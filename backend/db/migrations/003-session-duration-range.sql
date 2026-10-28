-- Remove only duration range checks; preserve the ends_at consistency check.
DO $$
DECLARE c record;
BEGIN
  FOR c IN SELECT conname, conrelid::regclass::text table_name FROM pg_constraint
    WHERE contype = 'c' AND conrelid::regclass::text IN ('sessions','schedules')
      AND pg_get_constraintdef(oid) LIKE '%duration_min%'
      AND pg_get_constraintdef(oid) NOT LIKE '%ends_at%'
  LOOP
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT IF EXISTS %I', c.table_name, c.conname);
  END LOOP;
END $$;
ALTER TABLE sessions ADD CONSTRAINT sessions_duration_min_range CHECK (duration_min BETWEEN 1 AND 240);
ALTER TABLE schedules ADD CONSTRAINT schedules_duration_min_range CHECK (duration_min BETWEEN 1 AND 240);
UPDATE system_params SET value = '{"min":1,"max":240}'::jsonb WHERE key = 'duration_min';
UPDATE system_params SET value = '1'::jsonb WHERE key = 'late_join_max_min';

-- Serialize new schedules/memberships against group dissolution.
CREATE OR REPLACE FUNCTION trg_require_active_group() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE current_status group_status;
BEGIN
  SELECT status INTO current_status FROM groups WHERE id = NEW.group_id FOR UPDATE;
  IF current_status <> 'ACTIVE' THEN
    RAISE EXCEPTION 'Nhóm không còn hoạt động' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS sessions_require_active_group ON sessions;
CREATE TRIGGER sessions_require_active_group BEFORE INSERT ON sessions
  FOR EACH ROW EXECUTE FUNCTION trg_require_active_group();
DROP TRIGGER IF EXISTS schedules_require_active_group ON schedules;
CREATE TRIGGER schedules_require_active_group BEFORE INSERT ON schedules
  FOR EACH ROW EXECUTE FUNCTION trg_require_active_group();
DROP TRIGGER IF EXISTS group_members_require_active_group ON group_members;
CREATE TRIGGER group_members_require_active_group BEFORE INSERT ON group_members
  FOR EACH ROW EXECUTE FUNCTION trg_require_active_group();
