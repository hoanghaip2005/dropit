# SRS 05 — Tham chiếu kỹ thuật

Mục đích: giữ lại phần kỹ thuật còn giá trị từ đặc tả cũ bản 1.0 (nguồn cũ đã xóa), đã chuyển sang mô hình DropIt! bản 1.1.
Toàn bộ tệp là **(tham khảo thiết kế, không phải yêu cầu)**. Yêu cầu kiểm tra được nằm ở `03-quy-tac.md` (BR-) và `04-nfr-rieng-tu.md` (NFR-). Khi mâu thuẫn, BR/NFR và `02-so-quyet-dinh.md` thắng.

Đã bỏ hẳn (không dùng lại): cược điểm (D-01), "nổ phòng"/FAILED cả phòng (thay bằng mất thưởng tập thể, D-05), Host/Guest (thay bằng chủ nhóm/thành viên, D-10, D-25), phòng 2–6 người và mã phòng 6 số (thay bằng nhóm 4–10, D-02), Điểm Uy Tín (thay bằng Coins, D-09), màn hình bêu tên người vi phạm.

Ngày tạo: 2026-10-19.

---

## 1. Phát hiện rời app trên thiết bị

(tham khảo thiết kế, không phải yêu cầu) — Liên quan: BR-11, BR-12, BR-13, BR-15, BR-34, BR-64, BR-66; NFR-03, NFR-04, NFR-08, NFR-18, NFR-19; D-07, D-08.

### 1.1 Nguyên tắc chung
- Chỉ dùng **sự kiện vòng đời của chính app** (tiền cảnh/nền/khóa màn hình). Không đọc tên app khác, nội dung thông báo, vị trí (BR-34, GĐ1 §6).
- Chỉ lắng nghe và gửi sự kiện khi đang ghi phiên (BR-05, NFR-P02).
- Client chỉ **báo** tín hiệu; server quyết định trạng thái theo giờ server (BR-03, BR-33).

### 1.2 Flutter (D-07)
- Lớp chung: `WidgetsBindingObserver.didChangeAppLifecycleState` (`resumed`, `inactive`, `paused`, `hidden`, `detached`) hoặc `AppLifecycleListener`.
- Flutter **không phân biệt** "khóa màn hình" với "rời app" đủ tin cậy (cả hai đều ra `inactive`/`paused`). Cần **platform channel** gọi mã native để lấy tín hiệu khóa màn hình (D-08, BR-15).
- Gợi ý ánh xạ sang sự kiện gửi server (mục 2): `paused`/`hidden` không kèm khóa màn hình → `member:left_app`; có tín hiệu khóa → `member:screen_locked`; `resumed` → `member:returned` hoặc `member:screen_unlocked`.

### 1.3 iOS (native, qua platform channel)
- Vòng đời scene: `sceneWillResignActive`, `sceneDidEnterBackground`, `sceneDidBecomeActive`.
- Khóa màn hình: `UIApplication.protectedDataWillBecomeUnavailable` / `protectedDataDidBecomeAvailable` (chỉ đúng khi máy có đặt mã khóa — cần ghi giới hạn).
- Kéo trung tâm thông báo/điều khiển thường gây `willResignActive` nhưng **không** vào nền. Đề xuất: chỉ coi là rời app khi `didEnterBackground` mà không có tín hiệu khóa; `willResignActive` đơn thuần không tính (tránh phạt oan). Cần spike trên iPhone thật (Q-61, Q-142, R-K01).
- Không có Mac (D-26): debug qua TestFlight + log từ xa (R-K01, NFR-24).

### 1.4 Android (native, qua platform channel)
- Chính: `ProcessLifecycleOwner` (`ON_STOP`/`ON_START`) hoặc `Activity.onPause/onStop`.
- Khóa/mở khóa: `ACTION_SCREEN_OFF`, `ACTION_SCREEN_ON`, `ACTION_USER_PRESENT` (đăng ký động trong lúc ghi phiên); `KeyguardManager.isKeyguardLocked()` để xác nhận.
- **Cấm `UsageStatsManager`** và quyền Usage Access (BR-34): nó cho biết app khác đang chạy — trái GĐ1 §6.
- Tối ưu pin của hãng có thể giết tiến trình nền. Cân nhắc Foreground Service (loại phù hợp, có thông báo thường trực "Phiên đang được ghi", khớp BR-05) — chờ spike; thử ≥ 2 hãng (NFR-19).

### 1.5 Màn hình phiên
- Giao diện tối, tĩnh, ít animation để tiết kiệm pin (NFR-08).
- Cho tắt màn hình (D-08); không bắt buộc giữ sáng.

