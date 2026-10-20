// Tự kiểm server bằng 3 client giả: K-03 (quay lại <3s), K-02 (rời >3s → EXITED,
// đo độ trễ MEMBER_EXITED), K-04 (lượt 2 → EXITED ngay), K-10 (event trùng),
// khóa màn hình không tính. Chạy: npm run selftest
'use strict';
process.env.PORT = process.env.PORT || '3999';
process.env.LOG_DIR = process.env.LOG_DIR || require('path').join(__dirname, 'logs', 'selftest');
const { server } = require('./server');
const { io } = require('socket.io-client');

const url = `http://127.0.0.1:${process.env.PORT}`;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let n = 0;
const send = (s, ev, extra = {}) =>
  new Promise((r) => s.emit(ev, { eventId: extra.eventId || `e${++n}`, clientTs: Date.now(), ...extra }, r));

function client(name) {
  return new Promise((res) => {
    const s = io(url, { transports: ['websocket'] });
    s.on('connect', async () => {
      await send(s, 'member:join', { name, platform: 'selftest', fresh: true });
      res(s);
    });
  });
}

(async () => {
  const fails = [];
  const check = (cond, msg) => { console.log(cond ? 'PASS' : 'FAIL', msg); if (!cond) fails.push(msg); };
  const a = await client('A');
  const b = await client('B');
  const c = await client('C');
  const exits = [];
  b.on('MEMBER_EXITED', (m) => exits.push({ ...m, recvAt: Date.now() }));

  // Khóa màn hình 4s: không tính
  await send(a, 'member:screen_locked', { trigger: 'test' });
  await sleep(4000);
  let r = await send(a, 'member:screen_unlocked');
  check(r.state === 'FOCUSING', 'Khóa 4s không bị tính rời (BR-15)');

  // K-03
  await send(a, 'member:left_app');
  await sleep(1500);
  r = await send(a, 'member:returned');
  check(r.state === 'FOCUSING', 'K-03 quay lại trong 1,5s → FOCUSING');

  // K-04
  r = await send(a, 'member:left_app');
  check(r.state === 'EXITED', 'K-04 rời lần 2 → EXITED ngay');

  // K-10
  r = await send(c, 'member:left_app', { eventId: 'dup-1' });
  const r2 = await send(c, 'member:left_app', { eventId: 'dup-1' });
  check(r2.dup === true, 'K-10 event trùng bị bỏ qua');

  // K-02: C đang GRACE từ trên → hết 3s → EXITED
  const t0 = Date.now();
  await sleep(3400);
  const ex = exits.find((e) => e.name === 'C');
  check(!!ex && ex.reason === 'grace_expired', 'K-02 rời >3s → EXITED + MEMBER_EXITED');
  if (ex) console.log('  độ trễ server→B (localhost):', ex.recvAt - ex.serverTs, 'ms; từ left_app:', ex.serverTs - t0, 'ms');
  check(exits.filter((e) => e.forfeitedNow).length === 1, 'forfeited đặt đúng 1 lần (BR-35)');

  a.close(); b.close(); c.close();
  server.close();
  console.log(fails.length ? `\n${fails.length} FAIL` : '\nTẤT CẢ PASS');
  process.exit(fails.length ? 1 : 0);
})();
