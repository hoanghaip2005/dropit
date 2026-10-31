import type { Generated } from 'kysely';
export interface UserBlocksTable { blocker_id: string; blocked_id: string; created_at: Generated<Date> }
export interface ModerationReportsTable {
  id: Generated<string>; reporter_id: string | null; subject_id: string | null; group_id: string | null;
  reason: 'HARASSMENT' | 'INAPPROPRIATE_CONTENT' | 'SPAM' | 'OTHER'; details: string;
  status: Generated<'OPEN' | 'RESOLVED' | 'DISMISSED'>; created_at: Generated<Date>; resolved_at: Date | null;
}
