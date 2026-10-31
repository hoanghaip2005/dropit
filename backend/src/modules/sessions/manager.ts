import { redactBlockedText } from '../moderation/redaction.js';
// SessionManager: nạp phiên theo lịch, giữ SessionRuntime trong bộ nhớ (ADR-01), ghi chuyển
// trạng thái quan trọng xuống RDS ngay (DQ-F04), phát sự kiện miền sang notifications/rewards.
import type { Namespace, Socket } from 'socket.io';
import type { Ctx } from '../../context.js';
import type { MemberState } from '../../shared/db.js';
import { SessionRuntime, FINAL, type Ack, type MemberRt, type Envelope } from './engine.js';
import { finalizeSession, breakStreak } from '../rewards/service.js';
import { applyPendingRemovals } from '../groups/service.js';

type Entry = {
  rt: SessionRuntime;
  groupId: string;
  groupName: string;
  ownerId: string;
  sessionDay: string;
  q: Promise<unknown>; // hàng đợi ghi DB tuần tự theo phiên
  done: Promise<void>;
  resolveDone: () => void;
};

const hhmmVN = (t: number) => new Date(t + 7 * 3600e3).toISOString().slice(11, 16);

export class SessionManager {
  readonly runtimes = new Map<string, Entry>();
  nsp: Namespace | null = null;
  private loading = new Set<string>();
  private log = (...a: unknown[]) => console.log('[sessions]', ...a);

  constructor(private ctx: Ctx) {}

  setQuiet(q: boolean) {
    if (q) this.log = () => {};
  }

  // ---------------- nạp phiên (job open-scheduled-sessions) ----------------

  /** Khởi động lại tiến trình giữa phiên = sự cố (BR-22, DQ-F04): COUNTDOWN/ACTIVE → CANCELLED, chưa kết thúc → VOID. */
  async recoverOnBoot() {
    const db = this.ctx.db;
    const stale = await db.selectFrom('sessions').select('id').where('status', 'in', ['COUNTDOWN', 'ACTIVE']).execute();
    for (const s of stale) await this.cancelInDb(s.id, 'SERVER_OUTAGE');
    if (stale.length) this.log(`recover: hủy ${stale.length} phiên dở do khởi động lại (BR-22)`);
  }

  async cancelInDb(sessionId: string, reason: 'SERVER_OUTAGE' | 'NO_ATTENDEE' | 'OWNER_CANCEL') {
    await this.ctx.db.transaction().execute(async (tx) => {
      await tx.updateTable('session_members')
        .set({ state: 'VOID', end_reason: 'SESSION_CANCELLED', ended_at: new Date() })
        .where('session_id', '=', sessionId).where('is_final', '=', false as never).execute();
      await tx.updateTable('sessions')
        .set({ status: 'CANCELLED', cancel_reason: reason, cancelled_at: new Date(), forfeited: false, forfeited_at: null, forfeit_trigger_user_id: null })
        .where('id', '=', sessionId).execute();
    });
  }

  /** Nạp các phiên sắp mở phòng chờ (cron mỗi OPEN_SESSIONS_INTERVAL_MS). */
  async loadDue() {
    const now = Date.now();
    const horizon = new Date(now + this.ctx.cfg.engine.lobbyOpenMs + this.ctx.cfg.openSessionsIntervalMs);
    const due = await this.ctx.db.selectFrom('sessions').select(['id', 'started_at'])
      .where('status', '=', 'SCHEDULED').where('started_at', '<=', horizon).execute();
    for (const s of due) {
      if (this.runtimes.has(s.id) || this.loading.has(s.id)) continue;
      if (s.started_at.getTime() < now - 2000) {
        await this.cancelInDb(s.id, 'SERVER_OUTAGE'); // lỡ giờ khi server tắt (giả định)
        continue;
      }
      await this.load(s.id);
    }
  }

  onScheduled(sessionId: string) {
    void this.loadDue().catch((e) => this.log('loadDue lỗi', e));
    void sessionId;
  }

