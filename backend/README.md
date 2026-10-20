# DropIt! — Backend chạy local (không AWS)

Node 20+ · TypeScript · Fastify 5 · Socket.io 4 · Kysely + pg · zod · vitest. Một tiến trình gồm HTTP, socket `/session` và cron (mở phiên, báo cáo tháng) (ADR-01).

## Chạy

```bash
npm install
npm run db:up        # postgres:16 ở 127.0.0.1:55433 (container dropit-backend-pg), áp ../design/schema.sql + db/seed.sql + db/seed-demo.sql
npm run dev          # http://localhost:3000 , GET /health
npm test             # unit + integration (cần db:up)
npm run demo         # 3 client socket, An rời app > 3s → cả phiên mất thưởng
npm run db:reset     # xóa volume, tạo lại DB + seed
npm run db:seed      # áp db/seed-demo.sql (idempotent) vào DB đang chạy, không cần reset
```

Biến môi trường: xem `.env.example` (mặc định đã đúng cho local; tiến trình **không** tự đọc `.env` — đặt biến trong shell nếu muốn đổi). `NODE_ENV` mặc định `development`.
`SESSION_MINUTE_MS`, `SCHEDULE_MIN_LEAD_MS` chỉ có hiệu lực khi `NODE_ENV=test`.
Thêm ở đợt này: `JOURNAL_MASTER_KEY` (khóa chủ nhật ký), `UPLOADS_DIR` (mặc định `backend/uploads`), `OUTBOX_DIR` (mặc định `backend/outbox`), `PUBLIC_BASE_URL` (mặc định `http://localhost:<PORT>`), `MONTHLY_REPORT_CRON=0` để tắt chạy bù báo cáo.

### Đăng nhập dev

`POST /dev/token {"email":"lan@dropit.dev"}` → `access_token` (JWT HS256, chỉ khi `NODE_ENV=development`). Gửi `Authorization: Bearer <token>`; socket: `io('/session', { auth: { token, v: 1, device_id } , transports:['websocket'] })`.
Bộ xác thực là interface `TokenVerifier` (`src/shared/auth.ts`) — thay bằng verifier Cognito (JWKS) sau mà không đổi route.

Seed: chủ nhóm `lan@dropit.dev` có 2 nhóm (`Nhóm Học Toán` mã `TAPTRUN7` với 5 thành viên an/binh/chi/dung/em@dropit.dev; `Nhóm Đọc Sách` mã `GHEPNHA5` trống), thêm giang/hoa@dropit.dev chưa vào nhóm.

Seed demo (`db/seed-demo.sql`, tự áp khi tạo container mới; DB đang có: `npm run db:seed`):
- Shop: khung/hình nền mặc định (ẩn, không bán) + 3 khung, 3 hình nền, 2 danh hiệu đang bán, 1 món đã ẩn.
- Nhóm Học Toán: 3 phiên tháng trước (phiên giữa: Dũng rời → mất thưởng tập thể) + 6 phiên ở 6 ngày gần nhất đều hoàn thành có thưởng; hôm nay ~3 giờ trước khi seed: một phiên Dũng rời (còn hạn giải trình/khiếu nại — đăng nhập `dung@dropit.dev`), An vắng.
- An: 50 Coins (80 thưởng − 30 mua "Khung Lá Xanh", đang trang bị), chuỗi 7/7, huy hiệu STREAK_3 + STREAK_7 (STREAK_7 đang trưng bày), điểm danh, hộp thông báo.
- Báo cáo tháng trước của Nhóm Học Toán đã tạo (`POST /dev/jobs/monthly-report {}` chạy lại được, idempotent) → `GET /v1/groups/00000000-0000-4000-9000-000000000001/reports/<YYYY-MM>` bằng token Lan; email tóm tắt ở `outbox/`.

## Cấu trúc

