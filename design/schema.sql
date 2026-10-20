-- =====================================================================
-- DropIt! — Lược đồ PostgreSQL 16 (Giai đoạn 3 Thiết kế)
-- Tài liệu đi kèm: design/02-du-lieu.md
-- Quy ước: thời gian lưu timestamptz (UTC); "ngày" nghiệp vụ là date theo
-- Asia/Ho_Chi_Minh (BR-55, §Thưởng) do ứng dụng tính và ghi sẵn.
-- Chạy: psql -v ON_ERROR_STOP=1 -f design/schema.sql
-- =====================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS btree_gist; -- ràng buộc EXCLUDE chống chồng phiên (BR-78)
CREATE EXTENSION IF NOT EXISTS citext;     -- email không phân biệt hoa thường

-- ---------------------------------------------------------------------
-- 1. Kiểu liệt kê
-- ---------------------------------------------------------------------
CREATE TYPE user_status        AS ENUM ('ACTIVE','LOCKED','DELETED');
CREATE TYPE group_status       AS ENUM ('ACTIVE','SCHEDULE_SUSPENDED','DISSOLVING','DISSOLVED');
    -- HOẠT ĐỘNG / TẠM NGƯNG LỊCH / CHỜ GIẢI TÁN / ĐÃ GIẢI TÁN (T-BA-37)
CREATE TYPE member_leave_reason AS ENUM ('LEFT','REMOVED','CONSENT_WITHDRAWN','ACCOUNT_DELETED','GROUP_DISSOLVED');
CREATE TYPE consent_action     AS ENUM ('GRANT','WITHDRAW');
CREATE TYPE session_status     AS ENUM ('SCHEDULED','COUNTDOWN','ACTIVE','COMPLETED','CANCELLED');
CREATE TYPE session_cancel_reason AS ENUM ('OWNER_CANCEL','NO_ATTENDEE','SERVER_OUTAGE','GROUP_DISSOLVED','OWNER_LOCKED','ADMIN');
CREATE TYPE member_state       AS ENUM (
    'INVITED','WAITING','FOCUSING','GRACE','PAUSED','DISCONNECTED',      -- chưa kết thúc
    'COMPLETED','EXITED','LOST','ABSENT','WITHDRAWN','VOID');             -- kết thúc
CREATE TYPE member_end_reason  AS ENUM ('USER_LEAVE','APP_LEFT','GRACE_EXPIRED','DISCONNECT_TIMEOUT',
    'CONSENT_WITHDRAWN','ACCOUNT_LOCKED','NO_SHOW','LOBBY_LEAVE','SESSION_CANCELLED','TIME_UP');
CREATE TYPE appeal_status      AS ENUM ('PENDING','IN_REVIEW','ESCALATED','EXEMPTED','REJECTED');
    -- CHỜ XỬ LÝ / ĐANG XỬ LÝ / CHUYỂN QUẢN TRỊ / MIỄN TRỪ / BÁC
CREATE TYPE ledger_type        AS ENUM ('SESSION_REWARD','SHOP_PURCHASE','ADMIN_ADJUST');
CREATE TYPE achievement_kind   AS ENUM ('CHECKIN','STREAK_INC','STREAK_BREAK','STREAK_RESTORE','BADGE_AWARD');
CREATE TYPE badge_metric       AS ENUM ('STREAK_DAYS','REWARDED_SESSIONS','FOCUS_HOURS');
CREATE TYPE item_kind          AS ENUM ('AVATAR_FRAME','BACKGROUND','TITLE');
CREATE TYPE item_status        AS ENUM ('ON_SALE','HIDDEN');            -- ĐANG BÁN / ĐÃ ẨN
CREATE TYPE report_status      AS ENUM ('PENDING','GENERATED','FAILED');
CREATE TYPE abuse_status       AS ENUM ('OPEN','IN_REVIEW','RESOLVED','DISMISSED');
CREATE TYPE viewer_role        AS ENUM ('OWNER','ADMIN');

-- ---------------------------------------------------------------------
-- 2. Hàm tiện ích chung
-- ---------------------------------------------------------------------
CREATE FUNCTION trg_set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END $$;

-- Chặn UPDATE/DELETE cho bảng chỉ-thêm. Ngoại lệ duy nhất: job xóa dữ liệu theo
-- thời hạn lưu/xóa tài khoản đặt `SET LOCAL dropit.purge = 'on'` (xem DQ-D03).
CREATE FUNCTION trg_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' AND current_setting('dropit.purge', true) = 'on' THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'Bảng % chỉ cho phép thêm (append-only)', TG_TABLE_NAME
    USING ERRCODE = 'check_violation';
END $$;

-- ---------------------------------------------------------------------
-- 3. Tham số hệ thống (BR-112)
-- ---------------------------------------------------------------------
CREATE TABLE system_params (
  key          text PRIMARY KEY,
  value        jsonb NOT NULL,
  configurable boolean NOT NULL DEFAULT true,       -- false = cố định (vd. duration, group_max_members)
  min_value    numeric,
  max_value    numeric,
  description  text,
  updated_by   uuid,                                 -- FK thêm sau users
  updated_at   timestamptz NOT NULL DEFAULT now()
);

