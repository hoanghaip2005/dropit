// Truy cập PostgreSQL bằng Kysely + pg (DQ-09). Lược đồ do design/schema.sql quản lý;
// interface dưới đây chỉ khai báo các bảng/cột backend lõi đang dùng.
import { Kysely, PostgresDialect, type Generated, type ColumnType } from 'kysely';
import pg from 'pg';

// date → 'YYYY-MM-DD' (không đổi sang Date theo múi giờ máy)
pg.types.setTypeParser(1082, (v: string) => v);

type Ts = ColumnType<Date, Date | string | undefined, Date | string>;
type TsNull = ColumnType<Date | null, Date | string | null | undefined, Date | string | null>;

export interface UsersTable {
  id: Generated<string>;
  cognito_sub: string | null;
  email: string | null;
  display_name: string;
  avatar_key: string | null;
  status: Generated<'ACTIVE' | 'LOCKED' | 'DELETED'>;
  current_streak: Generated<number>;
  longest_streak: Generated<number>;
  streak_last_inc_day: string | null;
  show_streak: Generated<boolean>; // BR-99 mặc định ẩn
  created_at: Generated<Date>;
}
export interface GroupsTable {
  id: Generated<string>;
  owner_id: string;
  name: string;
  report_purpose: string;
  retention_months: Generated<number>;
  consent_version: Generated<number>;
  invite_code: string;
  invite_code_rotated_at: Generated<Date>;
  status: Generated<'ACTIVE' | 'SCHEDULE_SUSPENDED' | 'DISSOLVING' | 'DISSOLVED'>;
  dissolved_at: Generated<Date | null>;
  created_at: Generated<Date>;
}
export interface GroupMembersTable {
  id: Generated<string>;
  group_id: string;
  user_id: string;
  consent_version: number;
  consented_at: Ts;
  joined_at: Generated<Date>;
  left_at: TsNull;
  leave_reason: 'LEFT' | 'REMOVED' | 'CONSENT_WITHDRAWN' | 'ACCOUNT_DELETED' | 'GROUP_DISSOLVED' | null;
  removal_effective_at: ColumnType<Date | null, Date | string | null | undefined, Date | string | null>; // BR-77
}
export interface ConsentsTable {
  id: Generated<string>;
  user_id: string;
  group_id: string;
  consent_version: number;
  action: 'GRANT' | 'WITHDRAW';
  purpose_snapshot: string;
  retention_months: number;
  terms_hash: string;
  client_info: string | null;
  created_at: Generated<Date>;
}
export interface InviteAttemptsTable {
  id: Generated<string>;
  user_id: string;
  success: boolean;
  created_at: Generated<Date>;
}
export type SessionStatus = 'SCHEDULED' | 'COUNTDOWN' | 'ACTIVE' | 'COMPLETED' | 'CANCELLED';
export interface SessionsTable {
  id: Generated<string>;
  group_id: string;
  schedule_id: string | null;
  duration_min: number;
  started_at: Ts;
  ends_at: Ts;
  session_day: string;
  status: Generated<SessionStatus>;
  forfeited: Generated<boolean>;
  forfeited_at: TsNull;
  forfeit_trigger_user_id: string | null;
  cancel_reason: string | null;
  cancelled_at: TsNull;
  completed_at: TsNull;
  created_by: string;
  created_at: Generated<Date>;
}
export type MemberState =
  | 'INVITED' | 'WAITING' | 'FOCUSING' | 'GRACE' | 'PAUSED' | 'DISCONNECTED'
  | 'COMPLETED' | 'EXITED' | 'LOST' | 'ABSENT' | 'WITHDRAWN' | 'VOID';
