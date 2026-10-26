// Module notifications (ADR-06): hộp thông báo DB (BR-81) + chọn kênh socket/push.
// SNS sender + durable inbox outbox; console sender chỉ phục vụ dev/test.
import type { Namespace } from 'socket.io';
import type { DB } from '../../shared/db.js';
import type { Envelope } from '../sessions/engine.js';
import { sql } from 'kysely';
import { safePush } from './sns.js';

export type PushMessage = { title: string; body: string; data: Record<string, string> };

export interface NotificationSender {
  push(userId: string, msg: PushMessage): Promise<void | 'SKIPPED'>;
  register?(userId: string, deviceId: string, platform: 'ANDROID' | 'IOS', token: string): Promise<void>;
  unregister?(userId: string, deviceId: string): Promise<void>;
}

export class ConsoleNotificationSender implements NotificationSender {
  sent: { userId: string; msg: PushMessage }[] = [];
  constructor(private quiet = false) {}
  async push(userId: string, msg: PushMessage) {
    this.sent.push({ userId, msg });
    if (!this.quiet) console.log(`[push:console] → ${userId} | ${msg.title} | ${msg.body}`);
  }
}

export type InboxItem = {
  type: string;
  title: string;
  body: string;
  data: Record<string, unknown>;
  dedupeKey: string;
};

export class NotificationService {
  nsp: Namespace | null = null;
  constructor(
    private db: DB,
    readonly sender: NotificationSender,
  ) {}

  /** Có socket đang mở của người này (room user:{id})? */
  online(userId: string): boolean {
    return (this.nsp?.adapter.rooms.get(`user:${userId}`)?.size ?? 0) > 0;
  }

  emitToUser(userId: string, env: Envelope) {
    this.nsp?.to(`user:${userId}`).emit(env.type, env);
  }

  /** Ghi hộp thông báo cho nhiều người (cùng event_id để client khử trùng). */
  async saveInbox(userIds: string[], item: InboxItem) {
    if (!userIds.length) return;
    await this.db
      .insertInto('notifications')
      .values(userIds.map((u) => ({ user_id: u, type: item.type, title: item.title, body: item.body, data: JSON.stringify(item.data), dedupe_key: item.dedupeKey, read_at: null })))
      .onConflict((oc) => oc.columns(['user_id', 'dedupe_key']).doNothing())
      .execute();
  }

  /** Hộp thông báo + giao ngay (socket nếu đang mở app, không thì push) — thông báo ngoài phiên. */
  async notify(userIds: string[], item: InboxItem) {
    await this.saveInbox(userIds, item);
    const data = Object.fromEntries(Object.entries(item.data).map(([k, v]) => [k, String(v)]));
    for (const u of userIds) {
      const env = {
        event_id: item.dedupeKey, type: item.type, session_id: String(item.data.session_id ?? ''),
        server_ts: new Date().toISOString(), title: item.title, body: item.body, ...item.data,
      } as Envelope;
      await this.deliverOutside(u, env, { title: item.title, body: item.body, data: { ...data, type: item.type, event_id: item.dedupeKey } });
    }
  }

  /** Giao ngoài phiên: socket nếu mở app, không thì push (BR-27, NFR-02). */
  async deliverOutside(userId: string, env: Envelope, push: PushMessage) {
    let defer = true;
    try { defer = Boolean(await this.activeRecipient(userId)); } catch { /* queue instead of interrupting focus */ }
    if (this.online(userId) && !defer) this.emitToUser(userId, env);
    else {
      // Persist the delivery intention before external I/O. Inbox survives every failure.
      try {
        await this.db.updateTable('notifications').set({ push_status: 'PENDING',
          push_payload: JSON.stringify(safePush(push)), push_next_at: new Date() })
          .where('user_id', '=', userId).where('dedupe_key', '=', String(push.data.event_id))
          .where('push_status', '=', 'NONE').execute();
      } catch {
        // Inbox is already persisted. A push enqueue failure must not fail the domain mutation.
        console.warn('[push] Could not enqueue delivery; inbox retained');
      }
    }
  }

  private activeRecipient(userId: string) {
    return this.db.selectFrom('session_members as sm').innerJoin('sessions as s', 's.id', 'sm.session_id')
      .select('sm.user_id').where('sm.user_id', '=', userId)
      .where('sm.state', 'in', ['WAITING', 'FOCUSING', 'GRACE', 'PAUSED', 'DISCONNECTED'])
      .where('s.status', 'in', ['SCHEDULED', 'COUNTDOWN', 'ACTIVE']).executeTakeFirst();
  }

  /** Bounded outbox, one retry (BR-81). Leases recover after process termination. */
  async flushPush(now = new Date()) {
    const jobs = await this.db.transaction().execute(async trx => {
      const rows = await trx.selectFrom('notifications').selectAll().where('push_status', '=', 'PENDING')
        .where('push_next_at', '<=', now)
        .where(eb => eb.or([eb('push_lease_until', 'is', null), eb('push_lease_until', '<=', now)]))
        .orderBy('created_at').limit(5).forUpdate().skipLocked().execute();
      if (rows.length) await trx.updateTable('notifications').set({ push_lease_until: new Date(now.getTime() + 120000) })
        .where('id', 'in', rows.map(r => r.id)).execute();
      return rows;
    });
    for (const job of jobs) {
      // Never send lock-screen pushes to a user participating in an unfinished session.
      try {
        const active = await this.activeRecipient(job.user_id);
        if (active) {
          await this.db.updateTable('notifications').set({ push_next_at: new Date(now.getTime() + 30000), push_lease_until: null })
            .where('id', '=', job.id).execute();
          continue;
        }
        if (this.online(job.user_id)) {
          this.emitToUser(job.user_id, { ...job.data, type: job.type, event_id: job.dedupe_key ?? job.id,
            session_id: String(job.data.session_id ?? ''), server_ts: new Date().toISOString(), title: job.title, body: job.body } as Envelope);
          await this.db.updateTable('notifications').set({ push_status: 'NONE', push_lease_until: null })
            .where('id', '=', job.id).execute();
          continue;
        }
        const result = await this.sender.push(job.user_id, job.push_payload as PushMessage);
        await this.db.updateTable('notifications').set({ push_status: result === 'SKIPPED' ? 'NONE' : 'SENT', push_lease_until: null,
          push_attempts: sql`push_attempts + 1` }).where('id', '=', job.id).execute();
      } catch {
        const failed = job.push_attempts >= 1;
        await this.db.updateTable('notifications').set({ push_status: failed ? 'FAILED' : 'PENDING',
          push_attempts: sql`push_attempts + 1`, push_next_at: new Date(now.getTime() + 30000), push_lease_until: null })
          .where('id', '=', job.id).execute();
      }
    }
  }
}
