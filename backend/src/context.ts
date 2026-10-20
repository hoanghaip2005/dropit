import type { AppConfig } from './config.js';
import type { DB } from './shared/db.js';
import type { TokenVerifier } from './shared/auth.js';
import type { NotificationService } from './modules/notifications/service.js';
import type { SessionManager } from './modules/sessions/manager.js';

/** Phụ thuộc dùng chung giữa các module (modular monolith, 01 §2.1). */
export interface Ctx {
  cfg: AppConfig;
  db: DB;
  verifier: TokenVerifier;
  notifications: NotificationService;
  sessions: SessionManager;
}
