// Áp các migration SQL idempotent trong backend/db/migrations (thêm bảng/cột ngoài design/schema.sql gốc).
import { readdir, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
import { sql } from 'kysely';
import type { DB } from './db.js';

const DIR = fileURLToPath(new URL('../../db/migrations', import.meta.url));

export async function applyMigrations(db: DB): Promise<string[]> {
  const files = (await readdir(DIR)).filter((f) => f.endsWith('.sql')).sort();
  for (const f of files) {
    const text = await readFile(join(DIR, f), 'utf8');
    // khóa tư vấn: nhiều tiến trình (test + dev) khởi động cùng lúc không chạy chồng DDL
    await db.connection().execute(async (c) => {
      await sql`SELECT pg_advisory_lock(551337)`.execute(c);
      try {
        await sql.raw(text).execute(c);
      } finally {
        await sql`SELECT pg_advisory_unlock(551337)`.execute(c);
      }
    });
  }
  return files;
}
