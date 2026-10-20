// Xóa volume và tạo lại DB (áp lại design/schema.sql + db/seed.sql).
import { execSync } from 'node:child_process';
const run = (c) => execSync(c, { stdio: 'inherit', cwd: new URL('..', import.meta.url) });
run('docker compose down -v');
run('docker compose up -d --wait');
console.log('DB đã reset: postgres://dropit:dropit@127.0.0.1:55433/dropit');