export interface SessionMembersTable {
  session_id: string;
  user_id: string;
  state: Generated<MemberState>;
  is_final: ColumnType<boolean, never, never>;
  end_reason: string | null;
  joined_at: TsNull;
  late_join: Generated<boolean>;
  exited_at: TsNull;
  ended_at: TsNull;
  grace_used: Generated<number>;
  pause_count: Generated<number>;
  pause_seconds: Generated<number>;
  focus_seconds: Generated<number>;
  exempted: Generated<boolean>;
  coins_awarded: Generated<number>;
  created_at: Generated<Date>;
}
export interface CoinLedgerTable {
  entry_id: Generated<string>;
  user_id: string;
  amount: number;
  type: 'SESSION_REWARD' | 'SHOP_PURCHASE' | 'ADMIN_ADJUST';
  ref_id: string | null;
  reward_date: string | null;
  reason: string;
  idempotency_key: string;
  balance_after: number; // trigger tính lại
  created_by: string | null;
  created_at: Generated<Date>;
}
export interface DailyAttendanceTable {
  user_id: string;
  day: string;
  group_id: string;
  first_session_id: string;
  sessions_completed: Generated<number>;
  focus_minutes: Generated<number>;
}
export interface AchievementLogTable {
  entry_id: Generated<string>;
  user_id: string;
  kind: 'CHECKIN' | 'STREAK_INC' | 'STREAK_BREAK' | 'STREAK_RESTORE' | 'BADGE_AWARD';
  value_before: number | null;
  value_after: number | null;
  day: string;
  ref_session_id: string | null;
  ref_badge_id: string | null;
  reason: string;
  created_at: Generated<Date>;
}
export interface NotificationsTable {
  id: Generated<string>;
  user_id: string;
  type: string;
  title: string;
  body: string;
  data: ColumnType<Record<string, unknown>, string | undefined, string>;
  dedupe_key: string | null;
  push_status: Generated<string>;
  push_attempts: Generated<number>;
  push_payload: ColumnType<Record<string, unknown> | null, string | null | undefined, string | null>;
  push_next_at: TsNull;
  push_lease_until: TsNull;
  read_at: TsNull;
  created_at: Generated<Date>;
}
export interface DeviceTokensTable {
  id: Generated<string>;
  user_id: string;
  device_id: string | null;
  platform: 'ANDROID' | 'IOS';
  token: string;
  sns_endpoint_arn: string | null;
  created_at: Generated<Date>;
  last_seen_at: Generated<Date>;
}
export interface IdempotencyKeysTable {
  user_id: string;
  key: string;
  method: string;
  path: string;
  request_hash: string;
  status_code: number | null;
  response_body: ColumnType<unknown, string | null, string | null>;
  created_at: Generated<Date>;
  expires_at: Generated<Date>;
}
export interface AccessLogsTable {
  id: Generated<string>;
  viewer_id: string | null;
  viewer_role: 'OWNER' | 'ADMIN';
  subject_user_id: string;
  object_type: string;
  object_id: string | null;
  group_id: string | null;
  purpose: string | null;
}
export interface UserCoinBalanceView {
  user_id: string;
  balance: number;
}

