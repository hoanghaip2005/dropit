import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, idempotent, parse } from '../../shared/http.js';
import { createAppeal, decideAppeal, getAppeal, getMyExplanation, listExplanationsForOwner, upsertExplanation } from './service.js';

const SessionId = z.object({ session_id: z.string().uuid() });
const AppealId = z.object({ appeal_id: z.string().uuid() });

export function appealRoutes(app: FastifyInstance, ctx: Ctx) {
  // US-04.05: thành viên EXITED gửi/sửa giải trình (If-Match tùy chọn = version)
  app.put('/v1/sessions/:session_id/explanation', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(SessionId, req.params);
    const body = parse(z.object({ body: z.string().min(1).max(2000) }), req.body);
    const ifMatch = req.headers['if-match'];
    return upsertExplanation(ctx, me.id, session_id, body.body, typeof ifMatch === 'string' ? ifMatch : undefined);
  });

  // US-04.05: đọc lại giải trình của chính mình (kèm lịch sử bản cũ) — openapi đã thêm GET
  app.get('/v1/sessions/:session_id/explanation', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(SessionId, req.params);
    return getMyExplanation(ctx, me.id, session_id);
  });

  // US-04.06: chủ nhóm xem giải trình
  app.get('/v1/sessions/:session_id/explanations', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(SessionId, req.params);
    return listExplanationsForOwner(ctx, me.id, session_id);
  });

  // US-04.07: khiếu nại
  app.post('/v1/sessions/:session_id/appeals', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { session_id } = parse(SessionId, req.params);
    const body = parse(z.object({ body: z.string().min(1).max(1000), suspect_system_error: z.boolean().default(false) }), req.body);
    return idempotent(req, reply, ctx.db, me.id, async () => ({
      status: 201, body: await createAppeal(ctx, me.id, session_id, body.body, body.suspect_system_error),
    }));
  });

  // Ngoài openapi: xem ca khiếu nại (chủ nhóm mở ca → ĐANG XỬ LÝ)
  app.get('/v1/appeals/:appeal_id', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { appeal_id } = parse(AppealId, req.params);
    return getAppeal(ctx, me.id, appeal_id);
  });

  // US-04.08: chủ nhóm miễn trừ / bác / chuyển quản trị
  app.post('/v1/appeals/:appeal_id/decision', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { appeal_id } = parse(AppealId, req.params);
    const body = parse(z.object({
      decision: z.enum(['EXEMPT', 'REJECT', 'ESCALATE']),
      decision_reason: z.string().min(1).max(500).optional(),
    }), req.body);
    return idempotent(req, reply, ctx.db, me.id, async () => ({
      status: 200, body: await decideAppeal(ctx, me.id, appeal_id, body.decision, body.decision_reason),
    }));
  });
}
