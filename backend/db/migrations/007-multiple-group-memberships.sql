-- D-30: users may be active members of multiple groups; prevent duplicate active rows per group.
DROP INDEX IF EXISTS group_members_one_active_uq;
CREATE UNIQUE INDEX IF NOT EXISTS group_members_one_active_per_group_uq
  ON group_members(user_id, group_id)
  WHERE left_at IS NULL;
