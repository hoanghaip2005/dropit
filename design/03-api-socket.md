# Thiết kế 03 — Hợp đồng API REST và Socket.io

Giai đoạn 3 – Thiết kế · Ngày tạo: 2026-10-19 · Trạng thái: Nháp.
Hợp đồng REST đầy đủ (máy đọc được): `design/openapi.yaml` (OpenAPI 3.1; lint lại bằng `@redocly/cli@1.34.5` sau khi khớp schema 2026-10-19: hợp lệ, 0 lỗi, 0 cảnh báo).
Nguồn: `ba/srs/02-ep0*.md` (US/AC), `03-quy-tac.md` (BR), `04-nfr-rieng-tu.md` (ma trận ai thấy gì, NFR-11), `05-tham-chieu-ky-thuat.md` §2–§3 (tham khảo), `ba/views/00-danh-muc-man.md` (V-xx), `spike/t01-lifecycle/server/server.js`.
Tên bảng/cột và giá trị enum theo `design/schema.sql` + `02-du-lieu.md` (nguồn thắng); đã khớp lại 2026-10-19 (DQ-A02 đã giải). Tệp này là nguồn thắng về **tên sự kiện socket**.

---

## 1. Nguyên tắc API

| # | Nguyên tắc | Chi tiết | Nguồn |
| --- | --- | --- | --- |
| P1 | Phiên bản | Tiền tố đường dẫn `/v1`. Thay đổi phá vỡ thì sang `/v2`; thêm trường tùy chọn không đổi phiên bản. Client gửi `X-App-Version`; server trả 426 nếu bản app quá cũ **(đề xuất, DQ-A03)**. Socket: tham số handshake `v=1`. | — |
| P2 | Xác thực | `Authorization: Bearer <access token Cognito>`. Server kiểm chữ ký JWKS, `exp`, `token_use=access`, `client_id`. Không có vai trò chủ nhóm trong token: vai trò tính theo **từng nhóm** ở server (D-10). Admin = nhóm Cognito `admin`. | NFR-10, D-10 |
| P3 | Phân quyền | Mọi yêu cầu kiểm tra (người gọi, nhóm, phiên) ở server. Người không thuộc nhóm gọi tài nguyên của nhóm → **403 `FORBIDDEN_GROUP`**. Thành viên gọi API của chủ nhóm → 403 `NOT_GROUP_OWNER`. Tài nguyên cá nhân luôn đi qua `/me/...` (không nhận `user_id` của người khác), nên không thể đọc chéo. | NFR-11, 04 §3 |
| P4 | Không lộ Coins/chuỗi cho chủ nhóm | Schema `*OwnerView`, `PublicUser`, `ReportRow*`, `SessionMemberOwnerRow` **không có** `coins_*`, `current_streak`, `longest_streak`; `additionalProperties: false` để kiểm thử hợp đồng phát hiện rò. Coins/chuỗi chỉ có trong `MeProfile`, `MySessionResult`, `MyAchievements`, `/me/coins`. | BR-53, BR-61, D-12 |
| P5 | Giờ server | Mọi mốc thời gian là ISO-8601 UTC do server cấp (`server_ts`, `started_at`, `ends_at`, hạn khoan hồng…). Client chỉ dùng giờ máy để **hiển thị**, hiệu chỉnh độ lệch bằng `GET /v1/time` hoặc `clock:ping` trên socket. Mọi quyết định trạng thái theo thời điểm server nhận. | BR-03, BR-33 |
| P6 | Idempotency | Mọi POST/DELETE gây tác dụng phụ (đồng ý, tạo nhóm, đổi mã mời, đặt lịch, mua, khiếu nại, quyết định, xóa…) bắt buộc header `Idempotency-Key` (UUID v4). PUT/PATCH idempotent tự nhiên hoặc dùng `If-Match` (P7). Server lưu (user, key) → phản hồi trong 24 giờ ở bảng `idempotency_keys`; trùng khóa + cùng thân → trả lại phản hồi cũ; khác thân → 422 `IDEMPOTENCY_MISMATCH`. Mua hàng còn được bảo vệ thêm bởi khóa duy nhất sổ cái (BR-45). | BR-31, BR-45 |
| P7 | Đồng thời | Tài nguyên sửa được (nhóm, phiên, giải trình) trả `ETag`; PATCH/PUT gửi `If-Match`; lệch → 409 `VERSION_CONFLICT`. | — |
| P8 | Phân trang | Con trỏ mờ: `?cursor=&limit=` (mặc định 20, tối đa 100), phản hồi `{ items, next_cursor }`. Không trả tổng số (tránh đếm tốn kém). Danh sách thời gian (thông báo, Coins, lịch sử phiên, nhật ký) sắp **mới nhất trước**. | — |
| P9 | Sắp xếp người (BR-115) | Mọi danh sách **người** trong nhóm (thành viên, người trong phiên, kết quả phiên, dòng báo cáo, chi tiết phiên chủ nhóm) sắp **phía server**: `display_name` tăng dần, không phân biệt hoa/thường, theo collation tiếng Việt (ICU `vi-VN`), trùng thì `joined_at` sớm trước, rồi `user_id`. Ngoại lệ 1: danh sách thành viên trả `owner` tách riêng (client hiện đầu). Ngoại lệ 2: danh sách **sự kiện** (exit_events, banner, hộp thông báo) theo thời gian. Không có tham số `sort` nào cho phép sắp theo chỉ số (không xếp hạng ngầm, D-03). | BR-115, D-03 |
| P10 | Lỗi | `application/problem+json` (RFC 9457) + `code` nghiệp vụ ổn định (enum `ErrorCode`), `detail` tiếng Việt hiển thị được, `br` để truy vết. Bảng ở §1.1. | — |
| P11 | Giới hạn tần suất | Theo người dùng: 60 yêu cầu/phút chung, 10/phút cho ghi **(đề xuất, DQ-A04)**; nhập mã mời theo BR-76 (5 lần sai/15 phút → khóa 15 phút). Trả 429 + `Retry-After`. | BR-76 |
| P12 | Nhật ký truy cập | Mỗi lần chủ nhóm/admin đọc dữ liệu về một thành viên (báo cáo, dòng báo cáo, chi tiết phiên, giải trình, điểm danh, PDF) → ghi/gộp một dòng `access_logs` (PostgreSQL, DQ-D04). Đây là nguồn cho `/me/access-log` (Should). | BR-73, NFR-P07 |
| P14 | Enum dùng chung | Giá trị enum trong API = giá trị enum CSDL: `SessionStatus` = `session_status`; `MemberFinalState` ⊂ `member_state`; `GroupStatus` = `group_status` (ACTIVE/SCHEDULE_SUSPENDED/DISSOLVING/DISSOLVED); `AppealStatus` = `appeal_status` (PENDING/IN_REVIEW/ESCALATED/EXEMPTED/REJECTED); `ItemKind` = `item_kind` (AVATAR_FRAME/BACKGROUND/TITLE); `ItemStatus` = `item_status` (ON_SALE/HIDDEN); `SessionCancelReason` = `session_cancel_reason`; `CoinEntry.type` = `ledger_type`; `ReportPeriod.status` = `report_status`. `duration_min` ∈ {25, 50} (BR-02); `member_count` 0–10, không gồm chủ nhóm (BR-74). | BR-02, BR-74 |
| P13 | Riêng tư | Không endpoint nào nhận/trả tên app khác, nội dung máy, vị trí. Nhật ký cá nhân chỉ có `/me/journal*`; không có đường nào cho chủ nhóm/admin (US-07.10). | GĐ1 §6, BR-34, BR-100 |

