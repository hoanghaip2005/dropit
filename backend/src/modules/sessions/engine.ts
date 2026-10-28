// Engine phiên thời gian thực (01-kien-truc §2.5) — thuần bộ nhớ, không biết DB/socket.
// Mỗi phiên đang chạy là một SessionRuntime. Node đơn luồng + mọi xử lý đồng bộ ⇒ các sự kiện
// của một phiên được xử lý tuần tự, `forfeited` đặt đúng một lần (BR-35, K-09).
// Logic khoan hồng/heartbeat/LOST lấy từ spike/t01-lifecycle/server/server.js (đã có selftest),
// đổi tên sự kiện theo design/03-api-socket.md §3 (DQ-F08).
import { EventEmitter } from 'node:events';
import { randomUUID } from 'node:crypto';
import type { EngineConfig } from '../../config.js';

export type MState =
  | 'WAITING' | 'FOCUSING' | 'GRACE' | 'PAUSED' | 'DISCONNECTED'
  | 'COMPLETED' | 'EXITED' | 'LOST' | 'ABSENT' | 'WITHDRAWN' | 'VOID';
export const FINAL: ReadonlySet<MState> = new Set(['COMPLETED', 'EXITED', 'LOST', 'ABSENT', 'WITHDRAWN', 'VOID']);
export type RtStatus = 'SCHEDULED' | 'COUNTDOWN' | 'ACTIVE' | 'ENDING' | 'COMPLETED' | 'CANCELLED';
export type EndReason =
  | 'USER_LEAVE' | 'APP_LEFT' | 'GRACE_EXPIRED' | 'DISCONNECT_TIMEOUT' | 'NO_SHOW' | 'LOBBY_LEAVE'
  | 'SESSION_CANCELLED' | 'TIME_UP' | 'CONSENT_WITHDRAWN';

export type Envelope = { event_id: string; type: string; session_id: string; server_ts: string; [k: string]: unknown };
export type Ack =
  | { ok: true; state: MState; server_ts: string; duplicate?: boolean; [k: string]: unknown }
  | { ok: false; code: string; detail?: string; state?: MState; server_ts?: string; duplicate?: boolean };

export interface MemberRt {
  userId: string;
  displayName: string;
  state: MState;
  endReason: EndReason | null;
  locked: boolean; // BR-15, BR-66
  awayInLobby: boolean; // rời app trong phòng chờ/COUNTDOWN (BR-64)
  graceUsed: number;
  graceDeadline: number | null;
  graceTimer: NodeJS.Timeout | null;
  lastSeenAt: number;
  disconnectedAt: number | null;
  prevState: MState | null;
  socketId: string | null;
  deviceId: string | null;
  joinedAt: number;
  exitedAt: number | null;
  endedAt: number | null;
  focusMs: number;
  segStart: number | null; // đầu đoạn FOCUSING/GRACE đang tính
  queue: Envelope[]; // BR-82: giữ thông báo khi khóa/GRACE/PAUSED/mất kết nối
}

export type SessionInfo = {
  id: string;
  groupId: string;
  startedAt: number; // giờ lịch (BR-04)
  durationMin: number;
};

export type C2SType =
  | 'member:left_app' | 'member:returned' | 'member:screen_locked' | 'member:screen_unlocked'
  | 'session:leave' | 'heartbeat';

export interface EngineEvents {
  member: [m: MemberRt, from: MState, reason: string];
  grace: [m: MemberRt];
  exited: [m: MemberRt, forfeitedNow: boolean];
  status: [status: RtStatus];
  deliver: [userId: string, env: Envelope];
  ended: [];
  admissionClosed: [];
}

export class SessionRuntime extends EventEmitter<EngineEvents> {
  readonly members = new Map<string, MemberRt>();
  status: RtStatus = 'SCHEDULED';
  forfeited = false;
  forfeitedAt: number | null = null;
  forfeitTriggerUserId: string | null = null;
  readonly endsAt: number;
  private seen = new Map<string, Ack>();
  private timers: NodeJS.Timeout[] = [];
  private sweepTimer: NodeJS.Timeout | null = null;

  constructor(
    readonly info: SessionInfo,
    readonly cfg: EngineConfig,
  ) {
    super();
    this.endsAt = info.startedAt + info.durationMin * cfg.minuteMs;
  }

