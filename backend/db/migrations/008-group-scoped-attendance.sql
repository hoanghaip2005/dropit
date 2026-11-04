-- D-30: keep completed-session attendance rollups separate per group and day.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'daily_attendance'::regclass
      AND contype = 'p'
      AND pg_get_constraintdef(oid) = 'PRIMARY KEY (user_id, day, group_id)'
  ) THEN
    ALTER TABLE daily_attendance DROP CONSTRAINT IF EXISTS daily_attendance_pkey;
    ALTER TABLE daily_attendance
      ADD CONSTRAINT daily_attendance_pkey PRIMARY KEY (user_id, day, group_id);
  END IF;
END $$;