---

## 2. Giao thức socket (Socket.io)

(tham khảo thiết kế, không phải yêu cầu) — Liên quan: BR-03, BR-04, BR-19, BR-27, BR-28, BR-31, BR-33, BR-38, BR-66, BR-70, BR-82, BR-91; NFR-01, NFR-02, NFR-09, NFR-10, NFR-11.

- Xác thực: JWT Cognito trong handshake; kiểm tra lại khi làm mới token (NFR-10).
- Mọi sự kiện kiểm tra quyền theo (người dùng, nhóm, phiên) ở server (NFR-11); rate limit.
- Mỗi sự kiện C→S có `event_id` duy nhất; server xử lý idempotent (BR-31).
- Mỗi (người, phiên) chỉ một socket (BR-70).
- Không có sự kiện tạo phòng/sẵn sàng/bắt đầu do người dùng: phiên mở theo lịch chủ nhóm (D-06, BR-01, BR-04).

| Hướng | Sự kiện (gợi ý) | Payload chính | Ghi chú |
| --- | --- | --- | --- |
| C→S | `session:join` | sessionId | Vào phòng chờ (BR-63) hoặc vào muộn (BR-07) |
| C→S | `member:left_app` | eventId, clientTs | Bắt đầu GRACE (BR-11) |
| C→S | `member:returned` | eventId, clientTs | Quay lại trong hạn (BR-12) |
| C→S | `member:screen_locked` / `member:screen_unlocked` | eventId, clientTs | D-08, BR-15, BR-66 |
| C→S | `member:pause` / `member:resume` | eventId, reasonCode | BR-16, BR-67 (không có tên app) |
| C→S | `member:withdraw` | eventId | Rút đồng ý giữa phiên (BR-26) |
| C→S | `session:leave` | eventId, sessionId | Bấm "Rời phiên" và đã xác nhận (D-29, BR-118). Chỉ gửi sau khi xác nhận; hủy hộp thì không gửi. Server: FOCUSING/GRACE/PAUSED → EXITED (`reason = USER_LEAVE`); WAITING → ABSENT **(giả định, Q-149)**; trạng thái kết thúc → bỏ qua. Không có mạng → client báo lỗi, không xếp hàng gửi sau. Phản hồi ack kèm trạng thái mới |
| C→S | `heartbeat` | sessionId | Chu kỳ `heartbeat_s` (BR-19) |
| C→S | `session:resume` | sessionId | Nối lại sau mất mạng (BR-20) |
| S→C | `session:state` | trạng thái phiên, số người, `remaining` | Không xếp hạng (BR-115) |
| S→C | `session:countdown` | `startedAtServerTs` | BR-04 |
| S→C | `member:grace` | graceDeadlineServerTs | Chỉ gửi cho chính người đó |
| S→C | `MEMBER_EXITED` (+ `SESSION_FORFEITED` gộp) | tên người thoát, giờ server | BR-27, BR-38; ≤ `notify_latency_s` (BR-28) |
| S→C | `SESSION_CANCELLED_OUTAGE` / `SESSION_CANCELLED_OUTAGE_EXITED` | lý do | BR-22, BR-68 |
| S→C | `SESSION_RESULT` | trạng thái cuối, Coins | BR-91 |

Push SNS chỉ gửi cho người **không** có trạng thái chưa kết thúc trong phiên (chủ nhóm, thành viên ngoài phiên, người trong phiên đã kết thúc) và đang không mở app (BR-27, NFR-01); người đang mở app nhận qua socket (NFR-02); người đang trong phiên mà khóa màn hình/GRACE/PAUSED không nhận push, thấy banner khi quay lại app (BR-82). Trong phiên không push hệ thống dụ rời app (Q-87, BR-82).

---

## 3. Mô hình dữ liệu

(tham khảo thiết kế, không phải yêu cầu) — Liên quan: D-04, D-09, D-10, D-21, D-25; BR-03, BR-19, BR-32, BR-35, BR-44; NFR-12, NFR-P (thời hạn lưu §4 của `04-nfr-rieng-tu.md`).

### 3.1 Trạng thái nóng
MVP 1 instance EC2 giữ trạng thái trong bộ nhớ; Redis/ElastiCache là Should (khi > 1 instance). Khi dùng Redis:
- `session:{id}` (hash): status, groupId, duration, startedAt, endsAt, forfeited, forfeitedAt, forfeitTriggerUserId.
- `session:{id}:members` (hash): userId → {state, lastSeenAt, disconnectedAt, graceUsed, graceDeadline, pauseUsed, pauseDeadline, screenLocked}.
- `user:{id}:session` → sessionId (chốt chặn BR-09).
- Khi phiên kết thúc: ghi xuống PostgreSQL trong **một transaction** (chốt trạng thái + Coins cho mọi người, D-05).