### 1.1 Mã lỗi chuẩn

| HTTP | Khi nào | `code` nghiệp vụ (ví dụ) | BR |
| --- | --- | --- | --- |
| 400 | Sai định dạng, thiếu trường | `VALIDATION_FAILED` | — |
| 401 | Thiếu/hết hạn token | `UNAUTHENTICATED`, `TOKEN_EXPIRED` | NFR-10 |
| 403 | Không có quyền trên nhóm/phiên | `FORBIDDEN_GROUP`, `NOT_GROUP_OWNER`, `ACCOUNT_LOCKED`, `ADMIN_REQUIRED`, `CONSENT_REQUIRED` (chưa đồng ý/đồng ý lại), `OWNER_CANNOT_JOIN_SESSION`, `NOT_EXITED_IN_SESSION` | NFR-11, BR-06, BR-114 |
| 404 | Không tồn tại | `NOT_FOUND`, `INVITE_CODE_INVALID`, `REPORT_NOT_READY` | BR-76 |
| 409 | Xung đột trạng thái | `GROUP_FULL`, `ALREADY_IN_GROUP`, `OWNER_OF_THIS_GROUP`, `CONSENT_VERSION_STALE`, `MAX_GROUPS_OWNED`, `SCHEDULE_OVERLAP`, `SESSION_ALREADY_STARTED`, `SESSION_IN_PROGRESS`, `SESSION_NOT_FINISHED`, `ALREADY_OWNED`, `PRICE_CHANGED`, `APPEAL_EXISTS`, `APPEAL_WINDOW_CLOSED`, `APPEAL_ALREADY_DECIDED`, `EXPLANATION_WINDOW_CLOSED`, `ALREADY_REPORTED`, `VERSION_CONFLICT` | BR-74, BR-75, BR-78, BR-45, BR-86 |
| 422 | Hợp lệ cú pháp nhưng trái quy tắc | `INSUFFICIENT_COINS`, `ITEM_UNAVAILABLE`, `ITEM_NOT_OWNED`, `START_IN_PAST`, `DURATION_OUT_OF_RANGE`, `BALANCE_WOULD_BE_NEGATIVE`, `JOURNAL_TOO_LONG`, `JOURNAL_DATE_INVALID`, `IDEMPOTENCY_MISMATCH` | BR-02, BR-45, BR-100 |
| 429 | Vượt giới hạn | `RATE_LIMITED`, `INVITE_CODE_LOCKED` | BR-76 |

### 1.2 Ánh xạ trường API ↔ cột CSDL (chỗ tên khác)

