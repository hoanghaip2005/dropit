import { buildApp } from './app.js';
import { loadConfig } from './config.js';

const cfg = loadConfig();
const srv = await buildApp({ cfg, logger: cfg.nodeEnv !== 'test' });
const addr = await srv.start();
console.log(`DropIt! backend chạy ở ${addr} (NODE_ENV=${cfg.nodeEnv}, dev token: ${cfg.devAuth ? 'BẬT' : 'tắt'})`);
for (const sig of ['SIGINT', 'SIGTERM'] as const)
  process.on(sig, async () => {
    await srv.close();
    process.exit(0);
  });