### 3.2 PostgreSQL (RDS) — dữ liệu lõi
- `users(id, cognito_sub, display_name, avatar_url, status, created_at)` — không có điểm uy tín; số dư Coins suy từ sổ cái.
- `groups(id, owner_id, name, purpose, status, created_at)` — chủ nhóm theo nhóm (D-10).
- `group_members(group_id, user_id, consent_version, consented_at, joined_at, left_at)` — tối đa 1 nhóm/thành viên (D-21); chủ nhóm không là dòng thành viên (D-25).
- `schedules(id, group_id, start_time, duration_min, recurrence, ...)` (BR-113).
- `sessions(id, group_id, schedule_id, duration_min, status, started_at, ends_at, forfeited, forfeited_at, forfeit_trigger_user_id, cancel_reason)`.
- `session_members(session_id, user_id, final_state, late_join, focus_seconds, exempted)` — trạng thái cuối bất biến (BR-32).
- `coin_ledger(entry_id, user_id, amount, type, ref_id, reward_date, created_at, reason)` — sổ cái chỉ-thêm (BR-44).
- `admin_audit(id, admin_id, action, target, note, created_at)` (EP-09).

### 3.3 DynamoDB — log (D-04)
- Log sự kiện phiên (rời app/quay lại/tạm dừng/khóa màn hình) theo (sessionId, userId, serverTs); TTL theo thời hạn lưu.
- Nhật ký cá nhân (mã hóa, NFR-12), nhật ký truy cập.

---

## 4. Kiến trúc AWS

(tham khảo thiết kế, không phải yêu cầu) — Liên quan: mục "Ánh xạ dịch vụ AWS" và NFR-09, NFR-13, NFR-14, NFR-22, NFR-24 trong `04-nfr-rieng-tu.md` (nguồn chính).

- **VPC:** public subnet cho EC2; private subnet cho RDS (và ElastiCache nếu dùng). Security Group chỉ cho EC2 vào DB (NFR-13). Tránh NAT Gateway.
- **EC2:** Node.js + Socket.io (PM2/Docker); TLS bằng Nginx + Let's Encrypt ở MVP. Khi mở rộng: nhiều instance sau ALB (sticky session) + `socket.io-redis-adapter` (Should).
- **RDS PostgreSQL:** dữ liệu lõi, backup tự động, mã hóa at-rest (NFR-12, NFR-16).
- **DynamoDB, Cognito, SNS, S3, SES, CloudWatch:** theo bảng ánh xạ ở `04-nfr-rieng-tu.md`.
- **CI/CD:** GitHub Actions → build → deploy EC2; iOS build trên runner macOS (D-26, NFR-24). Giám sát CloudWatch (kết nối, lỗi, độ trễ).
- **Chi phí:** xem "Lưu ý chi phí / Free Tier" ở `04-nfr-rieng-tu.md`; dev có thể chạy Redis/PostgreSQL bằng container.

---

## 5. Chống gian lận và heartbeat

(tham khảo thiết kế, không phải yêu cầu) — Liên quan: BR-03, BR-13, BR-19, BR-20, BR-21, BR-31, BR-33, BR-65, BR-66, BR-70; Q-30, Q-61, Q-86.

- Server so heartbeat theo `last_seen_at`; app bị "đóng băng" mà không báo khóa màn hình → mất heartbeat → DISCONNECTED → LOST theo BR-19 (không phải EXITED, D-19).
- Chống lách bằng chế độ máy bay: hạn khoan hồng 3 giây vẫn chạy trên server khi đang GRACE, không chuyển DISCONNECTED (đề xuất Q-30).
- Chống lách bằng báo "khóa màn hình" giả: đối chiếu tín hiệu native (mục 1); nếu sau đó nhận `member:returned` mà không có `screen_unlocked` hợp lệ thì coi như rời app (cần spike, Q-61).
- Mọi mốc dùng giờ server; bỏ qua `clientTs` khi quyết định (BR-03, BR-33).
- Một socket mỗi (người, phiên); thiết bị thứ hai không chiếm phiên (BR-70).
- Root/jailbreak: chỉ cảnh báo ở MVP, không chặn (giả định).
- Gian lận còn lại (máy thứ hai, app sửa đổi): xử lý qua khiếu nại/quản trị (EP-09); ghi giới hạn trong tài liệu kiểm thử.

