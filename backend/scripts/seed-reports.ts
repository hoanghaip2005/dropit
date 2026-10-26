// npm run db:seed:reports — local preview, no external delivery.
import { readFile } from 'node:fs/promises';
import { sql } from 'kysely';
import { loadConfig } from '../src/config.js';
import type { Ctx } from '../src/context.js';
import { createDb } from '../src/shared/db.js';
import { ConsoleNotificationSender, NotificationService } from '../src/modules/notifications/service.js';
import { generateGroupReport, prevMonth } from '../src/modules/reports/service.js';

const cfg = loadConfig();
const host = new URL(cfg.databaseUrl).hostname;
if (!['localhost', '127.0.0.1', '[::1]'].includes(host) || cfg.nodeEnv === 'production') {
  throw new Error('Report preview seed requires a local development database');
}
const db = createDb(cfg.databaseUrl);
try {
  const seed = await readFile(new URL('../db/seed-reports.sql', import.meta.url), 'utf8');
  await sql.raw(seed).execute(db);
  const result = await sql<{ month: string }>`select to_char(now() at time zone 'Asia/Ho_Chi_Minh','YYYY-MM') as month`.execute(db);
  const previous = prevMonth(result.rows[0].month);
  const ctx = { cfg, db, notifications: new NotificationService(db, new ConsoleNotificationSender(true)) } as Ctx;
  for (const month of [prevMonth(previous), previous]) {
    for (const group of ['00000000-0000-4000-9000-000000000001', '00000000-0000-4000-9000-000000000002']) {
      const report = await generateGroupReport(ctx, group, month);
      console.log(month, group, report?.created ? 'created' : 'already available');
    }
  }
} finally {
  await db.destroy();
}
