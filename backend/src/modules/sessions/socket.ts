// Gateway Socket.io namespace /session (03-api-socket §3).
import type { Server, Socket } from 'socket.io';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { ensureUser } from '../../shared/http.js';
import { AppError } from '../../shared/errors.js';
import type { Ack } from './engine.js';
import { withdrawConsent } from '../groups/service.js';

const Base = z.object({ event_id: z.string().min(1).max(100).optional(), session_id: z.string().uuid() });
type AckFn = (a: unknown) => void;

export function attachSessionSocket(io: Server, ctx: Ctx) {
  const nsp = io.of('/session');
  ctx.sessions.nsp = nsp;
  ctx.notifications.nsp = nsp;

  nsp.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (typeof token !== 'string') throw new AppError(401, 'UNAUTHENTICATED', 'Thiếu token');
      const identity = await ctx.verifier.verify(token);
      const u = await ensureUser(ctx.db, identity);
      socket.data.userId = u.id;
      socket.data.displayName = u.display_name;
      socket.data.deviceId = typeof socket.handshake.auth?.device_id === 'string' ? socket.handshake.auth.device_id : null;
      socket.data.sessions = new Set<string>();
      next();
    } catch (e) {
      const err = new Error(e instanceof AppError ? e.code : 'UNAUTHENTICATED') as Error & { data?: unknown };
      err.data = { code: e instanceof AppError ? e.code : 'UNAUTHENTICATED' };
      next(err);
    }
  });

  nsp.on('connection', (socket: Socket) => {
    socket.join(`user:${socket.data.userId}`); // giao thông báo khi đang mở app (NFR-02)

    const on = (ev: string, fn: (p: z.infer<typeof Base>) => Promise<Ack> | Ack) =>
      socket.on(ev, async (payload: unknown, ack?: AckFn) => {
        const reply = typeof ack === 'function' ? ack : () => {};
        const p = Base.safeParse(payload);
        if (!p.success) return reply({ ok: false, code: 'VALIDATION_FAILED', detail: p.error.issues[0]?.message });
        try {
          reply(await fn(p.data));
        } catch (e) {
          console.error('[socket]', ev, e);
          reply({ ok: false, code: 'INTERNAL' });
        }
      });

    on('session:join', (p) => ctx.sessions.join(socket, p.session_id, p.event_id));
    on('session:resume', (p) => ctx.sessions.resume(socket, p.session_id, p.event_id));
    for (const ev of ['member:left_app', 'member:returned', 'member:screen_locked', 'member:screen_unlocked', 'session:leave'] as const)
      on(ev, (p) => ctx.sessions.handle(socket, p.session_id, ev, p.event_id));
    // heartbeat: không cần event_id, không ack (volatile)
    socket.on('heartbeat', (payload: unknown) => {
      const p = Base.safeParse(payload);
      if (p.success) ctx.sessions.handle(socket, p.data.session_id, 'heartbeat');
    });
    socket.on('clock:ping', (p: { t0?: number } | undefined, ack?: AckFn) => {
      if (typeof ack === 'function') ack({ t0: p?.t0 ?? null, server_ts: new Date().toISOString() });
    });
    // US-01.07 / BR-26: rút đồng ý giữa phiên → WITHDRAWN + rời nhóm (cùng xử lý với DELETE /groups/{id}/consent)
    on('member:withdraw', async (p) => {
      const s = await ctx.db.selectFrom('sessions').select('group_id').where('id', '=', p.session_id).executeTakeFirst();
      if (!s) return { ok: false, code: 'NOT_FOUND' };
      try {
        const r = await withdrawConsent(ctx, socket.data.userId, s.group_id);
        const mine = r.sessions.find((x) => x.session_id === p.session_id);
        return { ok: true, state: 'WITHDRAWN', server_ts: new Date().toISOString(), left_group: true, after_forfeit: mine?.after_forfeit ?? false };
      } catch (e) {
        if (e instanceof AppError) return { ok: false, code: e.code, detail: e.detail };
        throw e;
      }
    });
    // Should — chưa làm ở bản này
    for (const ev of ['member:pause', 'member:resume'])
      socket.on(ev, (_p: unknown, ack?: AckFn) => typeof ack === 'function' && ack({ ok: false, code: 'NOT_SUPPORTED', detail: `${ev} (Should) chưa làm` }));

    socket.on('disconnect', () => ctx.sessions.socketClosed(socket));
  });
  return nsp;
}