INSERT INTO system_params(key, value, configurable, description) VALUES
 ('duration_min',            '[25,50]', false, 'BR-02'),
 ('countdown_s',             '5',   true, 'BR-04'),
 ('late_join_max_min',       '5',   true, 'BR-07'),
 ('grace_s',                 '3',   true, 'BR-11'),
 ('grace_max_per_session',   '1',   true, 'BR-13'),
 ('pause_max_count',         '1',   true, 'BR-16'),
 ('pause_max_min',           '5',   true, 'BR-16'),
 ('pause_reasons',           '["Cuộc gọi công việc","Đồng nghiệp gọi","Việc riêng gấp","Khác"]', true, 'BR-16 (giả định nội dung)'),
 ('heartbeat_s',             '5',   true, 'BR-19'),
 ('heartbeat_timeout_s',     '10',  true, 'BR-66'),
 ('disconnect_hold_s',       '10',  true, 'BR-19'),
 ('outage_ratio',            '0.8', true, 'BR-22'),
 ('outage_window_s',         '10',  true, 'BR-22'),
 ('lobby_open_min',          '10',  true, 'BR-63'),
 ('coins_25',                '10',  true, 'D-09'),
 ('coins_50',                '25',  true, 'D-09'),
 ('coins_daily_cap',         '100', true, 'D-09'),
 ('day_timezone',            '"Asia/Ho_Chi_Minh"', false, 'BR-112'),
 ('badge_milestones',        '{"STREAK_DAYS":[3,7,14,30,60,100],"REWARDED_SESSIONS":[10,50,100,500],"FOCUS_HOURS":[10,50,100]}', true, 'BR-52'),
 ('report_run_at',           '"02:00"', true, 'BR-56'),
 ('report_retry_max',        '3',   true, 'BR-101'),
 ('report_retry_deadline',   '"06:00"', true, 'BR-101'),
 ('group_report_min_members','5',   true, 'BR-104'),
 ('report_link_app_min',     '15',  true, 'BR-105'),
 ('retention_months',        '13',  true, 'BR-103'),
 ('account_purge_days',      '30',  true, 'BR-72'),
 ('access_log_merge_min',    '10',  true, 'BR-73'),
 ('access_log_retention_months','12', true, 'BR-73'),
 ('group_min_members',       '4',   false, 'BR-74, D-02'),
 ('group_max_members',       '10',  false, 'BR-74, D-02'),
 ('max_groups_owned',        '10',  true, 'BR-75'),
 ('invite_code_len',         '8',   true, 'BR-76'),
 ('invite_email_ttl_days',   '7',   true, 'BR-76'),
 ('invite_max_fail',         '5',   true, 'BR-76'),
 ('invite_lock_min',         '15',  true, 'BR-76'),
 ('schedule_min_lead_min',   '1',   true, 'BR-79'),
 ('reminder_min',            '5',   true, 'BR-79'),
 ('recurrence_max_weeks',    '12',  true, 'BR-113'),
 ('push_retry',              '1',   true, 'BR-81'),
 ('explanation_max_chars',   '500', true, 'BR-85'),
 ('explanation_submit_days', '7',   true, 'BR-85'),
 ('explanation_edit_h',      '24',  true, 'BR-85'),
 ('appeal_window_h',         '24',  true, 'BR-86'),
 ('appeal_escalate_h',       '72',  true, 'BR-86'),
 ('shop_price_min',          '10',  true, 'BR-93'),
 ('shop_price_max',          '1000',true, 'BR-93'),
 ('display_name_min',        '2',   true, 'BR-97'),
 ('display_name_max',        '30',  true, 'BR-97'),
 ('avatar_max_mb',           '5',   true, 'BR-98'),
 ('showcase_max_badges',     '3',   true, 'BR-99'),
 ('journal_max_chars',       '5000',true, 'BR-100'),
 ('admin_adjust_confirm',    '500', true, 'BR-107'),
 ('lock_dissolve_days',      '30',  true, 'BR-108'),
 ('abuse_merge_h',           '24',  true, 'BR-109');

-- ---------------------------------------------------------------------
-- 4. Người dùng & đồng ý (EP-01)
-- ---------------------------------------------------------------------
CREATE TABLE users (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cognito_sub     text UNIQUE,                       -- NULL sau khi xóa tài khoản
  email           citext UNIQUE,                     -- chỉ quản trị thấy (ma trận ai thấy gì)
  display_name    text NOT NULL,
  avatar_key      text,                              -- khóa S3, đọc qua URL ký hạn (BR-98)
  status          user_status NOT NULL DEFAULT 'ACTIVE',
  locked_at       timestamptz,
  lock_reason     text,
  show_streak     boolean NOT NULL DEFAULT false,    -- BR-99 mặc định ẩn
  current_streak  integer NOT NULL DEFAULT 0 CHECK (current_streak >= 0),   -- NHẠY CẢM: không trả cho chủ nhóm (D-12, BR-53)
  longest_streak  integer NOT NULL DEFAULT 0 CHECK (longest_streak >= current_streak),
  streak_last_inc_day date,                          -- chặn +1 hai lần/ngày (BR-49)
  deleted_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT users_display_name_len CHECK (char_length(btrim(display_name)) BETWEEN 2 AND 30),
  CONSTRAINT users_display_name_ctrl CHECK (display_name !~ '[[:cntrl:]]'),
  CONSTRAINT users_lock_consistent CHECK ((status = 'LOCKED') = (locked_at IS NOT NULL))
);
CREATE TRIGGER users_updated BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
ALTER TABLE system_params ADD CONSTRAINT system_params_updated_by_fk FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------
-- 5. Nhóm (EP-02)
-- ---------------------------------------------------------------------
CREATE TABLE groups (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id         uuid NOT NULL REFERENCES users(id),
  name             text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 60),
  report_purpose   text NOT NULL CHECK (char_length(report_purpose) BETWEEN 1 AND 500),  -- NFR-P09
  retention_months smallint NOT NULL DEFAULT 13 CHECK (retention_months BETWEEN 1 AND 13),
  consent_version  integer NOT NULL DEFAULT 1 CHECK (consent_version >= 1),  -- BR-71
  invite_code      char(8) NOT NULL,
  invite_code_rotated_at timestamptz NOT NULL DEFAULT now(),
  reminder_min     smallint NOT NULL DEFAULT 5 CHECK (reminder_min BETWEEN 0 AND 60),
  status           group_status NOT NULL DEFAULT 'ACTIVE',
  suspended_at     timestamptz,                      -- TẠM NGƯNG LỊCH (BR-108, lock_dissolve_days)
  dissolve_requested_at timestamptz,
  dissolved_at     timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  -- Bảng mã bỏ ký tự dễ nhầm 0/O/1/I/L (BR-76)
  CONSTRAINT groups_invite_code_fmt CHECK (invite_code ~ '^[A-HJKMNP-Z2-9]{8}$'),
  CONSTRAINT groups_dissolved_consistent CHECK ((status = 'DISSOLVED') = (dissolved_at IS NOT NULL))
);
-- Mã mời duy nhất trong các nhóm chưa giải tán
CREATE UNIQUE INDEX groups_invite_code_uq ON groups(invite_code) WHERE status <> 'DISSOLVED';
CREATE INDEX groups_owner_idx ON groups(owner_id) WHERE status <> 'DISSOLVED';
CREATE TRIGGER groups_updated BEFORE UPDATE ON groups FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- Giới hạn số nhóm chủ nhóm sở hữu (BR-75 (b), max_groups_owned)
CREATE FUNCTION trg_groups_owned_limit() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE lim int := (SELECT value::int FROM system_params WHERE key = 'max_groups_owned');
BEGIN
  IF (SELECT count(*) FROM groups WHERE owner_id = NEW.owner_id AND status <> 'DISSOLVED') >= lim THEN
    RAISE EXCEPTION 'Vượt số nhóm tối đa được tạo (%)', lim USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER groups_owned_limit BEFORE INSERT ON groups FOR EACH ROW EXECUTE FUNCTION trg_groups_owned_limit();

CREATE TABLE group_members (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id         uuid NOT NULL REFERENCES groups(id),
  user_id          uuid NOT NULL REFERENCES users(id),
  consent_version  integer NOT NULL CHECK (consent_version >= 1),  -- phiên bản đã đồng ý gần nhất
  consented_at     timestamptz NOT NULL,
  joined_at        timestamptz NOT NULL DEFAULT now(),
  left_at          timestamptz,
  leave_reason     member_leave_reason,
  removal_effective_at timestamptz,                  -- BR-77: xóa giữa phiên có hiệu lực sau ends_at
  CONSTRAINT gm_left_consistent CHECK ((left_at IS NULL) = (leave_reason IS NULL))
);
-- D-21 / BR-75 (a): một người là thành viên tối đa 1 nhóm tại một thời điểm
CREATE UNIQUE INDEX group_members_one_active_uq ON group_members(user_id) WHERE left_at IS NULL;
CREATE INDEX group_members_group_active_idx ON group_members(group_id) WHERE left_at IS NULL;
CREATE INDEX group_members_user_hist_idx ON group_members(user_id, joined_at);