```
src/
  server.ts, app.ts, config.ts, context.ts
  shared/      auth (JWT/verifier), db (Kysely types), http (lỗi, parse zod, currentUser, idempotency), cursor, time, sort
  modules/
    auth/          /v1/time, /dev/token, /v1/me (GET/PATCH)
    groups/        nhóm, mã mời, đồng ý, thành viên
    schedules/     lịch một lần + lịch lặp (BR-113), chống chồng (BR-78)
    sessions/      engine.ts (máy trạng thái thuần, test unit), manager.ts (runtime + DB + kết thúc trong transaction),
                   socket.ts (namespace /session), routes.ts (kết quả, lịch sử, owner-detail), summary.ts
    rewards/       Coins (D-09, trần 100/ngày), /v1/me/coins, finalizeSession
    notifications/ hộp thông báo + NotificationSender (push thật = log console)
    appeals/       giải trình (BR-85) + khiếu nại, máy trạng thái, miễn trừ & khôi phục hồi tố (BR-86…88)
    achievements/  huy hiệu theo mốc, phát lại chuỗi (replayStreak), /me/achievements, /me/attendance
    shop/          danh mục, mua (giao dịch + idempotency), đồ của tôi, trang bị
    profile/       avatar lưu local uploads/ (thay S3), ảnh xem trước Shop (SVG giữ chỗ)
    journal/       nhật ký mã hóa AES-256-GCM phong bì (crypto.ts), chỉ chủ sở hữu đọc
    reports/       báo cáo tháng (bản chụp), email tóm tắt → outbox/, job + /dev/jobs/monthly-report
    jobs/cron.ts   mở phiên theo chu kỳ + chạy bù báo cáo tháng sau 02:00 giờ VN
test/unit/*.test.ts, test/integration/*.test.ts (sim.ts: dựng phiên quá khứ rồi chốt bằng finalizeSession thật)
scripts/demo-session.ts, scripts/db-reset.mjs, scripts/db-seed.mjs, db/seed.sql, db/seed-demo.sql
```

## Endpoint so với `design/openapi.yaml` (tiền tố `/v1`)

In đậm = mới ở đợt này.

| Đã có | Chưa có (ngoài phạm vi đợt này) |
| --- | --- |
| `GET /time`, `GET/PATCH /me`, `GET /me/groups`, **`PUT /me/avatar`** (trả URL tải lên của chính server thay S3) | `DELETE /me`, `/me/logout-check`, `/me/data`, `/me/data/export`, `/me/access-log`, `/me/devices` |
| `POST /groups`, `GET /groups/{id}`, `GET/POST /groups/{id}/invite-code`, `GET /invites/{code}`, `POST /groups/{id}/consent`, `GET /groups/{id}/members` | `/groups/{id}/email-invites`, `/groups/{id}/members/{user_id}`, `/groups/{id}/abuse-reports` |
| `POST/GET /groups/{id}/schedules` — một lần **và lặp lại (`recurrence`)** | `/groups/{id}/members/{user_id}/attendance` (chủ nhóm xem điểm danh thành viên, Should) |
| `GET /sessions/{id}`, `GET /me/sessions/upcoming`, `GET /sessions/{id}/result`, `GET /sessions/{id}/owner-detail`, **`GET /me/sessions`** | `/users/{user_id}/public-profile` |
| `GET /me/notifications`, `POST /me/notifications/read` (ids / up_to / tất cả) | `/groups/{id}/reports/{month}/pdf` (PDF, Should) |
| **`PUT /sessions/{id}/explanation`**, **`GET /sessions/{id}/explanations`** | `/admin/*` (quản trị; ca khiếu nại ESCALATED chưa có người xử lý) |
| **`POST /sessions/{id}/appeals`**, **`POST /appeals/{id}/decision`** (EXEMPT / REJECT / ESCALATE) | |
| **`GET /me/achievements`**, **`GET /me/attendance?month=`**, **`GET /me/achievements/history`**, **`PUT /me/badges/{code}/display`** | |
| `GET /me/coins`, **`GET /shop/items`**, **`POST /shop/purchases`**, **`GET /me/inventory`**, **`PUT /me/equipment`** | |
| **`GET /me/journal`**, **`PUT /me/journal/{date}`**, **`DELETE /me/journal/{date}`** | |
| **`GET /groups/{id}/reports`**, **`GET /groups/{id}/reports/{month}`**, **`GET /groups/{id}/reports/{month}/members/{user_id}`** | |
| Ngoài openapi: `GET /health`, `POST /dev/token`, **`POST /dev/jobs/monthly-report`** (dev, `{month?, group_id?}`), **`GET /me/sessions/{id}`** (bí danh `/result`), **`GET /appeals/{id}`** (mở ca), **`PUT /me/avatar/content`**, **`DELETE /me/avatar`**, **`GET /uploads/avatars/{file}`** (thay S3), **`GET /me/journal/{date}`**, **`GET /assets/shop/{key}`** (ảnh xem trước giữ chỗ), **`GET /users/{id}/journal[/{date}]`**, **`GET /groups/{gid}/members/{uid}/journal`** (luôn 403 — US-07.10) | |

