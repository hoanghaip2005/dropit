// Demo: 3 client socket vào một phiên; An rời app quá 3s khoan hồng → cả phiên mất thưởng (D-05).
// Chạy: npm run demo (cần `npm run db:up`). Dựng server trong tiến trình với thời gian rút ngắn.
import { startServer, emit, sleep, waitFor } from '../test/integration/helpers.js';

const GRACE_MS = Number(process.env.DEMO_GRACE_MS ?? 3000);
const t = await startServer({ graceMs: GRACE_MS, countdownMs: 1000, minuteMs: 200 }); // phiên 25' ≈ 5s
const log = (...a: unknown[]) => console.log(`[${new Date().toISOString().slice(11, 23)}]`, ...a);

try {
  const { owner, members, groupId } = await t.groupWith(3, 'Lan');
  log(`Nhóm ${groupId}: chủ nhóm Lan + ${members.map((m) => m.name).join(', ')}`);
  const sid = await t.schedule(owner.token, groupId);
  log(`Lịch một lần 25 phút → phiên ${sid}`);
  await waitFor(() => t.srv.ctx.sessions.runtimes.has(sid), 15000);

  const ownerSock = await t.sock(owner.token);
  const socks = await Promise.all(members.map((m) => t.sock(m.token)));
  for (const [i, s] of socks.entries()) log(`${members[i].name} session:join →`, await emit(s, 'session:join', { session_id: sid }));
  const beat = setInterval(() => socks.forEach((s) => s.connected && s.emit('heartbeat', { session_id: sid })), 1000);

  await waitFor(async () => (await t.db.selectFrom('sessions').select('status').where('id', '=', sid).executeTakeFirstOrThrow()).status === 'ACTIVE', 15000);
  log('Phiên ACTIVE (sau đếm ngược)');
  log('An rời app →', await emit(socks[0], 'member:left_app', { session_id: sid }));
  await sleep(GRACE_MS + 500);
  log(`An quay lại sau ${GRACE_MS + 500}ms →`, await emit(socks[0], 'member:returned', { session_id: sid }));
  const ev = await waitFor(() => ownerSock.events.find((e) => e.type === 'MEMBER_EXITED'));
  log('Chủ nhóm nhận MEMBER_EXITED:', JSON.stringify(ev.payload));

  await waitFor(async () => {
    const s = await t.db.selectFrom('sessions').select('status').where('id', '=', sid).executeTakeFirstOrThrow();
    return s.status === 'COMPLETED' && !t.srv.ctx.sessions.runtimes.has(sid);
  }, 30000);
  clearInterval(beat);

  const s = await t.db.selectFrom('sessions').select(['status', 'forfeited']).where('id', '=', sid).executeTakeFirstOrThrow();
  const rows = await t.db.selectFrom('session_members as sm').innerJoin('users as u', 'u.id', 'sm.user_id')
    .select(['u.display_name', 'sm.state', 'sm.end_reason', 'sm.coins_awarded']).where('sm.session_id', '=', sid).execute();
  console.log('\n=== KẾT QUẢ PHIÊN ===');
  console.log(`status=${s.status} forfeited=${s.forfeited}`);
  console.table(rows);
  for (const m of members) {
    const r = await t.api('GET', `/v1/sessions/${sid}/result`, m.token);
    console.log(`${m.name}: final_state=${r.body.final_state} coins=${r.body.coins_awarded} forfeited=${r.body.forfeited} streak_broken=${r.body.streak_broken}`);
  }
  for (const x of [...socks, ownerSock]) x.close();
} finally {
  await t.close();
}