  private async load(sessionId: string) {
    this.loading.add(sessionId);
    try {
      const s = await this.ctx.db.selectFrom('sessions').innerJoin('groups', 'groups.id', 'sessions.group_id')
        .select(['sessions.id', 'sessions.group_id', 'sessions.started_at', 'sessions.duration_min', 'sessions.session_day', 'groups.owner_id', 'groups.name'])
        .where('sessions.id', '=', sessionId).executeTakeFirstOrThrow();
      const rt = new SessionRuntime(
        { id: s.id, groupId: s.group_id, startedAt: s.started_at.getTime(), durationMin: s.duration_min },
        this.ctx.cfg.engine,
      );
      let resolveDone!: () => void;
      const done = new Promise<void>((r) => (resolveDone = r));
      const e: Entry = { rt, groupId: s.group_id, groupName: s.name, ownerId: s.owner_id, sessionDay: s.session_day, q: Promise.resolve(), done, resolveDone };
      this.runtimes.set(s.id, e);
      this.wire(e);
      rt.schedule();
      this.log(`nạp phiên ${s.id} bắt đầu ${s.started_at.toISOString()}`);
    } finally {
      this.loading.delete(sessionId);
    }
  }

  private enqueue(e: Entry, fn: () => Promise<unknown>) {
    e.q = e.q.then(fn).catch((err) => this.log('ghi DB lỗi', e.rt.info.id, err));
    return e.q;
  }

  // ---------------- nối engine → DB / socket / thông báo ----------------

  private wire(e: Entry) {
    const { rt } = e;
    const sid = rt.info.id;
    const db = this.ctx.db;

    rt.on('deliver', (userId, env) => {
      const m = rt.members.get(userId);
      if (m?.socketId) void redactBlockedText(this.ctx.db, userId, env).then(safe => { if (m.socketId) this.nsp?.to(m.socketId).emit(env.type, safe); }).catch(err => this.log('redaction failed', err));
    });

    rt.on('member', (m, from, reason) => {
      this.log(`${sid.slice(0, 8)} ${m.displayName}: ${from} → ${m.state} (${reason})`);
      const snap = { ...m, focus: rt.focusSeconds(m) };
      this.enqueue(e, async () => {
        if (reason === 'joined') {
          await db.insertInto('session_members')
            .values({ session_id: sid, user_id: m.userId, state: snap.state as MemberState, late_join: m.joinedAt >= rt.info.startedAt,
              joined_at: new Date(m.joinedAt), exited_at: null, ended_at: null, end_reason: null })
            .onConflict((oc) => oc.columns(['session_id', 'user_id']).doNothing()).execute();
          return;
        }
        const final = FINAL.has(snap.state);
        await db.updateTable('session_members').set({
          state: snap.state as MemberState,
          grace_used: snap.graceUsed,
          ...(final ? {
            end_reason: snap.endReason, ended_at: new Date(snap.endedAt ?? Date.now()),
            exited_at: snap.exitedAt ? new Date(snap.exitedAt) : null, focus_seconds: snap.focus,
          } : {}),
        }).where('session_id', '=', sid).where('user_id', '=', m.userId).where('is_final', '=', false as never).execute();
      });
      if (from !== m.state || reason === 'joined' || reason === 'lobby_left') this.pushStateToAll(e); // check-in: cập nhật lobby_members
    });

    rt.on('exited', (m, forfeitedNow) => this.onExited(e, m, forfeitedNow));
    rt.on('admissionClosed', () => this.enqueue(e, () => this.onAdmissionClosed(e)));

    rt.on('status', (st) => {
      if (st === 'COUNTDOWN') this.enqueue(e, () => db.updateTable('sessions').set({ status: 'COUNTDOWN' }).where('id', '=', sid).where('status', '=', 'SCHEDULED').execute());
      if (st === 'ACTIVE') this.enqueue(e, () => this.onActivated(e));
      if (st === 'CANCELLED') {
        this.dispose(e);
        void this.afterSession(e);
      }
      this.pushStateToAll(e);
    });

    rt.on('ended', () => {
      this.enqueue(e, async () => {
        await this.onAdmissionClosed(e, true);
        const results = await finalizeSession(db, this.ctx.cfg.engine, sid);
        this.log(`${sid.slice(0, 8)} chốt phiên: ${results.map((r) => `${r.user_id.slice(-4)}=${r.state}/${r.coins_awarded}c`).join(', ')}`);
        for (const r of results) {
          if (r.state === 'ABSENT') continue; // DQ-F11: ABSENT không push
          const m = rt.members.get(r.user_id);
          const env = rt.env('SESSION_RESULT', {
            final_state: r.state, focus_seconds: r.focus_seconds, coins_awarded: r.coins_awarded,
            streak_after: r.streak_after, streak_broken: r.streak_broken, new_badges: r.new_badges, forfeited: rt.forfeited,
          });
          await this.ctx.notifications.saveInbox([r.user_id], {
            type: 'SESSION_RESULT', title: e.groupName,
            body: r.state === 'COMPLETED' ? (rt.forfeited ? 'Bạn đã hoàn thành phiên. Phiên mất thưởng tập thể: 0 Coins.' : `Bạn đã hoàn thành phiên: +${r.coins_awarded} Coins.`) : 'Kết quả phiên đã có.',
            data: { event_id: env.event_id, session_id: sid, group_id: e.groupId }, dedupeKey: env.event_id,
          });
          if (m?.socketId) this.nsp?.to(m.socketId).emit(env.type, await redactBlockedText(this.ctx.db, r.user_id, env));
          else await this.ctx.notifications.deliverOutside(r.user_id, env, { title: e.groupName, body: 'Kết quả phiên đã có', data: { type: 'SESSION_RESULT', event_id: env.event_id, session_id: sid } });
        }
      }).finally(() => {
        this.dispose(e);
        void this.afterSession(e);
      });
    });
  }