export type AppealStatus = 'PENDING' | 'IN_REVIEW' | 'ESCALATED' | 'EXEMPTED' | 'REJECTED';
export interface ExplanationsTable {
  id: Generated<string>;
  session_id: string;
  user_id: string;
  body: string;
  added_after_report: Generated<boolean>;
  edited_at: ColumnType<Date | null, Date | string | null | undefined, Date | string | null>; // migration 001 (ngoài schema.sql)
  created_at: Generated<Date>;
  updated_at: Generated<Date>;
}
/** Lịch sử bản cũ của giải trình (BR-85, AC-04.05.5) — migration 001, ngoài design/schema.sql. */
export interface ExplanationRevisionsTable {
  id: Generated<string>;
  explanation_id: string;
  body: string;
  written_at: Date;
  replaced_at: Generated<Date>;
}
export interface AppealsTable {
  id: Generated<string>;
  session_id: string;
  user_id: string;
  group_id: string;
  body: string;
  suspect_system_error: Generated<boolean>;
  status: AppealStatus;
  handler_id: string | null;
  decision_reason: string | null;
  opened_at: TsNull;
  escalated_at: TsNull;
  decided_at: TsNull;
  created_at: Generated<Date>;
  updated_at: Generated<Date>;
}
export interface SchedulesTable {
  id: Generated<string>;
  group_id: string;
  created_by: string;
  start_time: string; // 'HH:MM:SS' giờ VN
  duration_min: number;
  weekdays: number[];
  start_date: string;
  end_date: string;
  cancelled_at: TsNull;
  created_at: Generated<Date>;
}
export interface BadgesTable {
  id: string;
  metric: 'STREAK_DAYS' | 'REWARDED_SESSIONS' | 'FOCUS_HOURS';
  threshold: number;
  name: string;
  icon_key: string | null;
  retired_at: TsNull;
}
export interface UserBadgesTable {
  user_id: string;
  badge_id: string;
  awarded_at: Generated<Date>;
  showcase_slot: number | null;
}
export type ItemKind = 'AVATAR_FRAME' | 'BACKGROUND' | 'TITLE';
export interface ShopItemsTable {
  id: Generated<string>;
  kind: ItemKind;
  name: string;
  preview_key: string;
  price: number | null;
  status: Generated<'ON_SALE' | 'HIDDEN'>;
  is_default: Generated<boolean>;
  created_at: Generated<Date>;
  updated_at: Generated<Date>;
}
export interface UserItemsTable {
  id: Generated<string>;
  user_id: string;
  item_id: string;
  price_paid: number;
  ledger_entry_id: string | null;
  acquired_at: Generated<Date>;
}
export interface UserEquippedTable {
  user_id: string;
  kind: ItemKind;
  item_id: string;
  equipped_at: Generated<Date>;
}
export interface JournalsTable {
  id: Generated<string>;
  user_id: string;
  day: string;
  ciphertext: Buffer;
  nonce: Buffer;
  encrypted_dek: Buffer;
  kms_key_id: string;
  char_count: number;
  created_at: Generated<Date>;
  updated_at: Generated<Date>;
}
export interface MonthlyReportsTable {
  id: Generated<string>;
  group_id: string;
  period: string;
  period_end: string;
  status: Generated<'PENDING' | 'GENERATED' | 'FAILED'>;
  attempts: Generated<number>;
  owner_id_snapshot: string;
  member_count: number | null;
  group_visible: boolean | null;
  group_summary: ColumnType<Record<string, unknown> | null, string | null | undefined, string | null>;
  pdf_key: string | null;
  emailed_at: TsNull;
  generated_at: TsNull;
  expires_at: Ts;
  created_at: Generated<Date>;
}
export interface MonthlyReportRowsTable {
  report_id: string;
  user_id: string | null;
  display_name_snapshot: string | null;
  metrics: ColumnType<Record<string, unknown>, string, string>;
}
export interface JobRunsTable {
  id: Generated<string>;
  job: string;
  run_key: string;
  status: 'RUNNING' | 'SUCCEEDED' | 'FAILED';
  attempt: Generated<number>;
  started_at: Generated<Date>;
  finished_at: TsNull;
  error: string | null;
}

export interface Database {
  users: UsersTable;
  groups: GroupsTable;
  group_members: GroupMembersTable;
  consents: ConsentsTable;
  invite_attempts: InviteAttemptsTable;
  sessions: SessionsTable;
  session_members: SessionMembersTable;
  coin_ledger: CoinLedgerTable;
  daily_attendance: DailyAttendanceTable;
  achievement_log: AchievementLogTable;
  notifications: NotificationsTable;
  device_tokens: DeviceTokensTable;
  idempotency_keys: IdempotencyKeysTable;
  access_logs: AccessLogsTable;
  user_coin_balance: UserCoinBalanceView;
  explanations: ExplanationsTable;
  explanation_revisions: ExplanationRevisionsTable;
  appeals: AppealsTable;
  schedules: SchedulesTable;
  badges: BadgesTable;
  user_badges: UserBadgesTable;
  shop_items: ShopItemsTable;
  user_items: UserItemsTable;
  user_equipped: UserEquippedTable;
  journals: JournalsTable;
  monthly_reports: MonthlyReportsTable;
  monthly_report_rows: MonthlyReportRowsTable;
  job_runs: JobRunsTable;
}

export type DB = Kysely<Database>;

export function createDb(url: string): DB {
  return new Kysely<Database>({
    dialect: new PostgresDialect({ pool: new pg.Pool({ connectionString: url, max: 10 }) }),
  });
}

/** SQLSTATE từ lỗi pg. */
export const pgCode = (e: unknown): string | undefined => (e as { code?: string })?.code;
