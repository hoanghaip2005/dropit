import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { SessionRuntime, type Envelope } from '../../src/modules/sessions/engine.js';
import type { EngineConfig } from '../../src/config.js';

const cfg: EngineConfig = {
  lateJoinMs: 0,
  graceMs: 3000, graceMax: 1, countdownMs: 5000, hbTimeoutMs: 10000, holdMs: 10000,
  lobbyOpenMs: 600000, minuteMs: 60000, sweepMs: 250, lockReclassify: false,
  coins25: 10, coins50: 25, coinsDailyCap: 100,
};
const T0 = Date.UTC(2026, 9, 19, 13, 0, 0);

let rt: SessionRuntime;
let exited: { user: string; forfeitedNow: boolean }[];
let delivered: { user: string; env: Envelope }[];

function setup(members = ['a', 'b', 'c']) {
  vi.setSystemTime(T0 - 60000); // 1 phút trước giờ phiên
  rt = new SessionRuntime({ id: 's1', groupId: 'g1', startedAt: T0, durationMin: 25 }, cfg);
  exited = [];
  delivered = [];
  rt.on('exited', (m, f) => exited.push({ user: m.userId, forfeitedNow: f }));
  rt.on('deliver', (user, env) => delivered.push({ user, env }));
  rt.schedule();
  for (const u of members) expect(rt.join(u, u.toUpperCase(), `sock-${u}`, `dev-${u}`).ok).toBe(true);
}
/** Đến started_at + offset, giữ heartbeat cho mọi người đang có socket. */
function goActive(offsetMs = 0) {
  vi.advanceTimersByTime(60000 + offsetMs);
  expect(rt.status).toBe('ACTIVE');
}
const st = (u: string) => rt.members.get(u)!.state;
let ev = 0;
const send = (u: string, t: Parameters<SessionRuntime['handle']>[1], id?: string) => rt.handle(u, t, id ?? `e${++ev}`);

beforeEach(() => vi.useFakeTimers());
afterEach(() => {
  rt?.dispose();
  vi.useRealTimers();
});

describe('Engine phiên — vòng đời', () => {
  it('SCHEDULED → COUNTDOWN tại started_at − 5s → ACTIVE tại started_at; mọi người FOCUSING', () => {
    setup();
    vi.advanceTimersByTime(55000);
    expect(rt.status).toBe('COUNTDOWN');
    expect(delivered.some((d) => d.env.type === 'session:countdown')).toBe(true);
    vi.advanceTimersByTime(5000);
    expect(rt.status).toBe('ACTIVE');
    expect(['a', 'b', 'c'].map(st)).toEqual(['FOCUSING', 'FOCUSING', 'FOCUSING']);
  });

  it('hết ends_at → COMPLETED cho mọi người, phát ended, focus = 25 phút', () => {
    setup();
    goActive();
    const ended = vi.fn();
    rt.on('ended', ended);
    for (let i = 0; i < 25 * 60 / 5; i++) {
      for (const u of ['a', 'b', 'c']) send(u, 'heartbeat');
      vi.advanceTimersByTime(5000);
    }
    expect(['a', 'b', 'c'].map(st)).toEqual(['COMPLETED', 'COMPLETED', 'COMPLETED']);
    expect(ended).toHaveBeenCalledOnce();
    expect(rt.focusSeconds(rt.members.get('a')!)).toBe(1500);
    expect(rt.forfeited).toBe(false);
  });
});

describe('Khoan hồng 3s (BR-11…BR-14)', () => {
  it('rời app rồi quay lại < 3s → FOCUSING, không ai bị báo, không forfeited', () => {
    setup();
    goActive(1000);
    expect(send('a', 'member:left_app').state).toBe('GRACE');
    expect(delivered.find((d) => d.user === 'a' && d.env.type === 'member:grace')).toBeTruthy();
    vi.advanceTimersByTime(2999);
    expect(send('a', 'member:returned').state).toBe('FOCUSING');
    vi.advanceTimersByTime(5000);
    expect(st('a')).toBe('FOCUSING');
    expect(exited).toEqual([]);
    expect(rt.forfeited).toBe(false);
  });

  it('rời app > 3s → EXITED (GRACE_EXPIRED), forfeited = true', () => {
    setup();
    goActive(1000);
    send('a', 'member:left_app');
    vi.advanceTimersByTime(3000);
    expect(st('a')).toBe('EXITED');
    expect(rt.members.get('a')!.endReason).toBe('GRACE_EXPIRED');
    expect(exited).toEqual([{ user: 'a', forfeitedNow: true }]);
    expect(rt.forfeited).toBe(true);
    expect(rt.forfeitTriggerUserId).toBe('a');
  });

  it('quay lại đúng 3,000s (biên nửa mở BR-65) → EXITED', () => {
    setup();
    goActive(1000);
    send('a', 'member:left_app');
    // timer hết hạn cùng thời điểm: quay lại tại đúng hạn vẫn là EXITED
    vi.advanceTimersByTime(3000);
    expect(send('a', 'member:returned').state).toBe('EXITED');
  });

  it('đã dùng lượt khoan hồng, rời app lần 2 → EXITED ngay (BR-13)', () => {
    setup();
    goActive(1000);
    send('a', 'member:left_app');
    vi.advanceTimersByTime(1000);
    send('a', 'member:returned');
    vi.advanceTimersByTime(1000);
    expect(send('a', 'member:left_app').state).toBe('EXITED');
    expect(rt.members.get('a')!.endReason).toBe('APP_LEFT');
  });

  it('forfeited chỉ đặt một lần: người thứ hai thoát không đổi người khởi phát (BR-39)', () => {
    setup();
    goActive(1000);
    send('a', 'member:left_app');
    vi.advanceTimersByTime(3000);
    const at = rt.forfeitedAt;
    send('b', 'member:left_app');
    vi.advanceTimersByTime(3000);
    expect(exited).toEqual([{ user: 'a', forfeitedNow: true }, { user: 'b', forfeitedNow: false }]);
    expect(rt.forfeitTriggerUserId).toBe('a');
    expect(rt.forfeitedAt).toBe(at);
  });
});

