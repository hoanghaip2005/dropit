-- BR-02: new and updated schedules/sessions may use only the fixed 25/50-minute durations.
-- Existing incompatible rows must be resolved explicitly; this migration does not rewrite them.
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_duration_min_range;
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_duration_min_allowed_check;
ALTER TABLE sessions
  ADD CONSTRAINT sessions_duration_min_allowed_check
  CHECK (duration_min IN (25, 50));

ALTER TABLE schedules DROP CONSTRAINT IF EXISTS schedules_duration_min_range;
ALTER TABLE schedules DROP CONSTRAINT IF EXISTS schedules_duration_min_allowed_check;
ALTER TABLE schedules
  ADD CONSTRAINT schedules_duration_min_allowed_check
  CHECK (duration_min IN (25, 50));

UPDATE system_params SET value = '[25,50]'::jsonb WHERE key = 'duration_min';
