-- The single final decision already retains handler, reason and timestamp.
-- Retain its effect in the same transaction; never expose other users' coins.
ALTER TABLE appeals ADD COLUMN IF NOT EXISTS decision_effect jsonb;
