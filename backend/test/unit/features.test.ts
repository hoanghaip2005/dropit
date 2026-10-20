import { describe, it, expect } from 'vitest';
import { replayStreak, type LogEvent } from '../../src/modules/achievements/service.js';
import { decryptJournal, encryptJournal, masterKey } from '../../src/modules/journal/crypto.js';
import { memberMetrics, groupSummary, periodRange, prevMonth, rate } from '../../src/modules/reports/service.js';
import { occurrences } from '../../src/modules/schedules/routes.js';
import { sniffImage } from '../../src/modules/profile/routes.js';
import { daysOfMonth } from '../../src/modules/achievements/routes.js';

const ev = (kind: LogEvent['kind'], day: string, at: number, sid: string | null = null, reason = ''): LogEvent => ({ kind, day, at, ref_session_id: sid, reason });

describe('replayStreak (BR-88, BR-92)', () => {
  const base = [
    ev('STREAK_INC', '2026-10-01', 1), ev('STREAK_INC', '2026-10-02', 2),
    ev('STREAK_BREAK', '2026-10-03', 3, 'S3'), // phiên 3/10 bị mất thưởng tập thể
    ev('STREAK_INC', '2026-10-04', 4),
  ];
  it('không khôi phục → phát lại đúng như ghi', () => {
    expect(replayStreak(base, [])).toEqual({ current: 1, longest: 2, lastIncDay: '2026-10-04' });
  });
  it('khôi phục phiên S3 (có thưởng) → bỏ lần ngắt và +1 ảo cho ngày 3/10', () => {
    expect(replayStreak(base, [{ sessionId: 'S3', day: '2026-10-03', inc: true, at: 10 }])).toEqual({ current: 4, longest: 4, lastIncDay: '2026-10-04' });
  });
  it('khôi phục không +1 (LOST) → chỉ bỏ lần ngắt', () => {
    expect(replayStreak(base, [{ sessionId: 'S3', day: '2026-10-03', inc: false, at: 10 }]).current).toBe(3);
  });
  it('ngày đã có +1 thật thì không +1 ảo lần nữa (BR-49)', () => {
    const evs = [ev('STREAK_INC', '2026-10-03', 1), ev('STREAK_BREAK', '2026-10-03', 2, 'S3')];
    expect(replayStreak(evs, [{ sessionId: 'S3', day: '2026-10-03', inc: true, at: 3 }]).current).toBe(1);
  });
  it('lần ngắt khác (chưa khôi phục) vẫn giữ hiệu lực', () => {
    const evs = [...base, ev('STREAK_BREAK', '2026-10-05', 5, 'S5')];
    expect(replayStreak(evs, [{ sessionId: 'S3', day: '2026-10-03', inc: true, at: 10 }])).toMatchObject({ current: 0, longest: 4 });
  });
});

describe('Mã hóa nhật ký (BR-100, AES-256-GCM phong bì)', () => {
  const key = masterKey('test-master');
  it('mã hóa → giải mã đúng; bản mã không chứa bản rõ; mỗi lần nonce/DEK khác nhau', () => {
    const a = encryptJournal(key, 'u1', '2026-10-19', 'xin chào 🌱');
    const b = encryptJournal(key, 'u1', '2026-10-19', 'xin chào 🌱');
    expect(decryptJournal(key, 'u1', '2026-10-19', a)).toBe('xin chào 🌱');
    expect(a.ciphertext.toString('utf8')).not.toContain('xin');
    expect(a.nonce.equals(b.nonce)).toBe(false);
    expect(a.encrypted_dek.equals(b.encrypted_dek)).toBe(false);
  });
  it('sai khóa chủ, sửa bản mã, hay chép sang người/ngày khác (AAD) → không giải được', () => {
    const a = encryptJournal(key, 'u1', '2026-10-19', 'bí mật');
    expect(() => decryptJournal(masterKey('khác'), 'u1', '2026-10-19', a)).toThrow();
    const bad = { ...a, ciphertext: Buffer.from(a.ciphertext) };
    bad.ciphertext[0] ^= 1;
    expect(() => decryptJournal(key, 'u1', '2026-10-19', bad)).toThrow();
    expect(() => decryptJournal(key, 'u2', '2026-10-19', a)).toThrow();
    expect(() => decryptJournal(key, 'u1', '2026-10-20', a)).toThrow();
  });
  it('khóa base64 32 byte dùng trực tiếp; chuỗi khác → SHA-256', () => {
    const k = Buffer.alloc(32, 7).toString('base64');
    expect(masterKey(k)).toEqual(Buffer.alloc(32, 7));
    expect(masterKey('abc').length).toBe(32);
  });
});