-- D-25: chủ nhóm không là thành viên nhóm mình; BR-74: trần 10 thành viên;
-- nhóm phải HOẠT ĐỘNG mới nhận thành viên mới (T-BA-37)
CREATE FUNCTION trg_group_members_check() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE g groups%ROWTYPE; n int;
BEGIN
  SELECT * INTO g FROM groups WHERE id = NEW.group_id FOR UPDATE;  -- khóa nhóm, tránh đua sĩ số
  IF g.owner_id = NEW.user_id THEN
    RAISE EXCEPTION 'Chủ nhóm không là thành viên nhóm mình (D-25)' USING ERRCODE = 'check_violation';
  END IF;
  IF TG_OP = 'INSERT' THEN
    IF g.status <> 'ACTIVE' THEN
      RAISE EXCEPTION 'Nhóm không nhận thành viên mới ở trạng thái %', g.status USING ERRCODE = 'check_violation';
    END IF;
    SELECT count(*) INTO n FROM group_members WHERE group_id = NEW.group_id AND left_at IS NULL;
    IF n >= 10 THEN
      RAISE EXCEPTION 'Nhóm đã đủ 10 thành viên (BR-74)' USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER group_members_check BEFORE INSERT OR UPDATE OF group_id, user_id ON group_members
  FOR EACH ROW EXECUTE FUNCTION trg_group_members_check();

-- Đổi chủ nhóm (nếu có) cũng không được trùng thành viên đang hoạt động
CREATE FUNCTION trg_groups_owner_not_member() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM group_members WHERE group_id = NEW.id AND user_id = NEW.owner_id AND left_at IS NULL) THEN
    RAISE EXCEPTION 'Chủ nhóm không là thành viên nhóm mình (D-25)' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER groups_owner_not_member BEFORE UPDATE OF owner_id ON groups
  FOR EACH ROW EXECUTE FUNCTION trg_groups_owner_not_member();