Socket `/session` (03-api-socket §3): `session:join`, `session:resume`, `member:left_app`, `member:returned`, `member:screen_locked`, `member:screen_unlocked`, `session:leave`, `heartbeat`, `clock:ping`. `member:pause/resume/withdraw` (Should) trả `NOT_SUPPORTED`. Server phát `member:state`, `MEMBER_EXITED`, `SESSION_RESULT` (nay có `new_badges`)… theo tên trong 03-api-socket. `EXEMPTION_GRANTED`, `APPEAL_DECIDED` phát qua room `user:{id}` hoặc push (console).

## Đã kiểm chứng (2026-10-19)

- `tsc --noEmit` sạch; `npm test`: 7 tệp, **75 ca** qua — unit: 20 engine + 16 tính năng (phát lại chuỗi, mã hóa nhật ký, chỉ số báo cáo, sinh lịch lặp, nhận diện ảnh); integration: 14 nhóm, 5 phiên end-to-end, 7 lịch sử/thông báo/giải trình/khiếu nại, 6 Shop/thành tích, 7 nhật ký/hồ sơ/báo cáo/lịch lặp.
- Trọng tâm test: Coins mua (thiếu/đủ, idempotency, đã sở hữu, đổi giá, đua đồng thời) và bù miễn trừ (APPEAL_RESTORE theo trần ngày phiên, không ghi hai lần); quyền 403 (thành viên → `NOT_GROUP_OWNER`, chủ nhóm khác/người ngoài → `FORBIDDEN_GROUP`); nhật ký mã hóa (DB không có bản rõ, sai khóa/sửa bản mã/sai AAD không giải được, chủ nhóm 403); phản hồi cho chủ nhóm không có khóa coin/streak/balance.
- `npm run dev` + seed demo: `/v1/me`, `/v1/me/sessions`, `/v1/me/achievements`, `/v1/me/inventory`, `/v1/shop/items`, `/dev/jobs/monthly-report` trả đúng dữ liệu seed.
- Email/ảnh của test ghi vào thư mục tạm của hệ điều hành, không vào `outbox/`, `uploads/`.

## Giả định (theo phương án đề xuất của câu hỏi mở)