  // ---------------- vòng đời phiên ----------------

  /** Hẹn COUNTDOWN / ACTIVE / ends_at theo giờ server. */
  schedule() {
    // Check-in can open weeks before the scheduled start. Node timeouts above
    // 2^31-1 ms overflow to 1ms, so re-arm long waits in bounded chunks.
    const at = (t: number, fn: () => void) => {
      const remaining = Math.max(0, t - Date.now());
      this.timers.push(setTimeout(remaining > 2147483647 ? () => at(t, fn) : fn, Math.min(remaining, 2147483647)));
    };
    at(this.info.startedAt - this.cfg.countdownMs, () => this.startCountdown());
    at(this.info.startedAt, () => this.activate());
    if (this.cfg.lateJoinMs > 0) {
      at(Math.min(this.endsAt, this.info.startedAt + this.cfg.lateJoinMs), () => this.emit('admissionClosed'));
    }
    at(this.endsAt, () => this.end());
    this.sweepTimer = setInterval(() => this.sweep(), this.cfg.sweepMs);
  }

  dispose() {
    for (const t of this.timers) clearTimeout(t);
    if (this.sweepTimer) clearInterval(this.sweepTimer);
    for (const m of this.members.values()) if (m.graceTimer) clearTimeout(m.graceTimer);
    this.removeAllListeners();
  }

  startCountdown() {
    if (this.status !== 'SCHEDULED') return;
    this.setStatus('COUNTDOWN');
    this.broadcast('session:countdown', {
      countdown_starts_at: new Date(this.info.startedAt - this.cfg.countdownMs).toISOString(),
      started_at: new Date(this.info.startedAt).toISOString(),
    });
  }

  activate() {
    if (this.status !== 'SCHEDULED' && this.status !== 'COUNTDOWN') return;
    if (this.status === 'SCHEDULED') this.startCountdown();
    const now = Date.now();
    this.status = 'ACTIVE';
    for (const m of this.members.values()) {
      if (m.state !== 'WAITING') continue;
      if (m.socketId === null) {
        // Check-in remains reversible through the admission grace period.
        continue;
      } else if (m.awayInLobby && !m.locked) {
        m.lastSeenAt = now;
        this.startGrace(m, 'away_at_start'); // BR-64: GRACE từ started_at, trừ lượt
      } else {
        m.lastSeenAt = now;
        m.segStart = now;
        this.transition(m, 'FOCUSING', 'session_started'); // BR-05
      }
    }
    this.emit('status', 'ACTIVE');
    this.checkAllDone();
  }

  end() {
    if (this.status !== 'ACTIVE') return;
    this.status = 'ENDING';
    const now = Date.now();
    for (const m of this.members.values()) {
      if (m.state === 'FOCUSING' || m.state === 'PAUSED' || m.state === 'GRACE') {
        // BR-23: GRACE chưa quá hạn tại ends_at → COMPLETED (§3 #6)
        this.closeSeg(m, true, now);
        this.finish(m, 'COMPLETED', 'TIME_UP');
      }
      // DISCONNECTED: chờ nối lại trong hạn (→ COMPLETED) hoặc LOST (§3.4 #5, DQ-F12)
    }
    this.emit('status', 'ENDING');
    this.checkAllDone();
  }

  /** Finalize missing check-ins only after the admission window closes. */
  closeAdmission() {
    for (const m of this.members.values()) {
      if (m.state === 'WAITING' && m.socketId === null) this.finish(m, 'ABSENT', 'NO_SHOW');
    }
  }

  /** Hủy phiên (sự cố/hủy). Người chưa kết thúc → VOID (BR-22). */
  cancel() {
    if (this.status === 'COMPLETED' || this.status === 'CANCELLED') return;
    for (const m of this.members.values()) if (!FINAL.has(m.state)) this.finish(m, 'VOID', 'SESSION_CANCELLED');
    this.forfeited = false; // BR-22: gỡ forfeited
    this.setStatus('CANCELLED');
  }

  // ---------------- thành viên ----------------