-- Bản ghi đồng ý (chỉ-thêm): mỗi lần đồng ý/rút đồng ý một dòng (NFR-P, BR-71)
CREATE TABLE consents (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id          uuid NOT NULL REFERENCES users(id),
  group_id         uuid NOT NULL REFERENCES groups(id),
  consent_version  integer NOT NULL CHECK (consent_version >= 1),
  action           consent_action NOT NULL,
  purpose_snapshot text NOT NULL,                    -- mục đích báo cáo tại thời điểm đồng ý
  retention_months smallint NOT NULL,
  terms_hash       text NOT NULL,                    -- băm nội dung điều khoản/D-05 hiển thị
  client_info      text,                             -- phiên bản app/nền tảng, không IP chi tiết (giả định)
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX consents_user_group_idx ON consents(user_id, group_id, created_at DESC);
CREATE TRIGGER consents_append_only BEFORE UPDATE OR DELETE ON consents FOR EACH ROW EXECUTE FUNCTION trg_append_only();

-- Lời mời qua email (BR-76)
CREATE TABLE group_invites (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    uuid NOT NULL REFERENCES groups(id),
  email       citext NOT NULL,
  token_hash  text NOT NULL UNIQUE,
  invited_by  uuid NOT NULL REFERENCES users(id),
  expires_at  timestamptz NOT NULL,
  accepted_at timestamptz,
  revoked_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX group_invites_group_idx ON group_invites(group_id);

-- Đếm nhập mã sai (BR-76: invite_max_fail / 15 phút)
CREATE TABLE invite_attempts (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  success    boolean NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX invite_attempts_user_time_idx ON invite_attempts(user_id, created_at DESC);

-- ---------------------------------------------------------------------
-- 6. Lịch & phiên (EP-02, EP-03)
-- ---------------------------------------------------------------------
CREATE TABLE schedules (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id       uuid NOT NULL REFERENCES groups(id),
  created_by     uuid NOT NULL REFERENCES users(id),
  start_time     time NOT NULL,                      -- giờ địa phương Asia/Ho_Chi_Minh
  duration_min   smallint NOT NULL CHECK (duration_min IN (25, 50)),   -- BR-02
  weekdays       smallint[] NOT NULL CHECK (array_length(weekdays,1) BETWEEN 1 AND 7
                                            AND weekdays <@ ARRAY[1,2,3,4,5,6,7]::smallint[]), -- ISO 1=T2
  start_date     date NOT NULL,
  end_date       date NOT NULL,                      -- bắt buộc (BR-113)
  cancelled_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT schedules_range CHECK (end_date >= start_date AND end_date <= start_date + 7 * 12)  -- recurrence_max_weeks mặc định
);
CREATE INDEX schedules_group_idx ON schedules(group_id);

CREATE TABLE sessions (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id                uuid NOT NULL REFERENCES groups(id),
  schedule_id             uuid REFERENCES schedules(id),       -- NULL = phiên đơn lẻ
  duration_min            smallint NOT NULL CHECK (duration_min IN (25, 50)),  -- BR-02
  started_at              timestamptz NOT NULL,                 -- giờ lịch (BR-04)
  ends_at                 timestamptz NOT NULL,                 -- = started_at + duration_min phút (CHECK bên dưới)
  session_day             date NOT NULL,                        -- ngày của started_at theo day_timezone
  status                  session_status NOT NULL DEFAULT 'SCHEDULED',
  forfeited               boolean NOT NULL DEFAULT false,       -- BR-35: thuộc tính, không phải trạng thái
  forfeited_at            timestamptz,
  forfeit_trigger_user_id uuid REFERENCES users(id),
  cancel_reason           session_cancel_reason,
  cancelled_at            timestamptz,
  completed_at            timestamptz,
  created_by              uuid NOT NULL REFERENCES users(id),
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT sessions_forfeit_consistent CHECK (
    (forfeited AND forfeited_at IS NOT NULL AND forfeit_trigger_user_id IS NOT NULL)
    OR (NOT forfeited AND forfeited_at IS NULL AND forfeit_trigger_user_id IS NULL)),
  CONSTRAINT sessions_forfeit_only_active CHECK (NOT forfeited OR status IN ('ACTIVE','COMPLETED')),
  CONSTRAINT sessions_cancel_consistent CHECK ((status = 'CANCELLED') = (cancel_reason IS NOT NULL)),
  CONSTRAINT sessions_ends_at CHECK (ends_at = started_at + duration_min * interval '1 minute'),
  CONSTRAINT sessions_forfeit_in_window CHECK (forfeited_at IS NULL OR forfeited_at >= started_at),
  -- BR-78: không chồng phiên chưa hủy trong cùng nhóm
  CONSTRAINT sessions_no_overlap EXCLUDE USING gist (
    group_id WITH =,
    tstzrange(started_at, ends_at, '[)') WITH &&
  ) WHERE (status <> 'CANCELLED')
);
CREATE UNIQUE INDEX sessions_schedule_occurrence_uq ON sessions(schedule_id, started_at) WHERE schedule_id IS NOT NULL;
CREATE INDEX sessions_group_time_idx ON sessions(group_id, started_at DESC);
CREATE INDEX sessions_due_idx ON sessions(started_at) WHERE status IN ('SCHEDULED','COUNTDOWN','ACTIVE');
CREATE TRIGGER sessions_updated BEFORE UPDATE ON sessions FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- Máy trạng thái phiên (§Phiên 2.1); CANCELLED/COMPLETED là cuối.
-- Ngoại lệ: phiên COMPLETED được gỡ forfeited khi miễn trừ (BR-87) — chỉ đổi cờ, không đổi status.
CREATE FUNCTION trg_sessions_transition() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status AND NOT (
       (OLD.status = 'SCHEDULED' AND NEW.status IN ('COUNTDOWN','CANCELLED'))
    OR (OLD.status = 'COUNTDOWN' AND NEW.status IN ('ACTIVE','CANCELLED'))
    OR (OLD.status = 'ACTIVE'    AND NEW.status IN ('COMPLETED','CANCELLED'))) THEN
    RAISE EXCEPTION 'Chuyển trạng thái phiên không hợp lệ: % -> %', OLD.status, NEW.status
      USING ERRCODE = 'check_violation';
  END IF;
  IF OLD.status IN ('COMPLETED','CANCELLED') AND (NEW.started_at, NEW.duration_min, NEW.group_id)
       IS DISTINCT FROM (OLD.started_at, OLD.duration_min, OLD.group_id) THEN
    RAISE EXCEPTION 'Phiên đã kết thúc, không sửa được' USING ERRCODE = 'check_violation';
  END IF;
  IF OLD.status <> 'SCHEDULED' AND (NEW.started_at, NEW.duration_min) IS DISTINCT FROM (OLD.started_at, OLD.duration_min) THEN
    RAISE EXCEPTION 'Chỉ sửa giờ/thời lượng khi phiên SCHEDULED (BR-79)' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER sessions_transition BEFORE UPDATE ON sessions FOR EACH ROW EXECUTE FUNCTION trg_sessions_transition();

CREATE TABLE session_members (
  session_id        uuid NOT NULL REFERENCES sessions(id),
  user_id           uuid NOT NULL REFERENCES users(id),
  state             member_state NOT NULL DEFAULT 'INVITED',
  is_final          boolean GENERATED ALWAYS AS (state IN ('COMPLETED','EXITED','LOST','ABSENT','WITHDRAWN','VOID')) STORED,
  end_reason        member_end_reason,
  joined_at         timestamptz,                      -- vào phòng chờ / vào phiên
  late_join         boolean NOT NULL DEFAULT false,   -- BR-07
  exited_at         timestamptz,
  ended_at          timestamptz,
  grace_used        smallint NOT NULL DEFAULT 0 CHECK (grace_used >= 0),
  pause_count       smallint NOT NULL DEFAULT 0 CHECK (pause_count >= 0),
  pause_seconds     integer  NOT NULL DEFAULT 0 CHECK (pause_seconds >= 0),
  focus_seconds     integer  NOT NULL DEFAULT 0 CHECK (focus_seconds BETWEEN 0 AND 3000),  -- ≤ 50 phút
  exempted          boolean NOT NULL DEFAULT false,   -- BR-87, chỉ cho EXITED
  coins_awarded     integer NOT NULL DEFAULT 0 CHECK (coins_awarded >= 0),  -- bản sao hiển thị; nguồn thật là coin_ledger
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (session_id, user_id),
  CONSTRAINT sm_exempt_only_exited CHECK (NOT exempted OR state = 'EXITED'),
  CONSTRAINT sm_exited_time CHECK ((state = 'EXITED') = (exited_at IS NOT NULL)),
  CONSTRAINT sm_final_time CHECK (NOT (state IN ('COMPLETED','EXITED','LOST','ABSENT','WITHDRAWN','VOID')) OR ended_at IS NOT NULL)
);
CREATE INDEX session_members_user_idx ON session_members(user_id, created_at DESC);
-- BR-09: một người chỉ có một trạng thái chưa kết thúc tại một thời điểm (mọi phiên)
CREATE UNIQUE INDEX session_members_one_live_uq ON session_members(user_id)
  WHERE state IN ('WAITING','FOCUSING','GRACE','PAUSED','DISCONNECTED');
CREATE TRIGGER session_members_updated BEFORE UPDATE ON session_members FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- BR-32: trạng thái cuối bất biến (chỉ cho phép bật exempted / ghi coins_awarded sau đó);
-- D-25/BR-114: chủ nhóm không có dòng trong phiên nhóm mình.
CREATE FUNCTION trg_session_members_check() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF EXISTS (SELECT 1 FROM sessions s JOIN groups g ON g.id = s.group_id
               WHERE s.id = NEW.session_id AND g.owner_id = NEW.user_id) THEN
      RAISE EXCEPTION 'Chủ nhóm không tham gia phiên (D-25)' USING ERRCODE = 'check_violation';
    END IF;
  ELSIF OLD.is_final THEN
    IF NEW.state <> OLD.state OR NEW.focus_seconds <> OLD.focus_seconds
       OR NEW.exited_at IS DISTINCT FROM OLD.exited_at OR NEW.ended_at IS DISTINCT FROM OLD.ended_at
       OR (OLD.exempted AND NOT NEW.exempted) THEN
      RAISE EXCEPTION 'Trạng thái cuối của thành viên là bất biến (BR-32)' USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER session_members_check BEFORE INSERT OR UPDATE ON session_members
  FOR EACH ROW EXECUTE FUNCTION trg_session_members_check();

-- Tạm dừng (lý do, thời lượng) — chủ nhóm thấy (ma trận ai thấy gì); xóa sau retention_months
CREATE TABLE session_pauses (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  session_id  uuid NOT NULL,
  user_id     uuid NOT NULL,
  reason      text NOT NULL,
  started_at  timestamptz NOT NULL,
  ended_at    timestamptz,
  FOREIGN KEY (session_id, user_id) REFERENCES session_members(session_id, user_id),
  CHECK (ended_at IS NULL OR ended_at > started_at)
);
CREATE INDEX session_pauses_sm_idx ON session_pauses(session_id, user_id);

-- ---------------------------------------------------------------------
-- 7. Giải trình & khiếu nại (EP-04)
-- ---------------------------------------------------------------------
CREATE TABLE explanations (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id  uuid NOT NULL,
  user_id     uuid NOT NULL,
  body        text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 500),  -- explanation_max_chars
  added_after_report boolean NOT NULL DEFAULT false,  -- BR-102 nhãn "thêm sau khi tạo báo cáo"
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (session_id, user_id) REFERENCES session_members(session_id, user_id),
  UNIQUE (session_id, user_id)                         -- một giải trình/sự kiện EXITED (BR-85)
);
CREATE TRIGGER explanations_updated BEFORE UPDATE ON explanations FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

CREATE TABLE appeals (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id         uuid NOT NULL,
  user_id            uuid NOT NULL,
  group_id           uuid NOT NULL REFERENCES groups(id),
  body               text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),
  suspect_system_error boolean NOT NULL DEFAULT false,
  status             appeal_status NOT NULL,
  handler_id         uuid REFERENCES users(id),
  decision_reason    text,
  opened_at          timestamptz,
  escalated_at       timestamptz,
  decided_at         timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (session_id, user_id) REFERENCES session_members(session_id, user_id),
  UNIQUE (session_id, user_id),                        -- một khiếu nại/sự kiện (BR-86)
  CONSTRAINT appeals_decision CHECK (
    (status IN ('EXEMPTED','REJECTED')) = (decided_at IS NOT NULL)
    AND (status NOT IN ('EXEMPTED','REJECTED') OR (decision_reason IS NOT NULL AND handler_id IS NOT NULL)))
);
CREATE INDEX appeals_group_open_idx ON appeals(group_id) WHERE status IN ('PENDING','IN_REVIEW');
CREATE INDEX appeals_escalated_idx ON appeals(created_at) WHERE status = 'ESCALATED';
CREATE TRIGGER appeals_updated BEFORE UPDATE ON appeals FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- Máy trạng thái khiếu nại (T-BA-37)
CREATE FUNCTION trg_appeals_transition() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status NOT IN ('PENDING','ESCALATED') THEN
      RAISE EXCEPTION 'Khiếu nại mới chỉ ở CHỜ XỬ LÝ hoặc CHUYỂN QUẢN TRỊ' USING ERRCODE = 'check_violation';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM session_members WHERE session_id = NEW.session_id
                   AND user_id = NEW.user_id AND state = 'EXITED') THEN
      RAISE EXCEPTION 'Chỉ khiếu nại sự kiện EXITED của chính mình (BR-86)' USING ERRCODE = 'check_violation';
    END IF;
  ELSIF NEW.status IS DISTINCT FROM OLD.status AND NOT (
       (OLD.status = 'PENDING'   AND NEW.status IN ('IN_REVIEW','ESCALATED','EXEMPTED','REJECTED'))
    OR (OLD.status = 'IN_REVIEW' AND NEW.status IN ('ESCALATED','EXEMPTED','REJECTED'))
    OR (OLD.status = 'ESCALATED' AND NEW.status IN ('EXEMPTED','REJECTED'))) THEN
    RAISE EXCEPTION 'Chuyển trạng thái khiếu nại không hợp lệ: % -> %', OLD.status, NEW.status
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER appeals_transition BEFORE INSERT OR UPDATE ON appeals FOR EACH ROW EXECUTE FUNCTION trg_appeals_transition();

