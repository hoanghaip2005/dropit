import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { Ctx } from '../../context.js';
import { currentUser, idempotent, parse } from '../../shared/http.js';
import { AppError } from '../../shared/errors.js';
import * as svc from './service.js';

const GroupId = z.object({ group_id: z.string().uuid() });
// openapi GroupInput: name 1–60, report_purpose 1–500 (DQ-D10 theo đề xuất "giữ như schema")
const GroupInput = z.object({ name: z.string().min(1).max(60), report_purpose: z.string().min(1).max(500) });
const CODE = /^[A-HJ-NP-Z2-9]{8}$/; // pattern openapi

export function groupRoutes(app: FastifyInstance, ctx: Ctx) {
  app.get('/v1/me/groups', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    return svc.listMyGroups(ctx, me.id);
  });

  app.post('/v1/groups', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const body = parse(GroupInput, req.body);
    return idempotent(req, reply, ctx.db, me.id, async () => ({ status: 201, body: await svc.createGroup(ctx, me.id, body) }));
  });

  app.get('/v1/groups/:group_id', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    return svc.getGroup(ctx, me.id, group_id);
  });

  app.delete('/v1/groups/:group_id', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    return idempotent(req, reply, ctx.db, me.id, async () => {
      await svc.dissolveGroup(ctx, me.id, group_id);
      return { status: 204 };
    });
  });

  app.get('/v1/groups/:group_id/invite-code', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    return svc.getInviteCode(ctx, me.id, group_id);
  });

  app.post('/v1/groups/:group_id/invite-code', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    return idempotent(req, reply, ctx.db, me.id, async () => ({ status: 201, body: await svc.rotateInviteCode(ctx, me.id, group_id) }));
  });

  app.get('/v1/invites/:code', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { code } = req.params as { code: string };
    if (!CODE.test(code)) throw new AppError(404, 'INVITE_CODE_INVALID', 'Mã nhóm không đúng định dạng', 'BR-76');
    return svc.previewInvite(ctx, me.id, code);
  });

  app.post('/v1/groups/:group_id/consent', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    const body = parse(
      z.object({ consent_version: z.number().int(), invite_code: z.string().optional(), accepted_items: z.array(z.string()).optional() }),
      req.body,
    );
    return idempotent(req, reply, ctx.db, me.id, async () => ({ status: 201, body: await svc.acceptConsent(ctx, me.id, group_id, body) }));
  });

  app.get('/v1/groups/:group_id/members', async (req) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    return svc.listMembers(ctx, me.id, group_id);
  });

  // US-01.07: rút đồng ý = rời nhóm (trong phiên → WITHDRAWN, BR-26). 200 kèm phiên bị WITHDRAWN (openapi đã cập nhật).
  app.delete('/v1/groups/:group_id/consent', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id } = parse(GroupId, req.params);
    return idempotent(req, reply, ctx.db, me.id, async () => ({ status: 200, body: await svc.withdrawConsent(ctx, me.id, group_id) }));
  });

  // US-02.08: chủ nhóm xóa thành viên — 204 hiệu lực ngay; 202 nếu người đó đang trong phiên (sau ends_at, BR-77)
  app.delete('/v1/groups/:group_id/members/:user_id', async (req, reply) => {
    const me = await currentUser(req, ctx.db, ctx.verifier);
    const { group_id, user_id } = parse(GroupId.extend({ user_id: z.string().uuid() }), req.params);
    return idempotent(req, reply, ctx.db, me.id, () => svc.removeMember(ctx, me.id, group_id, user_id));
  });
}
