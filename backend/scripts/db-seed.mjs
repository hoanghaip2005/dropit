// Áp db/seed-demo.sql (idempotent) vào DB đang chạy, không cần reset volume.
import { readFileSync } from 'node:fs';
import pg from 'pg';
const url = process.env.DATABASE_URL || 'postgres://dropit:dropit@127.0.0.1:55433/dropit';
const c = new pg.Client({ connectionString: url });
c.on('notice', (n) => console.log('NOTICE:', n.message));
await c.connect();
await c.query(readFileSync(new URL('../db/seed-demo.sql', import.meta.url), 'utf8'));
await c.query(readFileSync(new URL('../db/seed-cosmetics.sql', import.meta.url), 'utf8'));
await c.end();
console.log('Đã áp seed-demo.sql');