-- ---------------------------------------------------------------------
-- 8. Coins (EP-06) — NHẠY CẢM: không trả cho chủ nhóm (BR-53, Q-23)
-- ---------------------------------------------------------------------
CREATE TABLE coin_ledger (
  entry_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES users(id),
  amount          integer NOT NULL CHECK (amount <> 0),
  type            ledger_type NOT NULL,
  ref_id          uuid,                               -- session_id / user_item id / admin_audit id
  reward_date     date,                               -- ngày tính trần, chỉ SESSION_REWARD
  reason          text NOT NULL,                      -- vd. SESSION_COMPLETE, APPEAL_RESTORE, lý do admin
  idempotency_key text NOT NULL UNIQUE,               -- chống gửi lại từ client/job
  balance_after   integer NOT NULL CHECK (balance_after >= 0),  -- số dư không âm (BR-45)
  created_by      uuid REFERENCES users(id),          -- admin cho ADMIN_ADJUST
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT cl_reward_shape CHECK (
    (type = 'SESSION_REWARD' AND amount > 0 AND reward_date IS NOT NULL AND ref_id IS NOT NULL)
    OR (type = 'SHOP_PURCHASE' AND amount < 0 AND reward_date IS NULL AND ref_id IS NOT NULL)
    OR (type = 'ADMIN_ADJUST' AND reward_date IS NULL AND created_by IS NOT NULL AND char_length(reason) > 0))
);
-- BR-45: chống ghi trùng thưởng phiên
CREATE UNIQUE INDEX coin_ledger_reward_uq ON coin_ledger(type, ref_id, user_id) WHERE type = 'SESSION_REWARD';
CREATE INDEX coin_ledger_user_time_idx ON coin_ledger(user_id, created_at DESC);
CREATE INDEX coin_ledger_user_day_idx ON coin_ledger(user_id, reward_date) WHERE type = 'SESSION_REWARD';  -- tính trần BR-43

-- Số dư + trần ngày: tính trong trigger, khóa dòng users để tuần tự hóa theo người
CREATE FUNCTION trg_coin_ledger_insert() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE bal int; day_sum int; cap int := (SELECT value::int FROM system_params WHERE key = 'coins_daily_cap');
BEGIN
  PERFORM 1 FROM users WHERE id = NEW.user_id FOR UPDATE;
  SELECT COALESCE(sum(amount),0) INTO bal FROM coin_ledger WHERE user_id = NEW.user_id;
  IF bal + NEW.amount < 0 THEN
    RAISE EXCEPTION 'Không đủ Coins (số dư %, cần %)', bal, -NEW.amount USING ERRCODE = 'check_violation';
  END IF;
  IF NEW.type = 'SESSION_REWARD' THEN
    SELECT COALESCE(sum(amount),0) INTO day_sum FROM coin_ledger
     WHERE user_id = NEW.user_id AND type = 'SESSION_REWARD' AND reward_date = NEW.reward_date;
    IF day_sum + NEW.amount > cap THEN
      RAISE EXCEPTION 'Vượt trần % Coins/ngày (BR-43); ứng dụng phải cắt về phần còn lại', cap
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  NEW.balance_after := bal + NEW.amount;
  RETURN NEW;
END $$;
CREATE TRIGGER coin_ledger_insert BEFORE INSERT ON coin_ledger FOR EACH ROW EXECUTE FUNCTION trg_coin_ledger_insert();
CREATE TRIGGER coin_ledger_append_only BEFORE UPDATE OR DELETE ON coin_ledger FOR EACH ROW EXECUTE FUNCTION trg_append_only();

CREATE VIEW user_coin_balance AS
  SELECT u.id AS user_id, COALESCE(sum(c.amount),0)::int AS balance
  FROM users u LEFT JOIN coin_ledger c ON c.user_id = u.id GROUP BY u.id;