  /** session:join vào phòng chờ (kiểm quyền/cửa sổ làm ở lớp trên). */
  join(userId: string, displayName: string, socketId: string, deviceId: string | null): Ack {
    const now = Date.now();
    const ex = this.members.get(userId);
    if (ex) {
      if (ex.socketId && ex.socketId !== socketId) return this.err('SESSION_ALREADY_JOINED_ELSEWHERE', ex.state);
      if (ex.state === 'WAITING') {
        if (this.status === 'ACTIVE' && now >= Math.min(this.endsAt, this.info.startedAt + this.cfg.lateJoinMs)) return this.err('LATE_JOIN_CLOSED');
        ex.socketId = socketId;
        ex.deviceId = deviceId ?? ex.deviceId;
        ex.lastSeenAt = now;
        ex.awayInLobby = false;
        if (this.status === 'ACTIVE') {
          ex.segStart = now;
          this.transition(ex, 'FOCUSING', 'late_checkin');
        }
        return this.ok(ex);
      }
      return this.err('SESSION_NOT_ACTIVE', ex.state, 'Dùng session:resume để nối lại');
    }
    const late = this.status === 'ACTIVE';
    if (this.status !== 'SCHEDULED' && this.status !== 'COUNTDOWN' &&
      !(late && now < Math.min(this.endsAt, this.info.startedAt + this.cfg.lateJoinMs))) return this.err('LATE_JOIN_CLOSED');
    const m: MemberRt = {
      userId, displayName, state: 'WAITING', endReason: null, locked: false, awayInLobby: false,
      graceUsed: 0, graceDeadline: null, graceTimer: null, lastSeenAt: now, disconnectedAt: null,
      prevState: null, socketId, deviceId, joinedAt: now, exitedAt: null, endedAt: null,
      focusMs: 0, segStart: null, queue: [],
    };
    this.members.set(userId, m);
    if (late) {
      m.state = 'FOCUSING';
      m.segStart = now;
    }
    this.emit('member', m, 'WAITING', 'joined');
    return this.ok(m);
  }

  /**
   * Rút đồng ý giữa phiên (BR-26, AC-01.07.2): → WITHDRAWN ngay, ưu tiên mọi hạn đang chạy.
   * Không tính thoát, không `exited`, không đặt forfeited (BR-36). Trả null nếu người đó không có trạng thái chưa kết thúc.
   */
  withdraw(userId: string): { at: number; afterForfeit: boolean } | null {
    const m = this.members.get(userId);
    if (!m || FINAL.has(m.state)) return null;
    const now = Date.now();
    this.closeSeg(m, m.state === 'FOCUSING', now);
    // D-23/BR-37: so nghiêm ngặt — đúng bằng forfeited_at coi là "sau"
    const afterForfeit = this.forfeited && this.forfeitedAt !== null && now >= this.forfeitedAt;
    m.queue = []; // dừng giao thông báo phiên cho người đã rút
    this.finish(m, 'WITHDRAWN', 'CONSENT_WITHDRAWN');
    return { at: now, afterForfeit };
  }

  /** Mọi sự kiện C→S có event_id (BR-31). */
  handle(userId: string, type: C2SType, eventId?: string): Ack {
    const m = this.members.get(userId);
    if (!m) return this.err('NOT_JOINED');
    const key = eventId ? `${userId}:${eventId}` : null;
    if (key && this.seen.has(key)) return { ...this.seen.get(key)!, duplicate: true };
    const ack = this.apply(m, type);
    if (key) this.seen.set(key, ack);
    return ack;
  }

