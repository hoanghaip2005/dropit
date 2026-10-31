// Operator-only CLI: uses existing server DB privileges; no public admin endpoint.
import { createDb } from '../src/shared/db.js';
import { z } from 'zod';
const db = createDb(process.env.DATABASE_URL ?? '');
try {
  const [action = 'list', reportId, resolution] = process.argv.slice(2);
  if (action === 'list') {
    const rows = await db.selectFrom('moderation_reports').selectAll().where('status', '=', 'OPEN').orderBy('created_at').limit(100).execute();
    process.stdout.write(JSON.stringify(rows, null, 2));
  } else if (action === 'resolve') {
    const id = z.string().uuid().parse(reportId);
    const status = z.enum(['RESOLVED','DISMISSED']).parse(resolution);
    const row = await db.updateTable('moderation_reports').set({status, resolved_at: new Date()}).where('id','=',id).where('status','=','OPEN').returning('id').executeTakeFirst();
    if (!row) throw new Error('Open report not found');
    process.stdout.write(`Report ${row.id}: ${status}\n`);
  } else if (action === 'redact-profile') {
    const id = z.string().uuid().parse(reportId);
    await db.updateTable('users').set({display_name: 'Người dùng', avatar_key: null}).where('id','=',id).execute();
    // Historical display-name snapshots must not re-expose removed content.
    await db.updateTable('monthly_report_rows').set({display_name_snapshot:'Người dùng'}).where('user_id','=',id).execute();
    process.stdout.write('Profile and report snapshots redacted. Purge avatar file/CDN separately.\n');
  } else if (action === 'redact-group') {
    const id = z.string().uuid().parse(reportId);
    await db.updateTable('groups').set({name:'Nhóm học', report_purpose:'Học tập'}).where('id','=',id).execute();
    process.stdout.write('Group text redacted.\n');
  } else if (action === 'redact-explanation') {
    const id = z.string().uuid().parse(reportId);
    await db.transaction().execute(async tx => {
      await tx.deleteFrom('explanation_revisions').where('explanation_id','=',id).execute();
      await tx.updateTable('explanations').set({body:'Nội dung đã được gỡ', edited_at:new Date()}).where('id','=',id).execute();
    });
    process.stdout.write('Explanation and historical content redacted.\n');
  } else throw new Error('Usage: tsx scripts/moderation.ts list | resolve <report UUID> RESOLVED|DISMISSED');
} finally { await db.destroy(); }