  /** Sau ends_at/hủy: áp các lần xóa thành viên đang chờ (BR-77). */
  private async afterSession(e: Entry) {
    try {
      await e.q;
      await applyPendingRemovals(this.ctx, e.groupId);
    } catch (err) {
      this.log('áp xóa thành viên chờ lỗi', err);
    }
  }

  /** Người có trạng thái chưa kết thúc trong phiên đang chạy của nhóm? (BR-77) */
  liveIn(groupId: string, userId: string): { sessionId: string; endsAt: number; status: string } | null {
    for (const e of this.runtimes.values()) {
      if (e.groupId !== groupId) continue;
      const m = e.rt.members.get(userId);
      if (m && !FINAL.has(m.state)) return { sessionId: e.rt.info.id, endsAt: e.rt.endsAt, status: e.rt.status };
    }
    return null;
  }

  /** Rút đồng ý giữa phiên (BR-26): WITHDRAWN ngay ở mọi phiên đang chạy của nhóm. Đồng bộ, không await. */
  withdrawFromGroup(groupId: string, userId: string) {
    const out: { sessionId: string; at: number; afterForfeit: boolean; forfeited: boolean }[] = [];
    for (const e of this.runtimes.values()) {
      if (e.groupId !== groupId) continue;
      const r = e.rt.withdraw(userId);
      if (r) out.push({ sessionId: e.rt.info.id, ...r, forfeited: e.rt.forfeited });
    }
    return out;
  }

  /** Revoke every connected socket after account erasure. */
  disconnectUser(userId: string) {
    this.nsp?.in('user:' + userId).disconnectSockets(true);
  }

  /** Trạng thái runtime (nếu đã nạp) — để kiểm sửa/hủy trước COUNTDOWN (BR-04, AC-02.11.4). */
  runtimeStatus(sessionId: string) {
    return this.runtimes.get(sessionId)?.rt.status ?? null;
  }

  /**
   * Chủ nhóm hủy phiên SCHEDULED đã nạp (phòng chờ mở): WAITING → VOID (AC-03.01.4). Gọi đồng bộ ngay sau khi kiểm
   * mốc COUNTDOWN để timer đếm ngược không chen vào. Trả danh sách người đang WAITING.
   */
  cancelLoaded(sessionId: string): string[] {
    const e = this.runtimes.get(sessionId);
    if (!e) return [];
    const waiting = [...e.rt.members.values()].filter((m) => !FINAL.has(m.state)).map((m) => m.userId);
    e.rt.cancel();
    return waiting;
  }

