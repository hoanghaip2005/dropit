ALTER TABLE device_tokens ADD COLUMN IF NOT EXISTS device_id uuid;
CREATE UNIQUE INDEX IF NOT EXISTS device_tokens_device_idx ON device_tokens(device_id) WHERE device_id IS NOT NULL;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS push_payload jsonb;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS push_next_at timestamptz;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS push_lease_until timestamptz;
CREATE INDEX IF NOT EXISTS notifications_push_pending_idx ON notifications(push_next_at) WHERE push_status = 'PENDING';
