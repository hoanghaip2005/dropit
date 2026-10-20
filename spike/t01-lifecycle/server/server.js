// Spike T-01 — server đo sự kiện vòng đời (DropIt!).
// Áp BR-11..15 (khoan hồng 3s, 1 lượt/phiên, biên nửa mở BR-65), BR-19/BR-66
// (heartbeat_timeout → DISCONNECTED, + disconnect_hold → LOST), BR-31 (event_id
// idempotent), BR-33 (mọi mốc theo giờ server). Phát MEMBER_EXITED cho mọi client.
// Không nhận/ghi tên app, nội dung, vị trí (BR-34). Đây là spike, không phải backend thật.
'use strict';
const fs = require('fs');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');

const CFG = {
  port: Number(process.env.PORT || 3000),
  graceMs: Number(process.env.GRACE_MS || 3000), // grace_s
  graceMax: Number(process.env.GRACE_MAX || 1), // grace_max_per_session
  hbTimeoutMs: Number(process.env.HB_TIMEOUT_MS || 10000), // heartbeat_timeout_s
  holdMs: Number(process.env.HOLD_MS || 10000), // disconnect_hold_s
  // (đề xuất spike) báo khóa màn hình đến trong lúc GRACE → coi là khóa, hoàn lượt.
  lockReclassify: process.env.LOCK_RECLASSIFY !== '0',
  logDir: process.env.LOG_DIR || path.join(__dirname, 'logs'),
};

fs.mkdirSync(CFG.logDir, { recursive: true });
const logFile = path.join(
  CFG.logDir,
  `t01-${new Date().toISOString().replace(/[:.]/g, '-')}.jsonl`,
);
const out = fs.createWriteStream(logFile, { flags: 'a' });

function log(type, data = {}) {
  const rec = { serverTs: Date.now(), type, ...data };
  out.write(JSON.stringify(rec) + '\n');
  console.log(new Date(rec.serverTs).toISOString().slice(11, 23), type, JSON.stringify(data));
  return rec;
}

// name -> member
const members = new Map();
const seenEventIds = new Set();
let forfeited = false;

function member(name) {
  if (!members.has(name)) {
    members.set(name, {
      name,
      state: 'FOCUSING', // FOCUSING | GRACE | DISCONNECTED | EXITED | LOST | COMPLETED
      locked: false,
      graceUsed: 0,
      graceDeadline: null,
      graceTimer: null,
      lastSeenAt: Date.now(),
      disconnectedAt: null,
      prevState: null,
      socketId: null,
    });
  }
  return members.get(name);
}

const FINAL = new Set(['EXITED', 'LOST', 'COMPLETED']);

function setState(m, state, reason, extra = {}) {
  const from = m.state;
  m.state = state;
  log('STATE', { name: m.name, from, to: state, reason, ...extra });
  io.emit('session:state', { name: m.name, state, reason, serverTs: Date.now() });
}

function exit(m, reason) {
  if (FINAL.has(m.state)) return;
  clearTimeout(m.graceTimer);
  setState(m, 'EXITED', reason);
  const first = !forfeited;
  forfeited = true; // BR-35: đặt đúng một lần
  const msg = { name: m.name, reason, serverTs: Date.now(), forfeitedNow: first };
  log('EMIT_MEMBER_EXITED', msg);
  io.emit('MEMBER_EXITED', msg);
}

function startGrace(m, trigger) {
  if (m.graceUsed >= CFG.graceMax) return exit(m, 'leave_after_grace_used'); // BR-13
  m.graceUsed++;
  m.graceDeadline = Date.now() + CFG.graceMs;
  setState(m, 'GRACE', trigger, { graceDeadline: m.graceDeadline });
  m.graceTimer = setTimeout(() => {
    if (m.state === 'GRACE') exit(m, 'grace_expired'); // BR-14
  }, CFG.graceMs);
}

const handlers = {
  'member:left_app'(m, p) {
    if (m.state === 'FOCUSING' && !m.locked) startGrace(m, p.trigger || p.reason || 'left_app');
    else if (m.state === 'FOCUSING' && m.locked) {
      // Đã báo khóa mà lại báo rời app → mở khóa ngầm rồi rời (BR-15 ca #17).
      m.locked = false;
      startGrace(m, 'left_while_locked_flag');
    }
  },
  'member:returned'(m) {
    if (m.state !== 'GRACE') return;
    if (Date.now() < m.graceDeadline) {
      clearTimeout(m.graceTimer);
      setState(m, 'FOCUSING', 'grace_recovered', { msBeforeDeadline: m.graceDeadline - Date.now() }); // BR-12
    } else exit(m, 'returned_at_or_after_deadline'); // BR-65 biên nửa mở
  },
  'member:screen_locked'(m, p) {
    if (m.state === 'GRACE' && CFG.lockReclassify) {
      clearTimeout(m.graceTimer);
      m.graceUsed--; // hoàn lượt
      m.locked = true;
      setState(m, 'FOCUSING', 'lock_reclassified', { lateBy: p.trigger });
      return;
    }
    if (m.state === 'FOCUSING') {
      m.locked = true;
      log('LOCKED', { name: m.name, trigger: p.trigger }); // BR-15: không đổi trạng thái
    }
  },
  'member:screen_unlocked'(m) {
    m.locked = false;
    m.lastSeenAt = Date.now(); // BR-66
    log('UNLOCKED', { name: m.name });
  },
  heartbeat() {},
  'client:mark'(m, p) {
    log('MARK', { name: m.name, case: p.case });
  },
  'session:end'(m) {
    if (!FINAL.has(m.state)) setState(m, 'COMPLETED', 'session_end');
  },
};

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ ok: true, forfeited, members: [...members.values()].map(({ graceTimer, ...r }) => r) }));
});
const io = new Server(server, { cors: { origin: '*' }, pingInterval: 25000, pingTimeout: 20000 });