  /** Sửa giờ phiên đã nạp: bỏ runtime cũ, báo người trong phòng chờ (họ vào lại khi phòng chờ mở theo giờ mới). */
  unloadForReschedule(sessionId: string): string[] {
    const e = this.runtimes.get(sessionId);
    if (!e) return [];
    const waiting = [...e.rt.members.values()].filter((m) => !FINAL.has(m.state));
    for (const m of waiting) if (m.socketId) this.nsp?.to(m.socketId).emit('SESSION_UPDATED', e.rt.env('SESSION_UPDATED', { reason: 'RESCHEDULED' }));
    this.dispose(e);
    return waiting.map((m) => m.userId);
  }

  private pushStateToAll(e: Entry) {
    for (const m of e.rt.members.values()) if (m.socketId) void redactBlockedText(this.ctx.db, m.userId, e.rt.stateFor(m.userId)).then(env => { if (m.socketId) this.nsp?.to(m.socketId).emit('session:state', env); }).catch(err => this.log('redaction failed', err));
  }

  /** Tại started_at: thành viên (đã đồng ý) chưa vào → ABSENT (DQ-F01 đề xuất + BR-08 với late_join_max_min = 0). */
  private async onActivated(e: Entry) {
    const db = this.ctx.db;
    const sid = e.rt.info.id;
    await db.updateTable('sessions').set({ status: 'ACTIVE' }).where('id', '=', sid).where('status', 'in', ['SCHEDULED', 'COUNTDOWN']).execute();
    if (this.ctx.cfg.engine.lateJoinMs <= 0) await this.onAdmissionClosed(e);
  }

  private async onAdmissionClosed(e: Entry, atEnd = false) {
    // At a one-minute session the admission and end timers share a deadline.
    // The engine may already be ENDING while this queued callback runs.
    if (e.rt.status !== 'ACTIVE' && e.rt.status !== 'ENDING' && !atEnd) return;
    const db = this.ctx.db;
    const sid = e.rt.info.id;
    const session = await db.selectFrom('sessions').select('status').where('id', '=', sid).executeTakeFirst();
    if (!session || session.status === 'CANCELLED' || session.status === 'COMPLETED') return;
    const members = await db.selectFrom('group_members').select('user_id')
      .where('group_id', '=', e.groupId).where('left_at', 'is', null).execute();
    const now = new Date();
    // Members who left check-in (or disconnected) before the deadline are
    // absent only now. Until this point they remain WAITING and can rejoin.
    const missingCheckins = [...e.rt.members.values()].filter((m) => m.state === 'WAITING' && m.socketId === null).map((m) => m.userId);
    e.rt.closeAdmission();
    if (missingCheckins.length) {
      // Persist before same-deadline finalization; member event writes are queued
      // after this callback and cannot be relied upon by finalizeSession yet.
      await db.updateTable('session_members').set({ state: 'ABSENT', end_reason: 'NO_SHOW', ended_at: now })
        .where('session_id', '=', sid).where('user_id', 'in', missingCheckins).where('is_final', '=', false as never).execute();
    }
    const absent = members.filter((m) => !e.rt.members.has(m.user_id));
    if (absent.length)
      await db.insertInto('session_members')
        .values(absent.map((m) => ({ session_id: sid, user_id: m.user_id, state: 'ABSENT' as const, end_reason: 'NO_SHOW', ended_at: now, joined_at: null, exited_at: null })))
        .onConflict((oc) => oc.columns(['session_id', 'user_id']).doNothing()).execute();
    const anyone = [...e.rt.members.values()].some((m) => m.state !== 'ABSENT');
    if (!anyone) {
      // BR-30: không ai vào → ABSENT trước, sau đó CANCELLED NO_ATTENDEE
      await this.cancelInDb(sid, 'NO_ATTENDEE');
      e.rt.cancel();
    }
  }

