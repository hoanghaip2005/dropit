// Module notifications (ADR-06): hộp thông báo DB (BR-81) + chọn kênh socket/push.
// Push thật (SNS) chưa làm: NotificationSender có bản ConsoleNotificationSender ghi log.
import type { Namespace } from 'socket.io';
import type { DB } from '../../shared/db.js';
import type { Envelope } from '../sessions/engine.js';

export type PushMessage = { title: string; body: string; data: Record<string, string> };

export interface NotificationSender {
  push(userId: string, msg: PushMessage): Promise<void>;
}

export class ConsoleNotificationSender implements NotificationSender {
  sent: { userId: string; msg: PushMessage }[] = [];
  constructor(private quiet = false) {}
  async push(userId: string, msg: PushMessage) {
    this.sent.push({ userId, msg });
    if (!this.quiet) console.log(`[push:console] → ${userId} | ${msg.title} | ${msg.body}`);
  }
}
// Sau này: SnsNotificationSender implements NotificationSender (device_tokens.sns_endpoint_arn, push_retry BR-81).

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
    if (this.online(userId)) this.emitToUser(userId, env);
    else {
      await this.sender.push(userId, push);
      await this.db.updateTable('notifications').set({ push_status: 'SENT' })
        .where('user_id', '=', userId).where('dedupe_key', '=', String(push.data.event_id)).execute();
    }
  }
}