-- ---------------------------------------------------------------------
-- 9. Điểm danh, chuỗi, huy hiệu (EP-05) — chuỗi NHẠY CẢM (D-12)
-- ---------------------------------------------------------------------
CREATE TABLE daily_attendance (
  user_id        uuid NOT NULL REFERENCES users(id),
  day            date NOT NULL,
  group_id       uuid NOT NULL REFERENCES groups(id),    -- D-21: thực tế một nhóm; dùng cho báo cáo trong nhóm
  first_session_id uuid NOT NULL REFERENCES sessions(id),
  sessions_completed smallint NOT NULL DEFAULT 1 CHECK (sessions_completed >= 1),
  focus_minutes  integer NOT NULL DEFAULT 0 CHECK (focus_minutes >= 0),
  created_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, day)                             -- tối đa 1 điểm danh/ngày (BR-46)
);
CREATE INDEX daily_attendance_group_day_idx ON daily_attendance(group_id, day);

-- Nhật ký thành tích chỉ-thêm (BR-92); users.current_streak/longest_streak tái lập được từ đây
CREATE TABLE achievement_log (
  entry_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id         uuid NOT NULL REFERENCES users(id),
  kind            achievement_kind NOT NULL,
  value_before    integer,
  value_after     integer,
  day             date NOT NULL,
  ref_session_id  uuid REFERENCES sessions(id),
  ref_badge_id    text,
  reason          text NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX achievement_log_user_idx ON achievement_log(user_id, created_at);
CREATE UNIQUE INDEX achievement_log_inc_once_uq ON achievement_log(user_id, day) WHERE kind = 'STREAK_INC';  -- BR-49
CREATE TRIGGER achievement_log_append_only BEFORE UPDATE OR DELETE ON achievement_log FOR EACH ROW EXECUTE FUNCTION trg_append_only();

-- (Thay cho bảng "streaks" riêng: chuỗi là 2 cột trên users + achievement_log — xem DQ-D05)

CREATE TABLE badges (
  id          text PRIMARY KEY,                       -- vd. STREAK_7, SESS_50, HOURS_10
  metric      badge_metric NOT NULL,
  threshold   integer NOT NULL CHECK (threshold > 0),
  name        text NOT NULL,
  icon_key    text,
  retired_at  timestamptz,                            -- mốc bị bỏ: không thu hồi (BR-90)
  UNIQUE (metric, threshold)
);
INSERT INTO badges(id, metric, threshold, name) VALUES
 ('STREAK_3','STREAK_DAYS',3,'Chuỗi 3 ngày'),   ('STREAK_7','STREAK_DAYS',7,'Chuỗi 7 ngày'),
 ('STREAK_14','STREAK_DAYS',14,'Chuỗi 14 ngày'),('STREAK_30','STREAK_DAYS',30,'Chuỗi 30 ngày'),
 ('STREAK_60','STREAK_DAYS',60,'Chuỗi 60 ngày'),('STREAK_100','STREAK_DAYS',100,'Chuỗi 100 ngày'),
 ('SESS_10','REWARDED_SESSIONS',10,'10 phiên'),  ('SESS_50','REWARDED_SESSIONS',50,'50 phiên'),
 ('SESS_100','REWARDED_SESSIONS',100,'100 phiên'),('SESS_500','REWARDED_SESSIONS',500,'500 phiên'),
 ('HOURS_10','FOCUS_HOURS',10,'10 giờ tập trung'),('HOURS_50','FOCUS_HOURS',50,'50 giờ tập trung'),
 ('HOURS_100','FOCUS_HOURS',100,'100 giờ tập trung');

CREATE TABLE user_badges (
  user_id       uuid NOT NULL REFERENCES users(id),
  badge_id      text NOT NULL REFERENCES badges(id),
  awarded_at    timestamptz NOT NULL DEFAULT now(),
  showcase_slot smallint CHECK (showcase_slot BETWEEN 1 AND 3),   -- showcase_max_badges (BR-99)
  PRIMARY KEY (user_id, badge_id)                     -- cấp một lần (BR-52)
);
CREATE UNIQUE INDEX user_badges_slot_uq ON user_badges(user_id, showcase_slot) WHERE showcase_slot IS NOT NULL;

-- ---------------------------------------------------------------------
-- 10. Shop & trang bị (EP-06, EP-07)
-- ---------------------------------------------------------------------
CREATE TABLE shop_items (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind        item_kind NOT NULL,
  name        text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 40),
  preview_key text NOT NULL,
  price       integer CHECK (price > 0),              -- NULL cho món mặc định không bán
  status      item_status NOT NULL DEFAULT 'ON_SALE',
  is_default  boolean NOT NULL DEFAULT false,         -- BR-95
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT shop_items_default_unsold CHECK (NOT is_default OR (price IS NULL AND status = 'HIDDEN')),
  CONSTRAINT shop_items_price_needed CHECK (is_default OR price IS NOT NULL)
);
CREATE UNIQUE INDEX shop_items_one_default_uq ON shop_items(kind) WHERE is_default;
CREATE TRIGGER shop_items_updated BEFORE UPDATE ON shop_items FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

CREATE TABLE user_items (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES users(id),
  item_id       uuid NOT NULL REFERENCES shop_items(id),
  price_paid    integer NOT NULL CHECK (price_paid >= 0),
  ledger_entry_id uuid UNIQUE REFERENCES coin_ledger(entry_id),  -- cùng giao dịch (BR-94)
  acquired_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, item_id)                           -- mỗi món mua tối đa 1 lần (BR-94)
);

CREATE TABLE user_equipped (
  user_id   uuid NOT NULL REFERENCES users(id),
  kind      item_kind NOT NULL,
  item_id   uuid NOT NULL REFERENCES shop_items(id),
  equipped_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, kind)                         -- mỗi loại tối đa 1 món (BR-95)
);
CREATE FUNCTION trg_user_equipped_check() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE it shop_items%ROWTYPE;
BEGIN
  SELECT * INTO it FROM shop_items WHERE id = NEW.item_id;
  IF it.kind <> NEW.kind THEN
    RAISE EXCEPTION 'Sai loại món' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT it.is_default AND NOT EXISTS (SELECT 1 FROM user_items WHERE user_id = NEW.user_id AND item_id = NEW.item_id) THEN
    RAISE EXCEPTION 'Chỉ trang bị món đã sở hữu hoặc mặc định (BR-95)' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER user_equipped_check BEFORE INSERT OR UPDATE ON user_equipped FOR EACH ROW EXECUTE FUNCTION trg_user_equipped_check();