  private apply(m: MemberRt, type: C2SType): Ack {
    const now = Date.now();
    if (this.status === 'COMPLETED' || this.status === 'CANCELLED') return this.err('SESSION_NOT_ACTIVE', m.state);
    if (FINAL.has(m.state)) return this.ok(m); // BR-32: bỏ qua, trả trạng thái cuối
    m.lastSeenAt = now; // BR-19 (2)
    if (m.state === 'DISCONNECTED' && m.socketId) this.reconnect(m, 'event_while_disconnected');
    const lobby = this.status === 'SCHEDULED' || this.status === 'COUNTDOWN';

    switch (type) {
      case 'heartbeat':
        break;
      case 'member:left_app':
        if (lobby) m.awayInLobby = true; // BR-64: không ghi trong COUNTDOWN
        else if (this.status === 'ACTIVE' && m.state === 'FOCUSING') {
          if (m.locked) m.locked = false; // đã báo khóa mà lại rời app → mở khóa ngầm (§3 #17)
          this.startGrace(m, 'left_app');
        }
        // PAUSED → bỏ qua (BR-16); sau ends_at → bỏ qua (BR-33)
        break;
      case 'member:returned':
        if (lobby) m.awayInLobby = false;
        else if (m.state === 'GRACE') {
          if (now < (m.graceDeadline ?? 0)) {
            if (m.graceTimer) clearTimeout(m.graceTimer);
            m.graceTimer = null;
            this.closeSeg(m, true, now); // GRACE hồi phục được tính (BR-23)
            m.segStart = now;
            m.graceDeadline = null;
            this.transition(m, 'FOCUSING', 'grace_recovered'); // BR-12: không báo ai
            this.flush(m);
          } else this.exit(m, 'GRACE_EXPIRED'); // BR-65 biên nửa mở
        }
        break;
      case 'member:screen_locked':
        if (m.state === 'GRACE' && this.cfg.lockReclassify) {
          // Q-151/DQ-F07 — chỉ khi bật cờ; mặc định TẮT
          if (m.graceTimer) clearTimeout(m.graceTimer);
          m.graceUsed--;
          m.locked = true;
          this.closeSeg(m, true, now);
          m.segStart = now;
          this.transition(m, 'FOCUSING', 'lock_reclassified');
        } else if (m.state === 'FOCUSING' || lobby) m.locked = true; // BR-15: không đổi trạng thái
        break;
      case 'member:screen_unlocked':
        m.locked = false;
        m.lastSeenAt = now; // BR-66
        this.flush(m); // BR-82
        break;
      case 'session:leave':
        // D-29, BR-118
        if (m.state === 'WAITING') {
          // Leaving check-in is reversible until the admission deadline.
          m.socketId = null;
          m.awayInLobby = true;
          m.lastSeenAt = now;
          this.emit('member', m, 'WAITING', 'lobby_left');
        }
        else if (m.state === 'FOCUSING' || m.state === 'GRACE' || m.state === 'PAUSED') this.exit(m, 'USER_LEAVE');
        break;
    }
    return { ...this.ok(m), ...(type === 'session:leave' && m.state === 'WAITING' ? { left_lobby: true } : {}) };
  }

  /** Socket đóng. */
  socketClosed(userId: string, socketId: string) {
    const m = this.members.get(userId);
    if (!m || m.socketId !== socketId) return;
    m.socketId = null;
    // BR-66: đã báo khóa → không coi là DISCONNECTED. GRACE vẫn chạy (GRACE không vào DISCONNECTED).
    if ((m.state === 'FOCUSING' || m.state === 'PAUSED') && !m.locked) this.toDisconnected(m, Date.now(), 'socket_closed');
    // WAITING remains reversible until admissionClosed.
  }

  /** session:resume từ socket mới (§3.4). DQ-A07: chỉ cùng device_id. */
  resume(userId: string, socketId: string, deviceId: string | null, eventId?: string): Ack {
    const m = this.members.get(userId);
    if (!m) return this.err('NOT_JOINED');
    const key = eventId ? `${userId}:${eventId}` : null;
    if (key && this.seen.has(key)) return { ...this.seen.get(key)!, duplicate: true };
    const now = Date.now();
    let ack: Ack;
    if (m.socketId && m.socketId !== socketId) ack = this.err('SESSION_ALREADY_JOINED_ELSEWHERE', m.state);
    else if (m.deviceId && deviceId !== m.deviceId) ack = this.err('SESSION_ALREADY_JOINED_ELSEWHERE', m.state, 'Chỉ nối lại từ cùng thiết bị (DQ-A07)');
    else if (m.state === 'LOST') ack = this.err('SESSION_LOST', 'LOST');
    else if (m.state === 'WAITING') ack = this.join(userId, m.displayName, socketId, deviceId);
    else if (m.state === 'DISCONNECTED') {
      if (now < (m.disconnectedAt ?? 0) + this.cfg.holdMs) {
        m.socketId = socketId;
        this.reconnect(m, 'reconnected');
        ack = this.ok(m);
      } else {
        this.lose(m);
        ack = this.err('SESSION_LOST', 'LOST');
      }
    } else {
      m.socketId = socketId;
      m.lastSeenAt = now;
      if (!FINAL.has(m.state)) this.flush(m);
      ack = this.ok(m);
    }
    if (key) this.seen.set(key, ack);
    return ack;
  }

