// Tiện ích test tích hợp: dựng app thật (Fastify + Socket.io) trên Postgres docker (cổng 55433).
import { randomUUID } from 'node:crypto';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { io as ioc, type Socket as ClientSocket } from 'socket.io-client';
import { buildApp } from '../../src/app.js';
import { loadConfig, type EngineConfig } from '../../src/config.js';
import { Hs256Verifier } from '../../src/shared/auth.js';
import { ConsoleNotificationSender } from '../../src/modules/notifications/service.js';

export type TestServer = Awaited<ReturnType<typeof startServer>>;

export async function startServer(engine: Partial<EngineConfig> = {}) {
  const cfg = loadConfig({
    nodeEnv: 'test',
    devAuth: false,
    scheduleMinLeadMs: 0,
    openSessionsIntervalMs: 100,
    outboxDir: join(tmpdir(), 'dropit-test-outbox'),
    uploadsDir: join(tmpdir(), 'dropit-test-uploads'),
    engine: {
      graceMs: 300, countdownMs: 300, hbTimeoutMs: 60000, holdMs: 500, lobbyOpenMs: 60000,
      minuteMs: 60, sweepMs: 50, ...engine,
    },
  });
  const sender = new ConsoleNotificationSender(true);
  const srv = await buildApp({ cfg, sender, verifier: new Hs256Verifier(cfg.jwtSecret), quiet: true });
  await srv.start(0, '127.0.0.1');
  const port = (srv.app.server.address() as { port: number }).port;
  const base = `http://127.0.0.1:${port}`;
  const signer = srv.ctx.verifier as Hs256Verifier;
  const run = randomUUID().slice(0, 8);

  async function api(method: string, path: string, token?: string, body?: unknown, idem: string | null = randomUUID()) {
    const headers: Record<string, string> = {};
    if (token) headers.authorization = `Bearer ${token}`;
    if (body !== undefined) headers['content-type'] = 'application/json';
    if ((method === 'POST' || method === 'DELETE') && idem) headers['idempotency-key'] = idem;
    const r = await fetch(base + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
    const text = await r.text();
    return { status: r.status, body: text ? JSON.parse(text) : null, headers: r.headers };
  }

  async function user(name: string) {
    const email = `${name.toLowerCase().replace(/[^a-z0-9]/g, '')}.${run}.${randomUUID().slice(0, 4)}@test.dev`;
    const token = await signer.sign({ sub: `test:${email}`, email, name });
    const me = await api('GET', '/v1/me', token);
    return { token, id: me.body.user_id as string, name };
  }

  /** Chủ nhóm + n thành viên đã đồng ý. */
  async function groupWith(n: number, ownerName = 'Chủ') {
    const owner = await user(ownerName);
    const g = await api('POST', '/v1/groups', owner.token, { name: `Nhóm ${run}`, report_purpose: 'Kiểm thử tích hợp' });
    if (g.status !== 201) throw new Error(JSON.stringify(g.body));
    const members = [];
    const names = ['An', 'Bình', 'Chi', 'Dũng', 'Em', 'Giang', 'Hoa', 'Khánh', 'Linh', 'Minh', 'Nam'];
    for (let i = 0; i < n; i++) {
      const m = await user(names[i % names.length]);
      const c = await api('POST', `/v1/groups/${g.body.group_id}/consent`, m.token, { consent_version: 1, invite_code: g.body.invite_code });
      if (c.status !== 201) throw new Error(JSON.stringify(c.body));
      members.push(m);
    }
    return { owner, members, groupId: g.body.group_id as string, inviteCode: g.body.invite_code as string };
  }

  /** Phiên một lần bắt đầu sau ~leadMs (làm tròn lên giây vì server cắt mili-giây). */
  async function schedule(ownerToken: string, groupId: string, leadMs = 2000, duration = 25) {
    const start = new Date(Math.ceil((Date.now() + leadMs) / 1000) * 1000 + 1000);
    const r = await api('POST', `/v1/groups/${groupId}/schedules`, ownerToken, { start_time: start.toISOString(), duration_min: duration });
    if (r.status !== 201) throw new Error(JSON.stringify(r.body));
    return r.body.sessions[0].session_id as string;
  }

  async function sock(token: string, deviceId: string = randomUUID()) {
    const s = ioc(`${base}/session`, { auth: { token, v: 1, device_id: deviceId }, transports: ['websocket'], reconnection: false, forceNew: true });
    const events: { type: string; payload: any }[] = [];
    s.onAny((type, payload) => events.push({ type, payload }));
    await new Promise<void>((res, rej) => {
      s.once('connect', () => res());
      s.once('connect_error', (e) => rej(e));
    });
    return Object.assign(s, { events, deviceId }) as ClientSocket & { events: typeof events; deviceId: string };
  }

  return { srv, cfg, api, user, groupWith, schedule, sock, sender, db: srv.ctx.db, close: () => srv.close() };
}

export function emit(s: ClientSocket, ev: string, payload: Record<string, unknown>): Promise<any> {
  return s.timeout(5000).emitWithAck(ev, { event_id: randomUUID(), ...payload });
}

export const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export async function waitFor<T>(fn: () => Promise<T | undefined | null | false> | T | undefined | null | false, ms = 8000, step = 50): Promise<T> {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v as T;
    if (Date.now() > until) throw new Error('waitFor: hết thời gian');
    await sleep(step);
  }
}

/** Đệ quy tìm khóa Coins/chuỗi trong JSON (BR-53). */
export function findSensitiveKeys(obj: unknown, path = ''): string[] {
  const bad = /coin|streak|balance/i;
  if (!obj || typeof obj !== 'object') return [];
  return Object.entries(obj as Record<string, unknown>).flatMap(([k, v]) =>
    [...(bad.test(k) ? [`${path}${k}`] : []), ...findSensitiveKeys(v, `${path}${k}.`)]);
}