---

## 6. Ca kiểm thử kỹ thuật

(tham khảo thiết kế, không phải yêu cầu) — Kết quả mong đợi dẫn theo BR/NFR; khi khác, BR/NFR thắng.

| # | Kịch bản | Kết quả mong đợi | Dẫn |
| --- | --- | --- | --- |
| K-01 | Nhóm 4 thành viên chạy trọn phiên 25 phút, không ai rời app | Mọi người COMPLETED, phiên không `forfeited`, mỗi người +10 Coins (trong trần ngày), chuỗi +1 | BR-23, BR-24, D-09, NFR-07 |
| K-02 | Một máy rời app > 3 giây | Người đó EXITED; phiên vẫn chạy; `forfeited = true`; chủ nhóm và thành viên ngoài phiên (app nền/khóa) nhận push có tên ≤ 5 giây p95; người trong phiên đang mở app nhận `MEMBER_EXITED` + `SESSION_FORFEITED` qua socket ≤ 2 giây; người trong phiên đang khóa màn hình **không** nhận push, mở khóa thấy banner (BR-82); cuối phiên mọi người 0 Coins, ngắt chuỗi | BR-14, BR-27, BR-35, BR-37, BR-38, NFR-01, NFR-02 |
| K-03 | Rời app rồi quay lại trong 3 giây | Về FOCUSING, ghi `grace_recovered`, không thông báo, không `forfeited` | BR-12 |
| K-04 | Rời app lần hai sau khi đã dùng khoan hồng | EXITED ngay | BR-13 |
| K-05 | Quay lại đúng 3,000 giây | EXITED (biên nửa mở) | BR-65 |
| K-06 | Khóa màn hình/úp máy 50 phút | 0 lần bị tính thoát, 0 DISCONNECTED giả; pin ≤ 5% | BR-15, BR-66, NFR-04, NFR-08 |
| K-07 | Tắt Wi-Fi 5 giây rồi bật | Vẫn trong phiên, về trạng thái trước | BR-20 |
| K-08 | Tắt Wi-Fi ≥ 20 giây | LOST; không `MEMBER_EXITED`; người khác giữ Coins | BR-19, BR-21, NFR-23, D-19 |
| K-09 | Hai người EXITED cách nhau ≤ 100 ms | `forfeited` đặt đúng một lần, một người khởi phát (theo giờ server nhận); Coins/chuỗi xử lý đúng một lần (idempotent) | BR-31, BR-33, BR-35, BR-39 |
| K-10 | Gửi trùng `event_id` | Bỏ qua bản trùng | BR-31 |
| K-11 | Khởi động lại server giữa phiên | CANCELLED; người chưa kết thúc VOID, không phạt; người EXITED trước đó giữ ngắt chuỗi, nhận thông báo riêng | BR-22, BR-68, NFR-15 |
| K-12 | Đăng nhập máy thứ hai khi đang trong phiên | Máy thứ hai không chiếm phiên; máy đầu bị chặn đăng xuất | BR-70 |
| K-13 | Rà gói tin/log client | Không có tên app, nội dung, vị trí; không yêu cầu quyền Usage Access | BR-34, NFR-P |
| K-14 | Token hết hạn / token nhóm khác gọi tài nguyên | Ngắt/401; 403 | NFR-10, NFR-11 |
| K-15 | 100 nhóm bắt đầu cùng phút | Vào phiên ≤ 3 giây p95, lỗi < 1% | NFR-05, NFR-06 |
| K-16 | Bấm "Rời phiên" (D-29): (a) FOCUSING → xác nhận; (b) GRACE → xác nhận trước hạn 3s; (c) WAITING ở phòng chờ V-06 → xác nhận (gồm ca server nhận khi phiên đã COUNTDOWN, trước `started_at`; màn đếm ngược V-07 không có nút — T-BA-132); (d) bấm rồi hủy hộp; (e) tắt Wi-Fi rồi bấm; (f) gửi lại cùng `event_id` | (a)(b) EXITED ngay, `reason = USER_LEAVE`, không trừ lượt khoan hồng, `forfeited = true`, người khác nhận thông báo có tên như K-02; (c) ABSENT, không `MEMBER_EXITED`, `forfeited` không đổi, không vào lại được; (d) không có bản ghi, trạng thái giữ nguyên; (e) client báo "chưa rời phiên", server không có sự kiện; (f) một bản ghi duy nhất | BR-118, BR-31, BR-35, D-29, Q-149 |