| Trường API | Cột / bảng | Ghi chú |
| --- | --- | --- |
| `group_id`, `session_id`, `item_id`, `appeal_id`, `notification_id` | `<bảng>.id` | Tiền tố tên bảng ở API cho rõ |
| `report_purpose` | `groups.report_purpose` | Trước đây API ghi `purpose` — đã đổi |
| `month` (`YYYY-MM`) | `monthly_reports.period` (ngày 1 của tháng) | Chỉ khác định dạng |
| `ScheduleInput.start_time` (date-time) | `sessions.started_at`; với lịch lặp tách thành `schedules.start_time` + `start_date` | `recurrence.weekdays/end_date` = `schedules.weekdays/end_date` |
| `PATCH /sessions/{id}` `started_at` | `sessions.started_at` | Trước đây `start_time` — đã đổi |
| `Explanation.body`, `Appeal.body`, abuse `category`/`body` | `explanations.body`, `appeals.body`, `abuse_reports.category/body` | Trước đây `text`, `reason_code`, `note` — đã đổi |
| `decision` EXEMPT/REJECT/ESCALATE + `decision_reason` | `appeals.status` EXEMPTED/REJECTED/ESCALATED + `appeals.decision_reason` | Động từ ở API, trạng thái ở CSDL |
| `ShopItem.kind`, `status`, `preview_url` | `shop_items.kind`, `status`, `preview_key` (URL sinh từ khóa S3) | |
| `OwnedItem.acquired_at` | `user_items.acquired_at` | |
| `frame_item_id` / `background_item_id` / `title_item_id` | `user_equipped (kind = AVATAR_FRAME/BACKGROUND/TITLE)` | |
| `AccessLogEntry.object_type`, `view_count`, `first/last_viewed_at` | `access_logs.*` | |
| `MySessionResult.final_state` | `session_members.state` (chỉ giá trị kết thúc) | |
| `coins_balance` | view `user_coin_balance.balance` | Chỉ `/me` |

Ví dụ:
```json
{ "type": "https://api.dropit.example/errors/already-in-group", "title": "Đã ở nhóm khác",
  "status": 409, "code": "ALREADY_IN_GROUP", "br": "BR-75",
  "detail": "Bạn đang ở nhóm A. Rời nhóm A trước khi tham gia nhóm khác.", "request_id": "r-7f3c" }
```

---

## 2. Bảng endpoint → US/AC → màn

Cột AC ghi dải AC của story trong `02-ep0*.md`; MoSCoW lấy theo story. (Should) = `x-moscow: Should` trong openapi.

