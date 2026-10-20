// Khởi tạo HTTP (Fastify) + Socket.io + cron trong một tiến trình (ADR-01).
import Fastify from 'fastify';
import { sql } from 'kysely';
import { Server } from 'socket.io';
import { loadConfig, type AppConfig } from './config.js';
import { createDb, type DB } from './shared/db.js';
import { Hs256Verifier, type TokenVerifier } from './shared/auth.js';
import { installErrorHandler } from './shared/http.js';
import { applyMigrations } from './shared/migrate.js';
import type { Ctx } from './context.js';
import { ConsoleNotificationSender, NotificationService, type NotificationSender } from './modules/notifications/service.js';
import { SessionManager } from './modules/sessions/manager.js';
import { authRoutes } from './modules/auth/routes.js';
import { groupRoutes } from './modules/groups/routes.js';
import { scheduleRoutes } from './modules/schedules/routes.js';
import { sessionRoutes } from './modules/sessions/routes.js';
import { notificationRoutes } from './modules/notifications/routes.js';
import { rewardRoutes } from './modules/rewards/routes.js';
import { appealRoutes } from './modules/appeals/routes.js';
import { shopRoutes } from './modules/shop/routes.js';
import { profileRoutes } from './modules/profile/routes.js';
import { achievementRoutes } from './modules/achievements/routes.js';
import { journalRoutes } from './modules/journal/routes.js';
import { reportRoutes } from './modules/reports/routes.js';
import { privacyRoutes } from './modules/privacy/routes.js';
import { attachSessionSocket } from './modules/sessions/socket.js';
import { startJobs } from './modules/jobs/cron.js';

export type BuildOpts = {
  cfg?: AppConfig;
  db?: DB;
  verifier?: TokenVerifier;
  sender?: NotificationSender;
  logger?: boolean;
  quiet?: boolean;
};

export async function buildApp(opts: BuildOpts = {}) {
  const cfg = opts.cfg ?? loadConfig();
  const db = opts.db ?? createDb(cfg.databaseUrl);
  await applyMigrations(db); // db/migrations (idempotent)
  const verifier = opts.verifier ?? new Hs256Verifier(cfg.jwtSecret);
  const notifications = new NotificationService(db, opts.sender ?? new ConsoleNotificationSender(opts.quiet));
  const ctx = { cfg, db, verifier, notifications } as Ctx;
  ctx.sessions = new SessionManager(ctx);
  if (opts.quiet) ctx.sessions.setQuiet(true);

  const app = Fastify({ logger: opts.logger ?? false });
  installErrorHandler(app);
  app.get('/health', async () => {
    await sql`select 1`.execute(db);
    return { ok: true, env: cfg.nodeEnv, time: new Date().toISOString() };
  });
  authRoutes(app, ctx);
  groupRoutes(app, ctx);
  scheduleRoutes(app, ctx);
  sessionRoutes(app, ctx);
  notificationRoutes(app, ctx);
  rewardRoutes(app, ctx);
  appealRoutes(app, ctx);
  shopRoutes(app, ctx);
  profileRoutes(app, ctx);
  achievementRoutes(app, ctx);
  journalRoutes(app, ctx);
  reportRoutes(app, ctx);
  privacyRoutes(app, ctx);

  const io = new Server(app.server, { cors: { origin: '*' }, transports: ['websocket'] }); // DQ-A06: tắt long-polling
  attachSessionSocket(io, ctx);

  let stopJobs: (() => void) | null = null;
  return {
    app,
    io,
    ctx,
    async start(port = cfg.port, host = '0.0.0.0') {
      await ctx.sessions.recoverOnBoot();
      const addr = await app.listen({ port, host });
      stopJobs = startJobs(ctx);
      return addr;
    },
    async close() {
      stopJobs?.();
      await ctx.sessions.stop();
      io.close();
      await app.close();
      await db.destroy();
    },
  };
}