-- ---------------------------------------------------------------------
-- 11. Nhật ký cá nhân (EP-07) — MÃ HÓA; chủ nhóm/quản trị không đọc (NFR-P05)
-- ---------------------------------------------------------------------
CREATE TABLE journals (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  day           date NOT NULL,                        -- theo thời điểm server nhận (BR-100)
  ciphertext    bytea NOT NULL,                       -- AES-256-GCM, khóa dữ liệu bọc bởi KMS
  nonce         bytea NOT NULL,
  encrypted_dek bytea NOT NULL,                       -- envelope encryption (KMS GenerateDataKey)
  kms_key_id    text NOT NULL,
  char_count    integer NOT NULL CHECK (char_count BETWEEN 1 AND 5000),  -- journal_max_chars
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, day)                               -- 1 mục/ngày (BR-100)
);
CREATE TRIGGER journals_updated BEFORE UPDATE ON journals FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ---------------------------------------------------------------------
-- 12. Báo cáo tháng (EP-08) — bản chụp bất biến (BR-56)
-- ---------------------------------------------------------------------
CREATE TABLE monthly_reports (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id         uuid NOT NULL REFERENCES groups(id),
  period           date NOT NULL CHECK (extract(day FROM period) = 1),   -- ngày 1 của tháng
  period_end       date NOT NULL,                     -- < cuối tháng nếu giải tán giữa tháng (BR-62)
  status           report_status NOT NULL DEFAULT 'PENDING',
  attempts         smallint NOT NULL DEFAULT 0 CHECK (attempts BETWEEN 0 AND 4),
  owner_id_snapshot uuid NOT NULL,                    -- người nhận (chủ nhóm lúc tạo)
  member_count     smallint,                          -- BR-104, đếm lúc tạo, không đổi
  group_visible    boolean,                           -- member_count >= group_report_min_members
  group_summary    jsonb,                             -- chỉ số nhóm (§Báo cáo §3)
  pdf_key          text,                              -- S3, Should (D-24)
  emailed_at       timestamptz,
  generated_at     timestamptz,
  expires_at       timestamptz NOT NULL,              -- period + retention_months
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (group_id, period),                          -- idempotent (BR-101)
  CONSTRAINT mr_generated CHECK ((status = 'GENERATED') = (generated_at IS NOT NULL AND group_summary IS NOT NULL)),
  CONSTRAINT mr_no_coins_streak CHECK (group_summary IS NULL
    OR NOT (group_summary ?| ARRAY['coins','balance','current_streak','longest_streak','streak']))  -- BR-53
);
CREATE TABLE monthly_report_rows (
  report_id        uuid NOT NULL REFERENCES monthly_reports(id) ON DELETE CASCADE,
  user_id          uuid,                              -- NULL sau xóa tài khoản (ẩn danh)
  display_name_snapshot text,
  metrics          jsonb NOT NULL,                    -- §Báo cáo §2; KHÔNG có Coins/chuỗi (BR-53)
  CONSTRAINT mrr_no_coins_streak CHECK (NOT (metrics ?| ARRAY['coins','balance','current_streak','longest_streak','streak'])),
  UNIQUE (report_id, user_id)
);
CREATE INDEX monthly_report_rows_user_idx ON monthly_report_rows(user_id);
-- Bản chụp: không sửa sau khi GENERATED (BR-56). Chỉ được ghi thêm emailed_at, pdf_key
-- (PDF Should, D-24) và attempts. DELETE chỉ qua job hết hạn lưu (dropit.purge = 'on').
CREATE FUNCTION trg_monthly_reports_freeze() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.status <> 'GENERATED' OR current_setting('dropit.purge', true) = 'on' THEN RETURN OLD; END IF;
    RAISE EXCEPTION 'Báo cáo đã tạo chỉ xóa khi hết hạn lưu (BR-56)' USING ERRCODE = 'check_violation';
  END IF;
  IF OLD.status = 'GENERATED' AND
     (NEW.id, NEW.group_id, NEW.period, NEW.period_end, NEW.status, NEW.owner_id_snapshot, NEW.member_count,
      NEW.group_visible, NEW.group_summary, NEW.generated_at, NEW.expires_at, NEW.created_at)
     IS DISTINCT FROM
     (OLD.id, OLD.group_id, OLD.period, OLD.period_end, OLD.status, OLD.owner_id_snapshot, OLD.member_count,
      OLD.group_visible, OLD.group_summary, OLD.generated_at, OLD.expires_at, OLD.created_at) THEN
    RAISE EXCEPTION 'Báo cáo đã tạo là bản chụp, không sửa (BR-56)' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER monthly_reports_freeze BEFORE UPDATE OR DELETE ON monthly_reports FOR EACH ROW EXECUTE FUNCTION trg_monthly_reports_freeze();

-- Dòng của báo cáo đã GENERATED: không thêm/sửa/xóa. Ngoại lệ: ẩn danh hóa khi xóa tài khoản
-- (chỉ đặt user_id/display_name_snapshot về NULL) và xóa qua job hết hạn lưu (dropit.purge).
CREATE FUNCTION trg_monthly_report_rows_freeze() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE rid uuid := CASE WHEN TG_OP = 'INSERT' THEN NEW.report_id ELSE OLD.report_id END;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM monthly_reports WHERE id = rid AND status = 'GENERATED') THEN
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  END IF;
  IF TG_OP = 'DELETE' AND current_setting('dropit.purge', true) = 'on' THEN RETURN OLD; END IF;
  IF TG_OP = 'UPDATE' AND NEW.report_id = OLD.report_id AND NEW.metrics = OLD.metrics
     AND NEW.user_id IS NULL AND (NEW.display_name_snapshot IS NULL
                                  OR NEW.display_name_snapshot IS NOT DISTINCT FROM OLD.display_name_snapshot) THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'Dòng báo cáo đã tạo là bản chụp, không sửa (BR-56)' USING ERRCODE = 'check_violation';
END $$;
CREATE TRIGGER monthly_report_rows_freeze BEFORE INSERT OR UPDATE OR DELETE ON monthly_report_rows
  FOR EACH ROW EXECUTE FUNCTION trg_monthly_report_rows_freeze();

-- ---------------------------------------------------------------------
-- 13. Thông báo (EP-04) — hộp thông báo trong app (BR-81)
-- ---------------------------------------------------------------------
CREATE TABLE notifications (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type          text NOT NULL,                        -- MEMBER_EXITED, SESSION_FORFEITED, SESSION_RESULT, ...
  title         text NOT NULL,
  body          text NOT NULL,
  data          jsonb NOT NULL DEFAULT '{}',          -- session_id, group_id...; KHÔNG Coins/chuỗi khi người nhận là chủ nhóm
  dedupe_key    text,
  push_status   text NOT NULL DEFAULT 'NONE' CHECK (push_status IN ('NONE','PENDING','SENT','FAILED')),
  push_attempts smallint NOT NULL DEFAULT 0,
  read_at       timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, dedupe_key)
);
CREATE INDEX notifications_inbox_idx ON notifications(user_id, created_at DESC);
CREATE INDEX notifications_unread_idx ON notifications(user_id) WHERE read_at IS NULL;