| Endpoint | US | AC | Màn | MoSCoW | BR chính |
| --- | --- | --- | --- | --- | --- |
| `GET /time` | — | — | mọi màn phiên | Must | BR-03, BR-33 |
| `GET /me` | US-01.01, US-07.01, US-07.04 | AC-01.01.1–10, AC-07.01.1–5, AC-07.04.1–4 | V-02, V-22 | Must | BR-51, BR-52 |
| `PATCH /me` | US-01.03 | AC-01.03.1–4 | V-23 | Must | BR-98 |
| `DELETE /me` | US-01.10 | AC-01.10.1–5 | V-25 | Should | BR-26, BR-62, BR-80 |
| `PUT /me/avatar` | US-07.03 | AC-07.03.1–6 | V-23 | Should | BR-98 |
| `GET /me/logout-check` | US-01.02 | AC-01.02.1–3 | V-24 | Must | BR-70 |
| `GET /me/groups` | US-01.04, US-02.06 | AC-01.04.1–5, AC-02.06.1–7 | V-19, V-41 | Must | BR-75, BR-114 |
| `GET /me/data` | US-01.08 | AC-01.08.1–5 | V-25 | Must | BR-53 |
| `POST /me/data/export` | US-01.09 | AC-01.09.1–4 | V-25 | Should | — |
| `GET /me/access-log` | US-01.11 | AC-01.11.1–4 | V-25 | Should | BR-73 |
| `PUT /me/devices` | US-04.01 | AC-04.01.x | (nền) | Must | BR-27 |
| `GET /invites/{code}` | US-02.03, US-01.05 | AC-02.03.1–7, AC-01.05.1–11 | V-04, V-05 | Must | BR-06, BR-76 |
| `POST /groups/{id}/consent` | US-01.05, US-01.06 | AC-01.05.1–11, AC-01.06.1–4 | V-05 | Must (đồng ý lại: Should) | BR-06, BR-74, BR-75, BR-114 |
| `DELETE /groups/{id}/consent` | US-01.07 | AC-01.07.1–7 | V-21 | Must | BR-26, BR-48, BR-59 |
| `POST /groups` | US-02.01 | AC-02.01.1–6 | V-42 | Must | BR-74, BR-75 |
| `GET /groups/{id}` | US-02.06 | AC-02.06.1–7 | V-19, V-40 | Must | BR-74 |
| `PATCH /groups/{id}` | US-02.02 | AC-02.02.1–5 | V-42 | Should | BR-06, BR-71 |
| `DELETE /groups/{id}` | US-02.09 | AC-02.09.1–7 | V-41 | Should | BR-29, BR-62, BR-80 |
| `GET/POST /groups/{id}/invite-code` | US-02.03 | AC-02.03.1–7 | V-43 | Must | BR-76 |
| `POST /groups/{id}/email-invites` | US-02.04 | AC-02.04.1–8 | V-43 | Should | BR-76, BR-122 |
| `GET /groups/{id}/members` | US-02.06 | AC-02.06.1–7 | V-20 | Must | BR-53, BR-115 |
| `DELETE /groups/{id}/members/{uid}` | US-02.08 | AC-02.08.1–6 | V-20 | Must | BR-77 |
| `GET/POST /groups/{id}/schedules` | US-02.10, US-02.10b | AC-02.10.1–8, AC-02.10b.1–5 | V-44, V-40 | Must (lặp: Should) | BR-01–04, BR-78, BR-113 |
| `PATCH/DELETE /sessions/{id}` | US-02.11 | AC-02.11.1–5 | V-45 | Must | BR-29, BR-78 |
| `POST /groups/{id}/abuse-reports` | US-02.13 | AC-02.13.1–5 | V-20, V-32 | Should | BR-109 |
| `GET /me/sessions/upcoming` | US-03.01 | AC-03.01.1–5 | V-03 | Must | BR-63 |
| `GET /sessions/{id}` | US-03.01, US-03.10 | AC-03.01.1–5 | V-06, V-46 | Must | BR-04, BR-63 |
| `GET /me/sessions` | US-03.14 | AC-03.14.1–8 | V-17 | Should | BR-119 |
| `GET /sessions/{id}/result` | US-03.10, US-06.01, US-05.03, US-05.05, US-03.12 | AC-03.10.1–8, AC-06.01.1–13 | V-12, V-13, V-14 | Must | BR-23, BR-37, BR-41, BR-68 |
| `GET /sessions/{id}/owner-detail` | US-08.10, US-04.06 | AC-08.10.1–12 | V-46 | Must | BR-116, BR-123, BR-53 |
| `GET /me/notifications`, `POST …/read` | US-04.01, US-03.09, US-04.09 | AC-04.01.1–11, AC-03.09.1–12 | V-16 | Must | BR-81, BR-82 |
| `PUT /sessions/{id}/explanation` | US-04.05 | AC-04.05.1–8 | V-15 | Must | BR-32, BR-54 |
| `GET /sessions/{id}/explanations` | US-04.06 | AC-04.06.1–6 | V-47 | Must | BR-61, BR-73 |
| `POST /sessions/{id}/appeals` | US-04.07 | AC-04.07.1–8 | V-13 | Should | BR-86 |
| `POST /appeals/{id}/decision` | US-04.08 | AC-04.08.1–9 | V-47 | Should | BR-87, BR-88 |
| `GET /me/achievements` | US-05.04, US-05.05, US-05.06 | AC-05.04.1–5, AC-05.05.1–8 | V-26, V-27, V-28 | Must | BR-49, BR-51, BR-52 |
| `GET /me/attendance` | US-05.02 | AC-05.02.1–6 | V-26 | Should | BR-46 |
| `GET /me/achievements/history` | US-05.08 | AC-05.08.1–6 | V-26 | Should | BR-47, BR-92 |
| `PUT /me/badges/{code}/display` | US-05.06 | AC-05.06.1–11 | V-28 | Should | BR-99 |
| `GET /groups/{id}/members/{uid}/attendance` | US-05.09 | AC-05.09.1–11 | V-20 → V-49 | Should | BR-53, BR-73 |
| `GET /me/coins` | US-06.02 | AC-06.02.1–7 | V-29 | Must | BR-43, BR-44 |
| `GET /shop/items` | US-06.03 | AC-06.03.1–8 | V-30 | Must | — |
| `POST /shop/purchases` | US-06.04 | AC-06.04.1–9 | V-31 | Must | BR-44, BR-45 |
| `GET /me/inventory`, `PUT /me/equipment` | US-06.05, US-07.04 | AC-06.05.1–8 | V-22, V-30 | Must | BR-95, BR-96 |
| `GET /users/{uid}/public-profile` | US-07.06 (US-07.04) | AC-07.06.1–5 | V-32 | Should | BR-53, BR-99 |
| `PUT /me/journal/{date}` | US-07.07 (sửa: US-07.08) | AC-07.07.1–6 | V-33 | Must | BR-100 |
| `GET /me/journal`, `DELETE /me/journal/{date}` | US-07.08, US-07.09 | AC-07.08.1–5, AC-07.09.1–5 | V-33 | Should | BR-100 |
| (không có endpoint cho người khác) | US-07.10 | AC-07.10.1–7 | — | Must | BR-100 |
| `GET /groups/{id}/reports` | US-08.01, US-08.09 | AC-08.01.1–11, AC-08.09.1–4 | V-48, V-34 | Must | BR-58, BR-103 |
| `GET /groups/{id}/reports/{month}` | US-08.02, US-08.03, US-08.04, US-08.05, US-08.08 | AC-08.02.1–12, AC-08.03.1–5 | V-48, V-34, V-35 | Must (tổng nhóm, so tháng trước: Should) | BR-57, BR-61, BR-104, BR-115 |
| `GET …/reports/{month}/members/{uid}` | US-08.02 | AC-08.02.x | V-49 | Must | BR-53, BR-73 |
| `GET …/reports/{month}/pdf` | US-08.06 | AC-08.06.1–7 | V-48 | Should | BR-105 |
| (email SES do job gửi, không có REST) | US-08.07 | AC-08.07.1–8 | V-50 | Must | BR-122 |
| `/admin/*` | US-09.02–09.07 | AC-09.0x | V-60–V-63 | Should | BR-44, BR-73, BR-109 |

Ghi chú: phần tương tác **trong phiên** (US-03.01–03.12, US-04.01) đi qua Socket.io, không phải REST — xem §3.

---

## 3. Hợp đồng Socket.io

### 3.1 Kết nối, namespace, room