describe('Khóa màn hình (BR-15, BR-66, D-08)', () => {
  it('LOCK không phạt: khóa 60s, không heartbeat, socket đóng → vẫn FOCUSING', () => {
    setup();
    goActive(1000);
    send('a', 'member:screen_locked');
    rt.socketClosed('a', 'sock-a');
    for (let i = 0; i < 12; i++) {
      send('b', 'heartbeat');
      send('c', 'heartbeat');
      vi.advanceTimersByTime(5000);
    }
    expect(st('a')).toBe('FOCUSING');
    expect(exited).toEqual([]);
    expect(rt.resume('a', 'sock-a2', 'dev-a', 'r1').ok).toBe(true);
    send('a', 'member:screen_unlocked');
    expect(st('a')).toBe('FOCUSING');
  });

  it('MEMBER_EXITED của người khác được xếp hàng khi khóa, giao khi mở khóa (BR-82)', () => {
    setup();
    goActive(1000);
    send('a', 'member:screen_locked');
    const env = rt.env('MEMBER_EXITED', { exited_display_name: 'B' });
    rt.deliverToMember('a', env);
    expect(delivered.find((d) => d.env === env)).toBeUndefined();
    send('a', 'member:screen_unlocked');
    expect(delivered.find((d) => d.env === env)?.user).toBe('a');
  });

  it('lock_reclassify mặc định TẮT: báo khóa khi đang GRACE vẫn EXITED sau 3s', () => {
    setup();
    goActive(1000);
    send('a', 'member:left_app');
    send('a', 'member:screen_locked');
    vi.advanceTimersByTime(3000);
    expect(st('a')).toBe('EXITED');
  });
});

describe('Heartbeat / mất kết nối (BR-19…BR-21, D-19)', () => {
  it('mất heartbeat 10s → DISCONNECTED, quá 10s nữa → LOST, KHÔNG forfeited, KHÔNG MEMBER_EXITED', () => {
    setup();
    goActive();
    for (let i = 0; i < 5; i++) {
      send('b', 'heartbeat');
      send('c', 'heartbeat');
      vi.advanceTimersByTime(5000);
    }
    expect(st('a')).toBe('LOST');
    expect(rt.members.get('a')!.endReason).toBe('DISCONNECT_TIMEOUT');
    expect(rt.forfeited).toBe(false);
    expect(exited).toEqual([]);
  });

  it('socket đóng → DISCONNECTED; resume trong hạn (cùng device) → FOCUSING', () => {
    setup();
    goActive(1000);
    rt.socketClosed('a', 'sock-a');
    expect(st('a')).toBe('DISCONNECTED');
    vi.advanceTimersByTime(4000);
    expect(rt.resume('a', 'sock-a2', 'dev-other', 'r1')).toMatchObject({ ok: false, code: 'SESSION_ALREADY_JOINED_ELSEWHERE' });
    expect(rt.resume('a', 'sock-a2', 'dev-a', 'r2')).toMatchObject({ ok: true, state: 'FOCUSING' });
  });

  it('resume sau hạn giữ chỗ → SESSION_LOST', () => {
    setup();
    goActive(1000);
    rt.socketClosed('a', 'sock-a');
    vi.advanceTimersByTime(10000);
    expect(rt.resume('a', 'sock-a2', 'dev-a', 'r1')).toMatchObject({ ok: false, code: 'SESSION_LOST' });
    expect(st('a')).toBe('LOST');
  });

  it('GRACE rồi mất mạng: hạn 3s vẫn chạy → EXITED (§3 #1)', () => {
    setup();
    goActive(1000);
    send('a', 'member:left_app');
    rt.socketClosed('a', 'sock-a');
    expect(st('a')).toBe('GRACE');
    vi.advanceTimersByTime(3000);
    expect(st('a')).toBe('EXITED');
  });
});