- Thời gian (khoan hồng 3s, đếm ngược 5s, heartbeat 10s, giữ chỗ 10s, mở phòng chờ 10 phút) lấy từ env, mặc định theo system_params.
- Ngày thưởng/chuỗi theo giờ Việt Nam (UTC+7) (giả định).
- Khóa màn hình không phạt; cờ đổi phân loại khi khóa trong GRACE (Q-151/DQ-F07) mặc định TẮT.
- LOST không forfeited và không gửi MEMBER_EXITED (D-19). `session:leave` ở WAITING → ABSENT, ở FOCUSING/GRACE → EXITED + forfeited (D-29/BR-118).
- Nối lại chỉ cùng `device_id` (DQ-A07); thiết bị khác nhận `SESSION_ALREADY_JOINED_ELSEWHERE`.
- Không ai vào phòng chờ → phiên CANCELLED `NO_ATTENDEE` (BR-30).
- Push thật chưa có: `ConsoleNotificationSender` log ra console; thông báo vẫn lưu vào hộp thông báo và phát qua room `user:{id}` khi đang mở app.
- Runtime phiên giữ trong bộ nhớ một tiến trình; khởi động lại gọi `recoverOnBoot()` (không phân tán nhiều instance).
- Lịch sử phiên (US-03.14): mọi phiên đã chốt (COMPLETED/CANCELLED) mà tôi có trạng thái, kể cả ABSENT; mỗi mục là `MySessionResult` (có Coins/chuỗi của chính tôi). `can_explain`/`can_appeal` tính theo hạn BR-85/BR-86.
- Giải trình: gửi đến `ends_at` + 7 ngày, sửa trong 24 giờ từ lần gửi đầu (BR-85); chủ nhóm nhận thông báo trong app, không push. `If-Match` (tùy chọn) so với `version` = `updated_at` (ms).
- Khiếu nại: chỉ tạo khi phiên đã COMPLETED (giả định) và trước `ends_at` + 24 giờ (BR-86); `suspect_system_error` → ESCALATED ngay. Quá 72 giờ chưa quyết → ESCALATED (kiểm tra lười khi đọc/quyết, chưa có job). Chủ nhóm quyết thẳng từ CHỜ XỬ LÝ thì đi qua ĐANG XỬ LÝ trong cùng giao dịch.
- Miễn trừ (BR-87/88): người được miễn trừ được điểm danh (Q-124). Không còn EXITED chưa miễn trừ → gỡ `forfeited`, bù `SESSION_REWARD` `reason = APPEAL_RESTORE` cho người COMPLETED + EXITED đã miễn trừ, theo trần **của ngày phiên**; ghi `STREAK_RESTORE` và tính lại chuỗi bằng phát lại nhật ký (bỏ lần ngắt của phiên đó, +1 ảo nếu ngày đó chưa có +1; `longest_streak` chỉ tăng); xét lại huy hiệu. LOST trong phiên được gỡ: chỉ gỡ lần ngắt, không +1. Còn EXITED khác → giữ forfeited, người khởi phát = EXITED chưa miễn trừ sớm nhất (Q-92). `EXEMPTION_GRANTED`: bản cho người được miễn (`coins_refunded`) + bản đính chính **không Coins** cho đúng những người đã nhận `MEMBER_EXITED` của sự kiện đó (Q-138). Bác → `APPEAL_DECIDED` cho người khiếu nại.
- Huy hiệu: cấp khi chốt phiên và khi khôi phục; số đo: chuỗi = `longest_streak`, số phiên hoàn thành có thưởng (D-11), giờ tập trung (BR-89, chỉ COMPLETED, kể cả forfeited). Thông báo `BADGE_EARNED` chỉ trong app (Q-95). Chưa có job 00:05 xét hồi tố khi đổi mốc (BR-90). Trưng bày tối đa 3 (BR-99).
- Shop: giá cố định, không ngẫu nhiên (BR-121); gỡ món → món mặc định (BR-95); `/me/inventory` gồm cả món mặc định (`is_default: true`, trường ngoài openapi). Số dư kiểm ở ứng dụng và trigger sổ cái (đua đồng thời → 422).
- Nhật ký: mục mới chỉ cho hôm nay theo giờ server VN; mục đã có sửa được không giới hạn, không lưu phiên bản; xóa thẳng (BR-100, Q-107/108). Mã hóa phong bì: DEK ngẫu nhiên/mục, AES-256-GCM, DEK bọc bằng khóa chủ `JOURNAL_MASTER_KEY` (base64 32 byte, hoặc chuỗi bất kỳ → SHA-256), `kms_key_id = local-env:v1`, AAD = (user, ngày). Bản AWS thay khóa chủ bằng KMS GenerateDataKey.
- Báo cáo tháng: chỉ số theo §Báo cáo §2–3; thành viên tính từ `joined_at` đến `left_at` (BR-59); phiên không có dòng của người đang là thành viên = vắng; tổng phút gồm phần trước EXITED/LOST. Nhóm tạo sau kỳ bị bỏ qua. Tổng nhóm cho thành viên khi ≥ 5 thành viên lúc tạo (BR-104). Email tóm tắt ghi `outbox/report-<YYYY-MM>-<group>.eml` + log console, không gửi thật, không ảnh/link theo dõi (D-27), link mở app dạng `dropit://`. Cron (tắt ở test) chạy bù kỳ trước sau 02:00 nếu `job_runs` chưa SUCCEEDED, tối đa 4 lượt (BR-101).
- Lịch lặp: giờ trong ngày + ngày bắt đầu lấy từ `start_time` (giờ VN), sinh mọi ngày khớp `weekdays` đến `end_date` (≤ 12 tuần); một lần trùng → 409 cả chuỗi kèm danh sách ngày (Q-78).
- Avatar: lưu `uploads/avatars/<user>-<ts>.<ext>`, kiểm tra byte đầu tệp, ≤ 5 MB, xóa tệp cũ khi thay; **chưa** cắt vuông/thu nhỏ/xóa EXIF (cần thư viện ảnh) và tệp phục vụ công khai không ký hạn (chỉ dev).