  /** EXITED: ghi ngay (DQ-F04), forfeited một lần (D-05), MEMBER_EXITED có tên (D-22) tới cả nhóm + người trong phiên. */
  private onExited(e: Entry, m: MemberRt, forfeitedNow: boolean) {
    const rt = e.rt;
    const sid = rt.info.id;
    const db = this.ctx.db;
    const exitedAt = m.exitedAt!;
    const env: Envelope = rt.env('MEMBER_EXITED', {
      group_id: e.groupId,
      exited_display_name: m.displayName,
      exited_at: new Date(exitedAt).toISOString(),
      ...(forfeitedNow ? { forfeited: { display_name: m.displayName, at: new Date(exitedAt).toISOString() } } : {}),
    });
    this.log(`${sid.slice(0, 8)} MEMBER_EXITED ${m.displayName}${forfeitedNow ? ' → forfeited' : ''}`);
    this.enqueue(e, async () => {
      if (forfeitedNow)
        await db.updateTable('sessions').set({ forfeited: true, forfeited_at: new Date(exitedAt), forfeit_trigger_user_id: m.userId })
          .where('id', '=', sid).where('forfeited', '=', false).execute();
      await breakStreak(db, m.userId, e.sessionDay, sid, 'EXITED'); // BR-47(a) ngắt ngay
      // Người nhận: chủ nhóm + thành viên hiện tại + mọi người có trạng thái trong phiên, trừ người thoát
      const members = await db.selectFrom('group_members').select('user_id').where('group_id', '=', e.groupId).where('left_at', 'is', null).execute();
      const inSession = [...rt.members.values()].filter((x) => x.state !== 'WITHDRAWN').map((x) => x.userId); // BR-26: đã rút → ngừng nhận
      const recipients = new Set<string>([e.ownerId, ...members.map((x) => x.user_id), ...inSession]);
      recipients.delete(m.userId);
      const body = `${m.displayName} đã rời phiên lúc ${hhmmVN(exitedAt)}.` + (rt.forfeited ? ' Phiên đã mất thưởng tập thể — vẫn tiếp tục đến hết giờ.' : '');
      await this.ctx.notifications.saveInbox([...recipients], {
        type: 'MEMBER_EXITED', title: e.groupName, body,
        data: { event_id: env.event_id, session_id: sid, group_id: e.groupId, exited_display_name: m.displayName, exited_user_id: m.userId, forfeited: forfeitedNow },
        dedupeKey: env.event_id,
      });
      for (const u of recipients) {
        if (rt.deliverToMember(u, env)) continue; // trong phiên: socket, xếp hàng nếu khóa/GRACE (BR-82)
        await this.ctx.notifications.deliverOutside(u, env, {
          title: e.groupName, body,
          data: { type: 'MEMBER_EXITED', event_id: env.event_id, session_id: sid, group_id: e.groupId, forfeited: String(forfeitedNow) },
        });
      }
    });
  }

  private dispose(e: Entry) {
    e.rt.dispose();
    this.runtimes.delete(e.rt.info.id);
    e.resolveDone();
  }

  // ---------------- socket ----------------

  private async entryFor(sessionId: string): Promise<Entry | { ok: false; code: string; detail?: string }> {
    const e = this.runtimes.get(sessionId);
    if (e) return e;
    const s = await this.ctx.db.selectFrom('sessions').select(['status', 'started_at', 'created_at']).where('id', '=', sessionId).executeTakeFirst();
    if (!s) return { ok: false, code: 'NOT_FOUND' };
    if (s.status === 'COMPLETED' || s.status === 'CANCELLED') return { ok: false, code: 'SESSION_NOT_ACTIVE' };
    if (s.status === 'SCHEDULED' && s.started_at.getTime() < Date.now() - 2000) {
      await this.cancelInDb(sessionId, 'SERVER_OUTAGE');
      return { ok: false, code: 'SESSION_NOT_ACTIVE' };
    }
    const opens = s.created_at.getTime();
    if (Date.now() < opens) return { ok: false, code: 'LOBBY_NOT_OPEN', detail: new Date(opens).toISOString() };
    if (!this.loading.has(sessionId)) await this.load(sessionId);
    return this.runtimes.get(sessionId) ?? { ok: false, code: 'SESSION_NOT_ACTIVE' };
  }