describe('Chỉ số báo cáo tháng (§Báo cáo §2–3)', () => {
  const range = periodRange('2026-10');
  it('kỳ theo giờ VN: [01/10 00:00+07, 01/11 00:00+07)', () => {
    expect(range.start.toISOString()).toBe('2026-09-30T17:00:00.000Z');
    expect(range.end.toISOString()).toBe('2026-10-31T17:00:00.000Z');
    expect(range.lastDay).toBe('2026-10-31');
    expect(prevMonth('2026-01')).toBe('2025-12');
    expect(rate(1, 3)).toBe(33.3);
    expect(rate(0, 0)).toBeNull();
  });
  const S = (id: string, iso: string, forfeited = false, trig: string | null = null) => ({ id, started_at: new Date(iso), session_day: iso.slice(0, 10), forfeited, forfeit_trigger_user_id: trig });
  const sessions = [S('a', '2026-10-02T13:00:00Z'), S('b', '2026-10-05T13:00:00Z', true, 'u'), S('c', '2026-10-20T13:00:00Z'), S('d', '2026-10-21T13:00:00Z')];
  const sm = (state: string, focus = 1500, extra = {}) => ({ session_id: '', user_id: 'u', state, late_join: false, pause_count: 0, focus_seconds: focus, exempted: false, ...extra });
  it('đếm hoàn thành/thoát/vắng, WITHDRAWN/VOID không vào lượt dự kiến, phút gồm phần trước EXITED', () => {
    const m = memberMetrics({ user_id: 'u', joined_at: new Date('2026-09-01'), left_at: null }, range, sessions, new Map([
      ['a', sm('COMPLETED')], ['b', sm('EXITED', 600)], ['c', sm('VOID', 0)], // d: không có dòng → vắng
    ]));
    expect(m).toMatchObject({ expected_sessions: 3, completed_sessions: 1, rewarded_sessions: 1, exited_count: 1, absent_count: 1,
      forfeit_trigger_count: 1, forfeited_participated: 1, focus_minutes: 35, attendance_days: 1, completion_rate: 33.3, joined_on: null });
    expect(Object.keys(m).some((k) => /coin|streak|balance/i.test(k))).toBe(false);
  });
  it('vào nhóm giữa tháng / rời giữa tháng: chỉ tính phiên trong khoảng là thành viên (BR-59)', () => {
    const m = memberMetrics({ user_id: 'u', joined_at: new Date('2026-10-10T00:00:00Z'), left_at: new Date('2026-10-21T00:00:00Z') }, range, sessions, new Map([['c', sm('COMPLETED')]]));
    expect(m).toMatchObject({ expected_sessions: 1, completed_sessions: 1, joined_on: '2026-10-10', left_on: '2026-10-21' });
  });
  it('tổng nhóm + so với tháng trước theo điểm phần trăm', () => {
    const rows = [memberMetrics({ user_id: 'u', joined_at: new Date('2026-09-01'), left_at: null }, range, sessions, new Map([['a', sm('COMPLETED')], ['c', sm('COMPLETED')]]))];
    const g = groupSummary(rows, sessions, { completion_rate: 40, sessions_held: 2 });
    expect(g).toMatchObject({ sessions_held: 4, expected_slots: 4, completion_rate: 50, forfeited_sessions: 1, forfeited_rate: 25 });
    expect(g.prev_month_delta).toMatchObject({ completion_rate_pp: 10, sessions_held: 2 });
    expect(groupSummary(rows, sessions, null).prev_month_delta).toBeNull();
  });
});

describe('Lịch lặp — sinh lần lặp (BR-113)', () => {
  it('giữ giờ VN, chỉ các thứ đã chọn (ISO 1 = T2), tới hết end_date', () => {
    // 2026-10-19 là Thứ Hai; 20:00 giờ VN = 13:00Z
    const occ = occurrences('2026-10-19T13:00:00Z', [1, 3], '2026-11-01');
    expect(occ.map((d) => d.toISOString())).toEqual(['2026-10-19T13:00:00.000Z', '2026-10-21T13:00:00.000Z', '2026-10-26T13:00:00.000Z', '2026-10-28T13:00:00.000Z']);
  });
  it('giờ VN qua nửa đêm UTC vẫn đúng ngày VN', () => {
    // 06:00 VN ngày 20/10 = 23:00Z ngày 19/10; Thứ Ba = 2
    expect(occurrences('2026-10-19T23:00:00Z', [2], '2026-10-27').map((d) => d.toISOString())).toEqual(['2026-10-19T23:00:00.000Z', '2026-10-26T23:00:00.000Z']);
  });
});

describe('Tiện ích', () => {
  it('sniffImage theo byte đầu', () => {
    expect(sniffImage(Buffer.from([0xff, 0xd8, 0xff, 0xe0]))).toBe('image/jpeg');
    expect(sniffImage(Buffer.from('RIFF0000WEBPVP8 '))).toBe('image/webp');
    expect(sniffImage(Buffer.from('GIF89a'))).toBeNull();
  });
  it('daysOfMonth', () => {
    expect(daysOfMonth('2026-02')).toHaveLength(28);
    expect(daysOfMonth('2028-02').at(-1)).toBe('2028-02-29');
  });
});