| Mục | Thiết kế |
| --- | --- |
| URL | `wss://rt.dropit.example` path `/socket.io`, namespace **`/session`** (chỉ phục vụ phiên). Transport `websocket` (tắt long-polling để giảm pin, **đề xuất, DQ-A06**). |
| Handshake | `auth: { token: "<access token Cognito>", v: 1, device_id: "<uuid>" }`. Middleware kiểm JWT như REST (P2). Sai → lỗi `connect_error` với `data.code = UNAUTHENTICATED`. |
| Làm mới token | Client gửi `auth:refresh { token }` trước khi hết hạn; server kiểm lại (NFR-10). Hết hạn mà không làm mới → server gửi `error {code: TOKEN_EXPIRED}` rồi ngắt; xử lý như mất kết nối (BR-19), **không** tính thoát (BR-70). |
| Room | `session:{session_id}` — mọi người có trạng thái trong phiên (kể cả đã kết thúc trước, để nhận `MEMBER_EXITED` theo BR-27b). `user:{user_id}` — mọi socket của một người (giao thông báo hộp thư khi đang mở app, NFR-02). **Không** có room cho chủ nhóm ở namespace `/session` (BR-114, BR-123); chủ nhóm đang mở app nhận `MEMBER_EXITED` qua room `user:{id}` (nhận thông báo, không nhận trạng thái phiên). |
| Một socket / (người, phiên) | Khi `session:join` từ socket thứ hai của cùng người cho cùng phiên đang chạy: từ chối `SESSION_ALREADY_JOINED_ELSEWHERE` (BR-70). Socket thứ nhất giữ phiên. Nếu socket thứ nhất đã đóng (đang DISCONNECTED) thì socket mới chỉ được vào bằng `session:resume` từ **cùng `device_id`** **(đề xuất, DQ-A07)**. |
| Phong bì C→S | Mọi sự kiện C→S có `event_id` (UUID v4) và `client_ts` (chỉ để log, không dùng quyết định — BR-33). Server giữ tập `event_id` đã xử lý theo (người, phiên) đến hết phiên; trùng → ack lại kết quả cũ với `duplicate: true`, không đổi trạng thái (BR-31). |
| Ack | Mọi sự kiện C→S dùng callback ack: `{ ok: true, state, server_ts, duplicate? }` hoặc `{ ok: false, code, detail }`. Client chờ ack tối đa 5 s rồi gửi lại **cùng** `event_id`. |
| Phong bì S→C | `{ event_id, type, session_id, server_ts, ...payload }`. `event_id` do server sinh để client chống hiển thị trùng (banner/hộp thông báo) khi nhận cả qua socket lẫn khi nối lại. |
| Rate limit | Tối đa 20 sự kiện/10 s/socket (trừ heartbeat); vượt → `error {code: RATE_LIMITED}`, bỏ sự kiện **(đề xuất, DQ-A04)**. |

### 3.2 Sự kiện Client → Server

| Sự kiện | Payload | Khi nào gửi | Server xử lý | Ack `state` | BR |
| --- | --- | --- | --- | --- | --- |
| `session:join` | `{event_id, session_id}` | Mở phòng chờ V-06 (từ `lobby_opens_at`), hoặc vào muộn | Kiểm: là thành viên đã đồng ý, không phải chủ nhóm (`OWNER_CANNOT_JOIN_SESSION`), chưa có phiên khác chưa kết thúc (BR-09), đúng cửa sổ (`LOBBY_NOT_OPEN` kèm `lobby_opens_at`; quá hạn vào muộn → `LATE_JOIN_CLOSED`). Phiên ACTIVE + trong hạn → vào muộn (Should, BR-07). Join room, gửi `session:state`. | `WAITING` hoặc `FOCUSING` | BR-01, BR-06, BR-07, BR-09, BR-63, BR-114 |
| `heartbeat` | `{session_id}` (không cần `event_id`) | Mỗi `heartbeat_s` = 5 s khi tiền cảnh + màn hình mở | Cập nhật `last_seen_at`. Không ack (dùng `volatile`). | — | BR-19, BR-66 |
| `clock:ping` | `{t0}` | Khi vào phiên, sau đó mỗi 60 s | Ack `{t0, server_ts}` để ước độ lệch (giữ từ spike T01). | — | BR-03 |
| `member:left_app` | `{event_id, session_id, client_ts}` | Vòng đời `paused/hidden` không kèm khóa màn hình | FOCUSING → GRACE, hẹn `grace_deadline = nhận + grace_s`; gửi `member:grace` cho chính người đó. PAUSED → bỏ qua. Sau `ends_at` → bỏ qua (BR-33). | `GRACE` | BR-11, BR-16, BR-33 |
| `member:returned` | `{event_id, session_id, client_ts}` | `resumed` | GRACE trước hạn → FOCUSING, ghi `grace_recovered`, không báo ai. Sau hạn → đã EXITED, ack `EXITED`. | `FOCUSING` / `EXITED` | BR-12, BR-13 |
| `member:screen_locked` | `{event_id, session_id, client_ts}` | Tín hiệu khóa màn hình native | Đặt cờ `screen_locked`, ngừng áp ngưỡng heartbeat, không coi socket đóng là DISCONNECTED; không đổi trạng thái. | giữ nguyên | BR-15, BR-66, D-08 |
| `member:screen_unlocked` | `{event_id, session_id, client_ts}` | Mở khóa | Gỡ cờ, `last_seen_at = nhận`. Giao các thông báo đang xếp hàng (BR-82). | giữ nguyên | BR-66, BR-82 |
| `member:pause` | `{event_id, session_id, reason_code}` | Bấm tạm dừng (Should) | Chỉ từ FOCUSING, còn lượt (1/phiên) → PAUSED, hẹn ≤ 5 phút. `reason_code` ∈ danh sách cố định, không có tên app. Hết lượt → `PAUSE_LIMIT_REACHED`. | `PAUSED` | BR-16, BR-17, BR-67 |
| `member:resume` | `{event_id, session_id}` | Kết thúc tạm dừng | PAUSED → FOCUSING. | `FOCUSING` | BR-16 |
| `session:leave` | `{event_id, session_id}` | Đã xác nhận hộp "Rời phiên" ở V-06/V-08 (không có ở V-07). Không có mạng → client báo lỗi, **không** xếp hàng | FOCUSING/GRACE/PAUSED → EXITED (`reason = USER_LEAVE`), hủy hẹn GRACE, áp đủ hệ quả thoát; WAITING → ABSENT **(giả định, Q-149)**; trạng thái kết thúc → bỏ qua. | `EXITED` / `ABSENT` / trạng thái cũ | BR-118, D-29 |
| `member:withdraw` | `{event_id, session_id}` | Rút đồng ý giữa phiên (V-21) | → WITHDRAWN ngay (ưu tiên mọi hạn đang chạy), dừng ghi; **không** `MEMBER_EXITED`, không Coins, không kích hoạt D-05. Server **đồng thời rời nhóm** (cùng xử lý với REST `DELETE /groups/{id}/consent` — client không cần gọi thêm). Ack thêm `left_group: true`, `after_forfeit` (true nếu rút từ `forfeited_at` trở đi → vẫn ngắt chuỗi tại `ends_at`, D-23). Người đã WITHDRAWN không nhận `MEMBER_EXITED` sau đó. | `WITHDRAWN` | BR-26, BR-37, D-23 |
| `session:resume` | `{event_id, session_id, last_server_event_id?}` | Socket mới sau mất mạng | Xem §3.4. | trạng thái hiện tại | BR-19, BR-20, BR-65 |
| `auth:refresh` | `{token}` | Trước khi token hết hạn | Kiểm lại JWT. | — | NFR-10 |

