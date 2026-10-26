// Cấu hình từ env. Thời gian (ms) cho engine; phút phiên rút ngắn CHỈ khi NODE_ENV=test.
import { fileURLToPath } from 'node:url';
const env = process.env;
const num = (k: string, d: number) => (env[k] !== undefined && env[k] !== '' ? Number(env[k]) : d);

export type EngineConfig = {
  graceMs: number; // grace_s (BR-11)
  graceMax: number; // grace_max_per_session (BR-13)
  countdownMs: number; // countdown_s (BR-04)
  hbTimeoutMs: number; // heartbeat_timeout_s (BR-66)
  holdMs: number; // disconnect_hold_s (BR-19)
  lobbyOpenMs: number; // lobby_open_min (BR-63)
  minuteMs: number; // độ dài 1 "phút" phiên — 60000 trừ môi trường test
  sweepMs: number; // chu kỳ quét heartbeat/LOST
  lockReclassify: boolean; // Q-151 / DQ-F07 — mặc định TẮT (BR hiện hành không có)
  coins25: number;
  coins50: number;
  coinsDailyCap: number;
};

export type AppConfig = {
  nodeEnv: string;
  port: number;
  databaseUrl: string;
  jwtSecret: string;
  devAuth: boolean; // POST /dev/token
  cognitoRegion?: string;
  cognitoPoolId?: string;
  cognitoClientId?: string;
  snsRegion?: string;
  snsPlatformApplicationArn?: string; // SNS GCM platform application, FCM v1 for both mobile platforms
  scheduleMinLeadMs: number; // BR-79
  openSessionsIntervalMs: number; // job open-scheduled-sessions (DQ-03)
  engine: EngineConfig;
  publicBaseUrl: string; // sinh preview_url / avatar_url
  uploadsDir: string; // thay S3 ở local (avatar)
  outboxDir: string; // email báo cáo ghi ra tệp, không gửi thật (D-27)
  journalKey: string; // khóa chủ (base64 32 byte hoặc chuỗi bất kỳ → SHA-256) bọc khóa dữ liệu nhật ký — thay KMS
  monthlyReportCron: boolean; // job báo cáo tháng chạy bù trong cron (tắt ở test)
  explanationSubmitDays: number; // BR-85
  explanationEditH: number; // BR-85
  appealWindowH: number; // BR-86
  appealEscalateH: number; // BR-86
  recurrenceMaxWeeks: number; // BR-113
};

export function loadConfig(overrides: Omit<Partial<AppConfig>, 'engine'> & { engine?: Partial<EngineConfig> } = {}): AppConfig {
  const nodeEnv = overrides.nodeEnv ?? env.NODE_ENV ?? 'development';
  const cognitoRegion = overrides.cognitoRegion ?? env.COGNITO_REGION;
  const cognitoPoolId = overrides.cognitoPoolId ?? env.COGNITO_USER_POOL_ID;
  const cognitoClientId = overrides.cognitoClientId ?? env.COGNITO_CLIENT_ID;
  // Any Cognito configuration opts into real auth; incomplete config fails closed.
  const hasCognito = Boolean(cognitoRegion || cognitoPoolId || cognitoClientId);
  const isTest = nodeEnv === 'test';
  const engine: EngineConfig = {
    graceMs: num('GRACE_MS', 3000),
    graceMax: num('GRACE_MAX', 1),
    countdownMs: num('COUNTDOWN_MS', 5000),
    hbTimeoutMs: num('HB_TIMEOUT_MS', 10000),
    holdMs: num('HOLD_MS', 10000),
    lobbyOpenMs: num('LOBBY_OPEN_MS', 10 * 60000),
    minuteMs: isTest ? num('SESSION_MINUTE_MS', 60000) : 60000,
    sweepMs: num('SWEEP_MS', 250),
    lockReclassify: env.LOCK_RECLASSIFY === '1',
    coins25: 10,
    coins50: 25,
    coinsDailyCap: 100,
    ...overrides.engine,
  };
  return {
    nodeEnv,
    port: num('PORT', 3000),
    databaseUrl: env.DATABASE_URL || 'postgres://dropit:dropit@127.0.0.1:55433/dropit',
    jwtSecret: env.JWT_SECRET || 'dev-only-secret-change-me',
    devAuth: env.DEV_AUTH !== undefined ? env.DEV_AUTH === '1' : nodeEnv === 'development' && !hasCognito,
    cognitoRegion,
    cognitoPoolId,
    cognitoClientId,
    snsRegion: env.AWS_REGION,
    snsPlatformApplicationArn: env.SNS_PLATFORM_APPLICATION_ARN,
    scheduleMinLeadMs: isTest ? num('SCHEDULE_MIN_LEAD_MS', 60000) : 60000,
    openSessionsIntervalMs: num('OPEN_SESSIONS_INTERVAL_MS', 30000),
    publicBaseUrl: env.PUBLIC_BASE_URL || `http://localhost:${num('PORT', 3000)}`,
    uploadsDir: env.UPLOADS_DIR || fileURLToPath(new URL('../uploads', import.meta.url)),
    outboxDir: env.OUTBOX_DIR || fileURLToPath(new URL('../outbox', import.meta.url)),
    journalKey: env.JOURNAL_MASTER_KEY || 'dev-only-journal-key-change-me',
    monthlyReportCron: !isTest && env.MONTHLY_REPORT_CRON !== '0',
    explanationSubmitDays: 7,
    explanationEditH: 24,
    appealWindowH: 24,
    appealEscalateH: 72,
    recurrenceMaxWeeks: 12,
    ...overrides,
    engine,
  };
}
