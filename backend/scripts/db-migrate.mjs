// Áp db/migrations/*.sql (idempotent) vào DB đang chạy.
import { readdirSync, readFileSync } from 'node:fs';
import pg from 'pg';
const url = process.env.DATABASE_URL || 'postgres://dropit:dropit@127.0.0.1:55433/dropit';
const dir = new URL('../db/migrations/', import.meta.url);
const c = new pg.Client({ connectionString: url });
await c.connect();
for (const f of readdirSync(dir).filter((x) => x.endsWith('.sql')).sort()) {
  await c.query(readFileSync(new URL(f, dir), 'utf8'));
  console.log('Đã áp', f);
}
await c.end();
