# Moderation operations

Run only on an authorized operator machine/server using existing DATABASE_URL. Do not expose this CLI or DB credentials to clients. Report content is private; never commit its output.

- Queue: `npx tsx scripts/moderation.ts list` (oldest 100 OPEN).
- Investigate promptly, target within 24 hours. Verify group membership/context and preserve only necessary evidence. Reports are allegations, not proof. Reporter details must not be disclosed to the subject.
- For confirmed profile abuse: clear `avatar_key`, replace abusive `display_name` with a neutral label; remove corresponding avatar file using existing storage procedures. Group-name abuse: replace the group name. Explanation abuse: remove/redact the actual explanation and its revisions. Severe/repeated abuse: set user status LOCKED and revoke active sessions through authorized operational procedures. Do not mark resolved before the action is complete.
- Resolve: `npx tsx scripts/moderation.ts resolve <report UUID> RESOLVED`; unfounded report: `DISMISSED`.
- Review resolved evidence for deletion after 90 days; longer retention requires a documented legal/security need. A retention job and automated alerts are not implemented in this patch; designate an operator for daily queue review before public release.

## Implemented scope and limits

Reports identify a user and shared group; details can identify the offensive profile/avatar, group name or explanation. Reporting does not automatically punish the subject. No unauthenticated operator API exists. Initial report/block requires current shared group; unblock remains available after leaving. Block is mutual profile access denial and redaction in group member/owner profile payloads; it does not remove study attendance records, dissolve groups or change rewards.

Session socket events, report snapshots, previously delivered notifications and direct cached avatar URLs are not yet covered by comprehensive blocked-content redaction. Do not claim complete UGC compliance or complete blocking until these surfaces and content filtering are audited and addressed. No proactive content filtering implemented. This patch alone is insufficient to attest App Store UGC compliance.

Operator takedown commands (apply only after investigation; content removal is destructive):
- `npx tsx scripts/moderation.ts redact-profile <user UUID>` clears visible avatar link/name and stored monthly report name snapshots. Delete original uploaded avatar and cached copies separately.
- `npx tsx scripts/moderation.ts redact-group <group UUID>` replaces group name/purpose with neutral text.
- `npx tsx scripts/moderation.ts redact-explanation <explanation UUID>` replaces text, removes historical revisions; attendance is preserved.

Block enforcement now also masks HTTP session result/owner-detail participant names, suppresses blocked explanation bodies in owner lists/monthly reports, masks blocked appeal content. Numeric attendance and rewards remain intact. Socket and notification limitations above still apply.

Additional delivery enforcement: lobby/state and live engine delivery pass through recipient-specific name/group-name redaction; HTTP inbox and future push/socket delivery also redact current blocked names. Names are masked, operational IDs/accounting are preserved. Previously cached payloads/avatars cannot be withdrawn. Legacy notification text containing an old display name may not match the current name; this is a documented limitation, not proof all historical content is removed. Already-delivered OS notifications cannot be recalled.