  /** Giao S→C cho người trong phiên; xếp hàng khi khóa/GRACE/PAUSED/mất kết nối (BR-82). */
  deliverToMember(userId: string, env: Envelope): boolean {
    const m = this.members.get(userId);
    if (!m) return false;
    if (!FINAL.has(m.state) && (m.locked || m.state === 'GRACE' || m.state === 'PAUSED' || m.state === 'DISCONNECTED' || !m.socketId)) {
      m.queue.push(env);
    } else this.emit('deliver', userId, env);
    return true;
  }

  /** Bản session:state riêng cho từng người (03 §3.3). */
  stateFor(userId: string): Envelope {
    const m = this.members.get(userId);
    const now = Date.now();
    const trig = this.forfeitTriggerUserId ? this.members.get(this.forfeitTriggerUserId) : null;
    return this.env('session:state', {
      status: this.status === 'ENDING' ? 'ACTIVE' : this.status,
      started_at: new Date(this.info.startedAt).toISOString(),
      ends_at: new Date(this.endsAt).toISOString(),
      remaining_s: Math.max(0, Math.round((this.endsAt - Math.max(now, this.info.startedAt)) / 1000)),
      participant_count: [...this.members.values()].filter((x) => x.state !== 'ABSENT' && (x.state !== 'WAITING' || x.socketId !== null)).length,
      my_state: m?.state ?? null,
      my_grace_deadline: m?.graceDeadline ? new Date(m.graceDeadline).toISOString() : null,
      pause_left: 0,
      forfeited: this.forfeited,
      forfeit_trigger_display_name: trig?.displayName ?? null,
      // Phòng chờ (V-06): tên người đang WAITING — chỉ khi chưa ACTIVE; không có trạng thái thời gian thực khác (NFR-P06)
      lobby_members: this.status === 'SCHEDULED' || this.status === 'COUNTDOWN'
        ? [...this.members.values()].filter((x) => x.state === 'WAITING' && x.socketId !== null).map((x) => x.displayName)
            .sort((a, b) => a.localeCompare(b, 'vi', { sensitivity: 'base' }))
        : [],
    });
  }

  focusSeconds(m: MemberRt): number {
    const s = Math.round((m.focusMs * 60) / this.cfg.minuteMs);
    return Math.min(s, this.info.durationMin * 60);
  }

  // ---------------- nội bộ ----------------

  /** Quét heartbeat_timeout (BR-66) và hạn giữ chỗ → LOST (BR-19 mục 4). */
  sweep() {
    if (this.status !== 'ACTIVE' && this.status !== 'ENDING') return;
    const now = Date.now();
    for (const m of this.members.values()) {
      if (this.status === 'ACTIVE' && (m.state === 'FOCUSING' || m.state === 'PAUSED') && !m.locked && now >= m.lastSeenAt + this.cfg.hbTimeoutMs) {
        this.toDisconnected(m, Math.min(now, m.lastSeenAt + this.cfg.hbTimeoutMs), 'heartbeat_timeout');
      }
      if (m.state === 'DISCONNECTED' && now >= (m.disconnectedAt ?? now) + this.cfg.holdMs) this.lose(m);
    }
  }

  private startGrace(m: MemberRt, trigger: string) {
    if (m.graceUsed >= this.cfg.graceMax) return this.exit(m, 'APP_LEFT'); // BR-13
    const now = Date.now();
    m.graceUsed++;
    m.graceDeadline = now + this.cfg.graceMs;
    this.closeSeg(m, true, now);
    m.segStart = now;
    this.transition(m, 'GRACE', trigger);
    m.graceTimer = setTimeout(() => {
      m.graceTimer = null;
      if (m.state === 'GRACE' && this.status === 'ACTIVE') this.exit(m, 'GRACE_EXPIRED'); // BR-14
    }, this.cfg.graceMs);
    this.emit('grace', m);
    this.emit('deliver', m.userId, this.env('member:grace', { grace_deadline: new Date(m.graceDeadline).toISOString() }));
  }