  async join(socket: Socket, sessionId: string, eventId?: string): Promise<Ack> {
    const userId: string = socket.data.userId;
    const r = await this.entryFor(sessionId);
    if (!('rt' in r)) return r.code === 'LOBBY_NOT_OPEN' ? ({ ...r, lobby_opens_at: r.detail } as Ack) : r;
    const e: Entry = r;
    if (e.ownerId === userId) return { ok: false, code: 'OWNER_CANNOT_JOIN_SESSION', detail: 'Chủ nhóm không tham gia phiên (D-25)' };
    const gm = await this.ctx.db.selectFrom('group_members').innerJoin('groups', 'groups.id', 'group_members.group_id')
      .select(['group_members.consent_version', 'groups.consent_version as gv'])
      .where('group_members.group_id', '=', e.groupId).where('group_members.user_id', '=', userId).where('group_members.left_at', 'is', null)
      .executeTakeFirst();
    if (!gm) return { ok: false, code: 'FORBIDDEN_GROUP' };
    if (gm.consent_version < gm.gv) return { ok: false, code: 'CONSENT_REQUIRED' }; // BR-06
    for (const [id, other] of this.runtimes) {
      const om = other.rt.members.get(userId);
      if (id !== sessionId && om && !FINAL.has(om.state) && (om.state !== 'WAITING' || om.socketId !== null)) return { ok: false, code: 'ALREADY_IN_OTHER_SESSION' }; // BR-09
    }
    const ack = e.rt.join(userId, socket.data.displayName, socket.id, socket.data.deviceId ?? null);
    if (ack.ok) this.attach(socket, e);
    void eventId;
    return ack;
  }

  async resume(socket: Socket, sessionId: string, eventId?: string): Promise<Ack> {
    const e = this.runtimes.get(sessionId);
    if (!e) {
      const sm = await this.ctx.db.selectFrom('session_members').select('state').where('session_id', '=', sessionId).where('user_id', '=', socket.data.userId).executeTakeFirst();
      if (sm?.state === 'LOST') return { ok: false, code: 'SESSION_LOST', state: 'LOST' };
      return { ok: false, code: 'SESSION_NOT_ACTIVE', ...(sm ? { state: sm.state as never } : {}) };
    }
    const ack = e.rt.resume(socket.data.userId, socket.id, socket.data.deviceId ?? null, eventId);
    if (ack.ok) this.attach(socket, e);
    return ack;
  }

  private attach(socket: Socket, e: Entry) {
    socket.join(`session:${e.rt.info.id}`);
    (socket.data.sessions as Set<string>).add(e.rt.info.id);
    void redactBlockedText(this.ctx.db, socket.data.userId, e.rt.stateFor(socket.data.userId)).then(env => socket.emit('session:state', env)).catch(err => this.log('redaction failed', err));
  }

  handle(socket: Socket, sessionId: string, type: Parameters<SessionRuntime['handle']>[1], eventId?: string): Ack {
    const e = this.runtimes.get(sessionId);
    if (!e) return { ok: false, code: 'SESSION_NOT_ACTIVE' };
    const m = e.rt.members.get(socket.data.userId);
    if (!m) return { ok: false, code: 'NOT_JOINED' };
    if (m.socketId && m.socketId !== socket.id) return { ok: false, code: 'SESSION_ALREADY_JOINED_ELSEWHERE' };
    return e.rt.handle(socket.data.userId, type, eventId);
  }

  socketClosed(socket: Socket) {
    for (const sid of socket.data.sessions as Set<string>) this.runtimes.get(sid)?.rt.socketClosed(socket.data.userId, socket.id);
  }

  /** Chờ phiên chốt xong (test/demo). */
  async waitFinished(sessionId: string) {
    const e = this.runtimes.get(sessionId);
    if (e) await e.done;
  }

  async stop() {
    for (const e of [...this.runtimes.values()]) {
      await e.q;
      this.dispose(e);
    }
  }
}