describe('Idempotency event_id (BR-31)', () => {
  it('gửi lại cùng event_id → ack kết quả cũ, duplicate, không đổi trạng thái', () => {
    setup();
    goActive(1000);
    const a1 = send('a', 'member:left_app', 'same-id');
    vi.advanceTimersByTime(1000);
    send('a', 'member:returned', 'ret-1');
    const a2 = send('a', 'member:left_app', 'same-id');
    expect(a1.state).toBe('GRACE');
    expect(a2).toMatchObject({ ok: true, state: 'GRACE', duplicate: true });
    expect(st('a')).toBe('FOCUSING'); // không vào GRACE lần nữa, không bị EXITED do hết lượt
    vi.advanceTimersByTime(5000);
    expect(st('a')).toBe('FOCUSING');
  });
});

describe('Rời phiên chủ động (D-29, BR-118)', () => {
  it('session:leave khi WAITING → ABSENT (LOBBY_LEAVE), không forfeited', () => {
    setup();
    expect(send('a', 'session:leave').state).toBe('ABSENT');
    expect(rt.members.get('a')!.endReason).toBe('LOBBY_LEAVE');
    goActive();
    expect(rt.forfeited).toBe(false);
    expect(exited).toEqual([]);
  });

  it('session:leave khi FOCUSING → EXITED (USER_LEAVE) + forfeited', () => {
    setup();
    goActive(1000);
    expect(send('a', 'session:leave').state).toBe('EXITED');
    expect(rt.members.get('a')!.endReason).toBe('USER_LEAVE');
    expect(rt.forfeited).toBe(true);
  });

  it('session:leave khi GRACE → EXITED ngay, hủy hẹn (không EXITED hai lần)', () => {
    setup();
    goActive(1000);
    send('a', 'member:left_app');
    send('a', 'session:leave');
    vi.advanceTimersByTime(5000);
    expect(exited.length).toBe(1);
  });
});

describe('Phòng chờ / COUNTDOWN (BR-64, Q-153)', () => {
  it('rời app trong COUNTDOWN không ghi; vẫn ở ngoài lúc started_at → GRACE (trừ lượt)', () => {
    setup();
    vi.advanceTimersByTime(56000);
    expect(send('a', 'member:left_app').state).toBe('WAITING');
    vi.advanceTimersByTime(4000);
    expect(st('a')).toBe('GRACE');
    vi.advanceTimersByTime(3000);
    expect(st('a')).toBe('EXITED');
  });

  it('WAITING mất kết nối đến started_at → ABSENT (NO_SHOW)', () => {
    setup();
    rt.socketClosed('a', 'sock-a');
    goActive();
    expect(st('a')).toBe('ABSENT');
    expect(rt.forfeited).toBe(false);
  });
});

describe('Engine — rút đồng ý giữa phiên (BR-26, D-23) và phòng chờ có tên', () => {
  it('withdraw từ GRACE: WITHDRAWN ngay, không exited, không forfeited; sau đó người khác thoát → forfeited do người đó', () => {
    setup();
    goActive(1000);
    send('a', 'member:left_app');
    expect(st('a')).toBe('GRACE');
    expect(rt.withdraw('a')).toEqual({ at: Date.now(), afterForfeit: false });
    expect(st('a')).toBe('WITHDRAWN');
    vi.advanceTimersByTime(5000); // hạn GRACE cũ không còn tác dụng
    expect(exited).toEqual([]);
    expect(rt.forfeited).toBe(false);
    send('b', 'member:left_app');
    vi.advanceTimersByTime(3000);
    expect(exited).toEqual([{ user: 'b', forfeitedNow: true }]);
    expect(rt.withdraw('a')).toBeNull(); // đã kết thúc → không đổi
  });

  it('withdraw đúng mốc forfeited_at coi là "sau" (BR-37 biên)', () => {
    setup();
    goActive(1000);
    send('b', 'session:leave');
    expect(rt.forfeited).toBe(true);
    expect(rt.withdraw('a')?.afterForfeit).toBe(true);
  });

  it('session:state.lobby_members: tên người WAITING sắp theo tên, rỗng khi ACTIVE', () => {
    setup(['c', 'a', 'b']);
    expect(rt.stateFor('a').lobby_members).toEqual(['A', 'B', 'C']);
    send('b', 'session:leave'); // WAITING → ABSENT
    expect(rt.stateFor('a').lobby_members).toEqual(['A', 'C']);
    goActive();
    expect(rt.stateFor('a').lobby_members).toEqual([]);
  });
});