  private exit(m: MemberRt, reason: EndReason) {
    if (FINAL.has(m.state)) return;
    const now = Date.now();
    if (m.graceTimer) clearTimeout(m.graceTimer);
    m.graceTimer = null;
    this.closeSeg(m, m.state === 'FOCUSING', now); // GRACE không hồi phục không tính
    m.exitedAt = now;
    const forfeitedNow = !this.forfeited;
    if (forfeitedNow) {
      this.forfeited = true; // BR-35: đúng một lần
      this.forfeitedAt = now;
      this.forfeitTriggerUserId = m.userId;
    }
    this.finish(m, 'EXITED', reason);
    this.emit('exited', m, forfeitedNow);
  }

  private lose(m: MemberRt) {
    if (m.state !== 'DISCONNECTED') return;
    this.finish(m, 'LOST', 'DISCONNECT_TIMEOUT'); // D-19: không MEMBER_EXITED, không forfeited
  }

  private toDisconnected(m: MemberRt, at: number, reason: string) {
    this.closeSeg(m, m.state === 'FOCUSING', at);
    m.prevState = m.state;
    m.disconnectedAt = at;
    this.transition(m, 'DISCONNECTED', reason);
  }

  private reconnect(m: MemberRt, reason: string) {
    const now = Date.now();
    m.lastSeenAt = now;
    if (this.status === 'ENDING') {
      this.finish(m, 'COMPLETED', 'TIME_UP'); // nối lại trong hạn sau ends_at (§3 #7)
      return;
    }
    const to = m.prevState === 'PAUSED' ? 'PAUSED' : 'FOCUSING';
    if (to === 'FOCUSING') m.segStart = now;
    m.disconnectedAt = null;
    this.transition(m, to, reason);
    this.flush(m);
  }

  private finish(m: MemberRt, state: MState, reason: EndReason) {
    if (m.graceTimer) clearTimeout(m.graceTimer);
    m.graceTimer = null;
    m.endReason = reason;
    m.endedAt = Date.now();
    m.graceDeadline = null;
    this.transition(m, state, reason);
    if (state !== 'EXITED') this.flush(m);
    this.checkAllDone();
  }

  private transition(m: MemberRt, to: MState, reason: string) {
    const from = m.state;
    m.state = to;
    this.emit('member', m, from, reason);
    this.emit('deliver', m.userId, this.env('member:state', { my_state: to, reason }));
  }

  private closeSeg(m: MemberRt, count: boolean, at: number) {
    if (m.segStart !== null) {
      if (count) m.focusMs += Math.max(0, Math.min(at, this.endsAt) - Math.max(m.segStart, this.info.startedAt));
      m.segStart = null;
    }
  }

  private flush(m: MemberRt) {
    const q = m.queue.splice(0);
    for (const e of q) this.emit('deliver', m.userId, e);
  }

  private checkAllDone() {
    if (this.status !== 'ENDING') return;
    for (const m of this.members.values()) if (!FINAL.has(m.state)) return;
    this.setStatus('COMPLETED');
    for (const t of this.timers) clearTimeout(t);
    if (this.sweepTimer) clearInterval(this.sweepTimer);
    this.emit('ended');
  }

  private setStatus(s: RtStatus) {
    this.status = s;
    this.emit('status', s);
  }

  private broadcast(type: string, payload: Record<string, unknown>) {
    for (const m of this.members.values()) if (!FINAL.has(m.state)) this.emit('deliver', m.userId, this.env(type, payload));
  }

  env(type: string, payload: Record<string, unknown>): Envelope {
    return { event_id: randomUUID(), type, session_id: this.info.id, server_ts: new Date().toISOString(), ...payload };
  }

  private ok(m: MemberRt): Ack {
    return { ok: true, state: m.state, server_ts: new Date().toISOString(), ...(m.graceDeadline ? { grace_deadline: new Date(m.graceDeadline).toISOString() } : {}) };
  }
  private err(code: string, state?: MState, detail?: string): Ack {
    return { ok: false, code, ...(state ? { state } : {}), ...(detail ? { detail } : {}), server_ts: new Date().toISOString() };
  }
}