### 3.3 Sự kiện Server → Client

| Sự kiện | Payload (JSON) | Ai nhận | Khi nào | BR |
| --- | --- | --- | --- | --- |
| `session:state` | `{event_id, session_id, status, server_ts, started_at, ends_at, remaining_s, participant_count, lobby_members, my_state, my_grace_deadline?, my_pause_deadline?, pause_left, forfeited, forfeit_trigger_display_name?}` | Room `session:{id}` (phần `my_*` gửi riêng từng socket) | Sau join/resume, khi có người vào phòng chờ, khi đổi trạng thái phiên, khi số người đổi. `lobby_members`: **chỉ tên** người đang WAITING, sắp theo tên (BR-115), chỉ có giá trị khi `status` ∈ SCHEDULED/COUNTDOWN (phòng chờ V-06); từ ACTIVE là `[]`. **Không** danh sách trạng thái từng người trong phiên, không thứ hạng (NFR-P06). | BR-04, BR-115 |
| `session:countdown` | `{event_id, session_id, countdown_starts_at, started_at, server_ts}` | Room phiên | Tại `started_at − countdown_s` | BR-04, BR-05 |
| `member:grace` | `{event_id, session_id, grace_deadline, server_ts}` | Chỉ chính người đó | Khi vào GRACE | BR-11 |
| `member:state` | `{event_id, session_id, my_state, reason?, server_ts}` | Chỉ chính người đó | Mọi chuyển trạng thái của mình (EXITED do hết hạn GRACE, LOST, nối lại…) | BR-13, BR-21 |
| `SESSION_UPDATED` | `{event_id, session_id, reason: "RESCHEDULED", server_ts}` | Người đang ở phòng chờ của phiên | Chủ nhóm đổi giờ/thời lượng phiên SCHEDULED (US-02.11): runtime cũ bị bỏ, client rời phòng chờ và vào lại theo `lobby_opens_at` mới. Hủy phiên → `session:state` với `status = CANCELLED` (WAITING → VOID, AC-03.01.4). Thông báo `SESSION_UPDATED`/`SESSION_CANCELLED` cho mọi thành viên qua hộp thông báo + room `user:{id}`/push. | BR-29, BR-79 |
| `MEMBER_EXITED` | `{event_id, type:"MEMBER_EXITED", session_id, group_id, exited_display_name, exited_at, server_ts, forfeited: {display_name, at}?}` — gộp `SESSION_FORFEITED` khi đây là lần thoát khởi phát | (a) mọi thành viên hiện tại của nhóm + chủ nhóm, (b) mọi người có trạng thái trong phiên; trừ người thoát | ≤ `notify_latency_s` = 5 s sau khi server xác nhận EXITED (không phải lúc bắt đầu GRACE). Người trong phiên: qua room phiên, client hiện banner V-11 nếu tiền cảnh + mở màn hình; nếu khóa/GRACE/PAUSED → **server giữ trong hàng đợi** và giao khi `member:screen_unlocked`/`member:returned`/`member:resume`. Người ngoài phiên đang mở app: room `user:{id}`; không mở app: push SNS (§4). Không có tên app, lý do, Coins. | BR-27, BR-28, BR-38, BR-82, D-20, D-22 |
| `SESSION_FORFEITED` | Không phát riêng ở MVP — là trường `forfeited` trong `MEMBER_EXITED` (một thông báo/người, BR-38). Hộp thông báo lưu cả hai `type`. | — | — | BR-38 |
| `SESSION_CANCELLED_OUTAGE` | `{event_id, session_id, reason:"SERVER_OUTAGE", server_ts}` | Người VOID (chưa kết thúc lúc sự cố) + chủ nhóm + thành viên nhóm | Phiên CANCELLED do sự cố | BR-22, BR-29 |
| `SESSION_CANCELLED_OUTAGE_EXITED` | `{event_id, session_id, reason:"SERVER_OUTAGE", streak_broken:true, can_appeal:true, server_ts}` | Chỉ người đã EXITED trước sự cố | Cùng lúc trên | BR-68 |
| `SESSION_CANCELLED` | `{event_id, session_id, reason: session_cancel_reason (OWNER_CANCEL / GROUP_DISSOLVED / OWNER_LOCKED / ADMIN), server_ts}` | Người đang WAITING (socket); mọi thành viên nhóm qua hộp thông báo + push (thay đề xuất `SESSION_CANCELLED_BY_OWNER` của DQ-F09) | Phiên SCHEDULED/COUNTDOWN bị hủy không do sự cố | BR-29, BR-63, BR-80, BR-108 |
| `SESSION_RESULT` | `{event_id, session_id, final_state, focus_seconds, coins_awarded, streak_after, streak_broken, new_badges[], forfeited, server_ts}` | Chỉ chính người đó | Sau khi phiên chốt trong transaction (đến `ends_at`, hoặc khi người đó đã kết thúc và phiên chốt). Chi tiết lấy lại bằng `GET /sessions/{id}/result`. | BR-23, BR-24, BR-41, BR-91 |
| `EXEMPTION_GRANTED` | Người được miễn trừ: `{event_id, session_id, appeal_id, coins_refunded?, server_ts}`. Bản đính chính cho người khác: `{event_id, session_id, exempted_display_name, forfeited, server_ts}` — **không** `coins_refunded` | Người được miễn trừ (room `user:{id}`); bản đính chính cho đúng danh sách đã nhận `MEMBER_EXITED` gồm chủ nhóm **(đề xuất, Q-138 Chờ)** | Quyết định EXEMPT (Should) | BR-35, BR-43, BR-87, BR-53 |
| `MEMBER_REMOVED` | `{event_id, session_id, group_id, server_ts}` | Chỉ người bị xóa | Chủ nhóm xóa giữa phiên; hộp thông báo lưu `type = REMOVED_FROM_GROUP` | BR-77 |
| `error` | `{code, detail}` | Socket liên quan | Lỗi không gắn với ack | — |