io.on('connection', (socket) => {
  let m = null;
  log('SOCKET_CONNECT', { sid: socket.id, addr: socket.handshake.address });

  socket.on('clock:ping', (p, ack) => typeof ack === 'function' && ack({ serverTs: Date.now(), t0: p && p.t0 }));

  socket.on('member:join', (p, ack) => {
    const name = String((p && p.name) || 'unknown').slice(0, 32);
    m = member(name);
    m.socketId = socket.id;
    m.lastSeenAt = Date.now();
    if (m.state === 'DISCONNECTED') {
      // BR-20: nối lại trong hạn (BR-19 mục 4, nửa mở)
      if (Date.now() < m.disconnectedAt + CFG.holdMs) setState(m, m.prevState || 'FOCUSING', 'reconnected');
    } else if (FINAL.has(m.state) && p && p.fresh) {
      members.delete(name);
      m = member(name);
      m.socketId = socket.id;
    }
    log('JOIN', { name, platform: p && p.platform, state: m.state, lagMs: Date.now() - (p && p.clientTs) });
    if (typeof ack === 'function') ack({ serverTs: Date.now(), state: m.state });
  });

  for (const ev of Object.keys(handlers)) {
    socket.on(ev, (p = {}, ack) => {
      const now = Date.now();
      if (!m) return typeof ack === 'function' && ack({ serverTs: now, error: 'not_joined' });
      m.lastSeenAt = now; // BR-19 (2)
      const dup = p.eventId && seenEventIds.has(p.eventId);
      if (!dup && p.eventId) seenEventIds.add(p.eventId);
      // lagMs = serverTs - clientTs (gồm lệch giờ; hiệu chỉnh bằng clock_sync trong log client)
      if (ev !== 'heartbeat' || process.env.LOG_HB === '1') {
        log('RECV', { name: m.name, ev, eventId: p.eventId, lagMs: p.clientTs ? now - p.clientTs : null, dup, locked: m.locked, trigger: p.trigger });
      } else {
        log('HB', { name: m.name, lagMs: p.clientTs ? now - p.clientTs : null, locked: p.locked });
      }
      if (!dup && !FINAL.has(m.state)) handlers[ev](m, p); // BR-31
      if (typeof ack === 'function') ack({ serverTs: Date.now(), state: m.state, dup });
    });
  }

  socket.on('disconnect', (reason) => {
    log('SOCKET_DISCONNECT', { sid: socket.id, name: m && m.name, reason, locked: m && m.locked });
    if (!m || m.socketId !== socket.id) return;
    // BR-66: đã báo khóa → không coi socket đóng là DISCONNECTED. GRACE vẫn chạy (§5, Q-30).
    if (m.state === 'FOCUSING' && !m.locked) toDisconnected(m, 'socket_closed');
  });
});

function toDisconnected(m, reason) {
  m.prevState = m.state;
  m.disconnectedAt = Date.now();
  setState(m, 'DISCONNECTED', reason, { lastSeenAt: m.lastSeenAt });
}

// Bộ quét 250 ms: heartbeat_timeout (BR-66) và LOST (BR-19 mục 4).
setInterval(() => {
  const now = Date.now();
  for (const m of members.values()) {
    if (m.state === 'FOCUSING' && !m.locked && now >= m.lastSeenAt + CFG.hbTimeoutMs) {
      toDisconnected(m, 'heartbeat_timeout');
      m.disconnectedAt = Math.min(now, m.lastSeenAt + CFG.hbTimeoutMs);
    }
    if (m.state === 'DISCONNECTED' && now >= m.disconnectedAt + CFG.holdMs) {
      setState(m, 'LOST', 'disconnect_hold_expired'); // không MEMBER_EXITED (D-19)
    }
  }
}, 250);

server.listen(CFG.port, '0.0.0.0', () => {
  log('SERVER_START', { ...CFG, logFile });
});

module.exports = { server, io, CFG };