CREATE TABLE device_tokens (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform    text NOT NULL CHECK (platform IN ('IOS','ANDROID')),
  token       text NOT NULL UNIQUE,
  sns_endpoint_arn text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 14. Nhật ký truy cập (BR-73, NFR-P07) — chỉ-thêm; "gộp" bằng cột count
--     (cập nhật view_count/last_viewed_at là ngoại lệ duy nhất, xem DQ-D04)
-- ---------------------------------------------------------------------
CREATE TABLE access_logs (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  viewer_id       uuid,                               -- giữ sau khi người xem xóa tài khoản (ẩn danh hóa)
  viewer_role     viewer_role NOT NULL,
  subject_user_id uuid NOT NULL,                      -- người bị xem
  object_type     text NOT NULL CHECK (object_type IN ('SESSION','REPORT','LEDGER','APPEAL','STREAK','EXPORT','EXPLANATION','ATTENDANCE')),
  object_id       uuid,
  group_id        uuid,
  purpose         text,                               -- bắt buộc với quản trị (xử lý khiếu nại/lỗi)
  view_count      integer NOT NULL DEFAULT 1 CHECK (view_count >= 1),
  first_viewed_at timestamptz NOT NULL DEFAULT now(),
  last_viewed_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT al_admin_purpose CHECK (viewer_role <> 'ADMIN' OR purpose IS NOT NULL)
);
CREATE INDEX access_logs_subject_idx ON access_logs(subject_user_id, last_viewed_at DESC);
CREATE INDEX access_logs_merge_idx ON access_logs(viewer_id, subject_user_id, object_type, object_id, last_viewed_at DESC);
CREATE FUNCTION trg_access_logs_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF current_setting('dropit.purge', true) = 'on' THEN RETURN OLD; END IF;
    RAISE EXCEPTION 'access_logs chỉ-thêm' USING ERRCODE = 'check_violation';
  END IF;
  -- UPDATE chỉ được tăng đếm khi gộp, hoặc ẩn danh viewer khi xóa tài khoản
  IF (NEW.viewer_role, NEW.subject_user_id, NEW.object_type, NEW.object_id, NEW.first_viewed_at)
       IS DISTINCT FROM (OLD.viewer_role, OLD.subject_user_id, OLD.object_type, OLD.object_id, OLD.first_viewed_at)
     OR NEW.view_count < OLD.view_count
     OR (NEW.viewer_id IS DISTINCT FROM OLD.viewer_id AND NEW.viewer_id IS NOT NULL) THEN
    RAISE EXCEPTION 'access_logs chỉ cho phép gộp lượt xem' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER access_logs_guard BEFORE UPDATE OR DELETE ON access_logs FOR EACH ROW EXECUTE FUNCTION trg_access_logs_guard();

-- ---------------------------------------------------------------------
-- 15. Quản trị (EP-09)
-- ---------------------------------------------------------------------
CREATE TABLE abuse_reports (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   uuid REFERENCES users(id) ON DELETE SET NULL,
  target_user_id uuid REFERENCES users(id),
  target_group_id uuid REFERENCES groups(id),
  category      text NOT NULL,
  body          text CHECK (char_length(body) <= 1000),
  status        abuse_status NOT NULL DEFAULT 'OPEN',
  merged_into   uuid REFERENCES abuse_reports(id),    -- gộp trong abuse_merge_h (BR-109)
  handler_id    uuid REFERENCES users(id),
  resolution    text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  resolved_at   timestamptz,
  CONSTRAINT abuse_target CHECK (target_user_id IS NOT NULL OR target_group_id IS NOT NULL),
  CONSTRAINT abuse_resolved CHECK ((status IN ('RESOLVED','DISMISSED')) = (resolved_at IS NOT NULL))
);
CREATE INDEX abuse_reports_open_idx ON abuse_reports(created_at) WHERE status IN ('OPEN','IN_REVIEW');

CREATE TABLE admin_audit (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  admin_id    uuid NOT NULL,
  action      text NOT NULL,                          -- LOCK_USER, ADJUST_COINS, SET_PARAM, HIDE_ITEM, DISSOLVE_GROUP...
  target_type text NOT NULL,
  target_id   text NOT NULL,
  before      jsonb,
  after       jsonb,
  note        text NOT NULL CHECK (char_length(note) > 0),
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX admin_audit_target_idx ON admin_audit(target_type, target_id, created_at DESC);
CREATE TRIGGER admin_audit_append_only BEFORE UPDATE OR DELETE ON admin_audit FOR EACH ROW EXECUTE FUNCTION trg_append_only();

-- Idempotency REST (03-api-socket P6): (người, khóa) → phản hồi đã trả, giữ 24 giờ.
-- Socket event_id C→S giữ trong bộ nhớ theo (người, phiên) đến hết phiên + 1 giờ (DQ-A11).
CREATE TABLE idempotency_keys (
  user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  key           uuid NOT NULL,                        -- header Idempotency-Key
  method        text NOT NULL,
  path          text NOT NULL,
  request_hash  text NOT NULL,                        -- khác thân → 422 IDEMPOTENCY_MISMATCH
  status_code   smallint,
  response_body jsonb,
  created_at    timestamptz NOT NULL DEFAULT now(),
  expires_at    timestamptz NOT NULL DEFAULT now() + interval '24 hours',
  PRIMARY KEY (user_id, key)
);
CREATE INDEX idempotency_keys_expiry_idx ON idempotency_keys(expires_at);

-- Lượt chạy job định kỳ (01-kien-truc §2.4): chạy bù sau khởi động lại, chống chạy trùng
CREATE TABLE job_runs (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  job         text NOT NULL,                          -- open-scheduled-sessions, monthly-report...
  run_key     text NOT NULL,                          -- vd. '2026-11' cho monthly-report
  status      text NOT NULL CHECK (status IN ('RUNNING','SUCCEEDED','FAILED')),
  attempt     smallint NOT NULL DEFAULT 1 CHECK (attempt >= 1),
  started_at  timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  error       text,
  UNIQUE (job, run_key, attempt)
);

-- ---------------------------------------------------------------------
-- 16. Khung nhìn cho chủ nhóm — KHÔNG có Coins/chuỗi (BR-53, D-12, BR-116)
--     API chủ nhóm chỉ đọc qua view này, lọc thêm group_id theo quyền (D-10).
-- ---------------------------------------------------------------------
CREATE VIEW owner_session_member_view AS
  SELECT s.group_id, sm.session_id, s.started_at, s.duration_min, s.forfeited,
         s.forfeit_trigger_user_id, sm.user_id, u.display_name,
         sm.state, sm.late_join, sm.exited_at, sm.pause_count, sm.pause_seconds,
         sm.focus_seconds, sm.exempted
  FROM session_members sm
  JOIN sessions s ON s.id = sm.session_id
  JOIN users u ON u.id = sm.user_id
  WHERE sm.is_final;                                   -- chỉ dữ liệu đã chốt (BR-116)

COMMIT;