Chủ nhóm **không** nhận `session:state`, `member:*`, đồng hồ (BR-116, BR-123); màn V-46 chỉ GET REST và hiện "Cập nhật lúc…".

### 3.4 Luồng nối lại

1. Socket đóng / mất heartbeat → server đặt `disconnected_at` (sớm hơn của: lúc phát hiện đóng, `last_seen_at + heartbeat_timeout_s`), trạng thái DISCONNECTED, nhớ trạng thái trước (BR-19). Đang báo khóa màn hình → **không** áp (BR-66).
2. Client tự kết nối lại (backoff 0,5 s → 1 → 2 → 4 s, có jitter), handshake JWT, gửi `session:resume {event_id, session_id, last_server_event_id}`.
3. Server: nếu `nhận < disconnected_at + disconnect_hold_s` (10 s) → về trạng thái trước (FOCUSING/PAUSED), ghi `reconnected`, ack `{ok, state}`, gửi `session:state` rồi **phát lại** mọi S→C có `event_id` sau `last_server_event_id` (hàng đợi theo người, giữ đến hết phiên). Client bỏ `event_id` đã thấy.
4. Quá hạn → LOST (không `MEMBER_EXITED`, không D-05); ack `{ok:false, code:"SESSION_LOST", state:"LOST"}`, client mở V-10 → V-14.
5. DISCONNECTED lúc `ends_at`: chưa chốt; nối lại trong hạn → COMPLETED (phút tính đến `disconnected_at`); không → LOST (BR §3 #7, Q-31).
6. Sự cố hàng loạt (≥ `outage_ratio` trong `outage_window_s`) → CANCELLED (BR-22); người nối lại sau đó nhận `SESSION_CANCELLED_OUTAGE(_EXITED)`.
7. Instance server khởi động lại (MVP 1 instance, trạng thái trong bộ nhớ) → xem DQ-A08.

### 3.5 Mã lỗi socket

| `code` | Nghĩa | Gặp ở |
| --- | --- | --- |
| `UNAUTHENTICATED`, `TOKEN_EXPIRED` | JWT sai/hết hạn | handshake, `auth:refresh` |
| `FORBIDDEN_GROUP` | Không thuộc nhóm của phiên | `session:join`, `session:resume` |
| `CONSENT_REQUIRED` | Chưa đồng ý / cần đồng ý lại | `session:join` |
| `OWNER_CANNOT_JOIN_SESSION` | Chủ nhóm của nhóm này | `session:join` |
| `ALREADY_IN_OTHER_SESSION` | Đang có phiên khác chưa kết thúc | `session:join` (BR-09) |
| `SESSION_ALREADY_JOINED_ELSEWHERE` | Thiết bị khác đang giữ phiên | `session:join`, `session:resume` (BR-70) |
| `LOBBY_NOT_OPEN` (+`lobby_opens_at`) | Trước giờ mở phòng chờ | `session:join` (BR-63) |
| `LATE_JOIN_CLOSED` | Quá hạn vào muộn | `session:join` (BR-07) |
| `SESSION_NOT_ACTIVE` | Phiên đã kết thúc/hủy | mọi sự kiện |
| `INVALID_TRANSITION` | Chuyển trạng thái không hợp lệ | `member:*` (BR-31) |
| `PAUSE_LIMIT_REACHED` | Hết lượt tạm dừng | `member:pause` (BR-16) |
| `SESSION_LOST` | Quá hạn giữ chỗ | `session:resume` (BR-21) |
| `RATE_LIMITED` | Quá tần suất | mọi sự kiện |

---

## 4. Push qua Amazon SNS

- Thiết bị đăng ký qua `PUT /me/devices` → SNS platform endpoint (APNs/FCM). Server không đọc gì từ máy ngoài token push.
- Payload (data + notification tối giản, không Coins, không tên app):
```json
{ "notification": { "title": "Nhóm Học Toán", "body": "Minh đã rời phiên lúc 20:14. Phiên đã mất thưởng tập thể — vẫn tiếp tục đến hết giờ." },
  "data": { "type": "MEMBER_EXITED", "event_id": "…", "notification_id": "…", "group_id": "…", "session_id": "…", "server_ts": "2026-10-19T13:14:05Z", "forfeited": "true" } }
```

| Loại | Ai nhận push | Khi **không** gửi push | BR |
| --- | --- | --- | --- |
| `MEMBER_EXITED` (+forfeited) | Chủ nhóm, thành viên nhóm không trong phiên, người trong phiên **đã kết thúc**, khi **không** mở app (không có socket `user:{id}` sống) | (1) Người nhận đang có trạng thái chưa kết thúc trong phiên (WAITING/FOCUSING/GRACE/PAUSED/DISCONNECTED) — kể cả khóa màn hình: không push, không thông báo cục bộ trên màn khóa; xếp hàng, hiện khi quay lại app (BR-82). (2) Đang mở app → giao qua socket (NFR-02). (3) Chính người thoát. | BR-27, BR-82, NFR-01, NFR-02 |
| `SESSION_CANCELLED_OUTAGE` / `_EXITED` | Như trên (người VOID đã kết thúc trạng thái nên nhận được) | Đang mở app → socket | BR-22, BR-68 |
| `SESSION_RESULT`, Coins, chuỗi, huy hiệu, ngắt chuỗi | Chỉ chính người đó, **sau** khi phiên chốt | Không bao giờ trong lúc phiên chạy; ngắt chuỗi do D-05 gộp vào thông báo kết quả | BR-91 |
| `SESSION_REMINDER` (Should) | Thành viên nhóm (không gồm chủ nhóm) trước giờ phiên | Người đang trong phiên khác | BR-79 |
| `EXEMPTION_GRANTED`, `APPEAL_DECIDED` (Should), `REMOVED_FROM_GROUP`, `GROUP_DISSOLVED`, `CONSENT_CHANGED` | Người liên quan | Đang trong phiên chưa kết thúc → hoãn đến sau phiên (BR-82, giả định) | BR-77, BR-80, BR-87 |

Mọi thông báo đều được ghi vào hộp thông báo (`/me/notifications`) với cùng `event_id`, nên client khử trùng giữa push, socket và hộp thư (BR-81).

---

## 5. Câu hỏi thiết kế (DQ-A)

| Mã | Câu hỏi | Đề xuất | Ảnh hưởng |
| --- | --- | --- | --- |
| DQ-A01 | Tên miền/host REST và realtime (một ALB hay tách)? | **Đã giải** — theo ADR-09 (01 §6): MVP một EC2, Nginx + Let's Encrypt kết thúc TLS, `/v1` và `/socket.io` cùng host; ALB là Should. Tên miền còn chờ DQ-02 | Hạ tầng |
| DQ-A02 | Tên bảng/trường chính thức — chờ `design/02-du-lieu.md` | **Đã giải** — đã đổi tên trường API theo schema, xem §1.2 | openapi.yaml |
| DQ-A03 | Có chặn bản app cũ (426) không? | Có, theo `X-App-Version` **(đề xuất)** | Client |
| DQ-A04 | Ngưỡng rate limit REST/socket | 60/phút chung, 10/phút ghi, 20 sự kiện/10 s socket **(đề xuất)** | NFR |
| DQ-A05 | Thời lượng phiên cho phép (BR-02): danh sách cố định hay khoảng? | **Đã giải** — BR-02 cố định {25, 50}; openapi `DurationMin enum [25, 50]` | `ScheduleInput` |
| DQ-A06 | Tắt long-polling fallback? | Có (pin, đơn giản); mạng chặn WebSocket coi như mất kết nối **(đề xuất)** | NFR-08 |
| DQ-A07 | `session:resume` từ thiết bị khác khi đang DISCONNECTED có được nhận không? | Không — chỉ cùng `device_id` (BR-70) **(đề xuất)**; cần BA xác nhận | BR-70 |
| DQ-A08 | Server khởi động lại giữa phiên (trạng thái trong bộ nhớ) xử lý thế nào? | Coi là sự cố → BR-22 (CANCELLED) nếu không khôi phục trong `outage_window_s`; Redis ở Should **(đề xuất)** | BR-22, 05 §3.1 |
| DQ-A09 | `SESSION_FORFEITED` có cần phát thành sự kiện riêng không? | **Đã giải** — gộp trong `MEMBER_EXITED.forfeited` vì BR-38 bắt buộc "một thông báo" mỗi người nhận; hộp thông báo vẫn có `type` SESSION_FORFEITED để lọc | Client |
| DQ-A10 | Thông báo không liên quan phiên (bị xóa khỏi nhóm khác, giải tán) khi người nhận đang trong phiên: hoãn push hay gửi? | Hoãn đến sau phiên (mở rộng BR-82) **(đề xuất)** — cần tạo Q- | BR-82 |
| DQ-A11 | Giữ `event_id` C→S bao lâu để chống trùng? | Đến hết phiên + 1 giờ, theo (người, phiên) | BR-31 |
| DQ-A12 | Endpoint đồng ý lại (US-01.06) dùng chung `POST /consent` không có `invite_code` — có đủ an toàn? | Có, vì đã là thành viên; server kiểm `group_members` | US-01.06 |
| DQ-A13 | Spike T01 dùng `member:join` và namespace mặc định; hợp đồng này đổi sang `session:join` + `/session`. | Cập nhật spike khi chuyển sang code thật | spike |