## Phát hiện khi code

- `openapi.yaml` khai báo server `.../v1`, nên mọi route nghiệp vụ có tiền tố `/v1`; `/health` và `/dev/token` nằm ngoài tiền tố.
- Lịch đặt bằng giây: server cắt mili-giây của `start_time`, client nên gửi thời điểm tròn giây.
- Nhóm thứ hai trong seed không có thành viên — muốn demo nhóm này phải tham gia bằng mã `GHEPNHA5`.
- Kiểu dữ liệu `loadConfig` trước đây không cho ghi đè một phần `engine` (lỗi `tsc` ở test, vitest vẫn chạy vì không kiểm kiểu) — đã sửa.
- `GET /health` thiếu so với yêu cầu tích hợp app — đã thêm (kiểm tra cả kết nối DB).
- Chủ nhóm cần `appeal_id` để quyết định nhưng openapi không có endpoint liệt kê/mở ca cho chủ nhóm, và `SessionMemberOwnerRow` (additionalProperties: false) chỉ có `appeal_status` → thêm `GET /appeals/{id}` (mở ca → ĐANG XỬ LÝ, ghi access_logs) và đưa `appeal_id` vào `data` của thông báo cho chủ nhóm.
- enum `Notification.type` thiếu loại cho "chủ nhóm nhận giải trình" (BR-85) và "có khiếu nại mới" (máy trạng thái khiếu nại) → dùng `EXPLANATION_SUBMITTED`, `APPEAL_CREATED` (ngoài enum).
- `Explanation.version` và "lưu lịch sử bản cũ" (BR-85): bảng `explanations` không có cột version/bảng lịch sử → version = `updated_at` (ms), chưa lưu bản cũ.
- `ReportRowOwnerView.explanations[]` (additionalProperties: false) không có chỗ cho nhãn "thêm sau khi tạo báo cáo" (BR-102) dù cột `explanations.added_after_report` có → báo cáo chưa trả nhãn (vẫn có ở `GET /sessions/{id}/explanations`).
- `/me/achievements/history` chỉ có `STREAK_UP | STREAK_BROKEN | BADGE_EARNED`: `STREAK_RESTORE` (BR-88) đang ánh xạ thành `STREAK_UP`.
- `ErrorCode` không có mã cho "nhật ký là riêng tư" (BR-100 yêu cầu 403) → dùng `FORBIDDEN_GROUP` kèm `br: BR-100`; chủ nhóm quyết ca đã chuyển quản trị → 403 `NOT_GROUP_OWNER` kèm `br: BR-110`. Giải trình quá 500 ký tự → 422 `VALIDATION_FAILED` (`br: BR-85`).
- `MEMBER_EXITED` trong hộp thông báo trước đây không lưu `user_id` người thoát nên không xác định chính xác người nhận bản đính chính khi trùng tên → nay lưu `exited_user_id` trong `data` (bản ghi cũ dò theo tên).
- `ledger_type` không có loại riêng cho bù miễn trừ: theo BR-88/openapi dùng `SESSION_REWARD` + `reason = APPEAL_RESTORE`, chung khóa idempotency với thưởng thường nên không thể ghi hai lần.
- `server_ts`/con trỏ trả ở độ chính xác ms còn Postgres lưu µs: `up_to = server_ts` trước đây bỏ sót chính thông báo đó; sửa giải trình theo `updated_at` không khớp → so sánh `date_trunc('milliseconds', …)`. Con trỏ phân trang `created_at|id` vẫn có thể lệch hiếm khi nhiều dòng cùng 1 ms.
- `finalizeSession` xét huy hiệu khi phiên còn ACTIVE trong giao dịch → số đo huy hiệu tính cả phiên ACTIVE có trạng thái cuối.
- Báo cáo chỉ tính phiên từ `group_members.joined_at` (BR-59): seed cũ có `joined_at`/`groups.created_at = now()` nên phiên quá khứ không vào báo cáo → seed-demo lùi hai cột này 2 tháng.
- `roleIn` trả 404 cho nhóm ĐÃ GIẢI TÁN → người từng là chủ nhóm chưa xem được báo cáo cuối (BR-62, BR-103) — chưa xử lý.
