# Thiết kế 00 — Tổng quan thiết kế (Giai đoạn 3)

Ngày: 2026-10-19 · Trạng thái: Nháp, đã soát chéo và khớp 5 tệp.
Nguồn ưu tiên khi mâu thuẫn: `ba/02-so-quyet-dinh.md` (D-01…D-29) > `ba/srs/03-quy-tac.md` > `ba/srs/04-nfr-rieng-tu.md` > `ba/srs/05-tham-chieu-ky-thuat.md`.
Trong thiết kế: `schema.sql` / `02-du-lieu.md` thắng về tên bảng, cột, giá trị enum; `03-api-socket.md` thắng về tên sự kiện socket; `04-luong-trang-thai.md` theo cả hai.

---

## 1. Mục lục

| Tệp | Nội dung | Ghi chú |
| --- | --- | --- |
| `01-kien-truc.md` | C4 mức 1–2, modular monolith Node/TS, module + bảng sở hữu, job định kỳ, app Flutter, AWS (mạng, môi trường, CI/CD, bí mật, giám sát), bảo mật, ADR-01…10, DQ-01…14 | 8 dịch vụ AWS Must |
| `02-du-lieu.md` + `schema.sql` | ERD, từ điển dữ liệu 31 bảng PostgreSQL (gồm `idempotency_keys`, `job_runs` mới thêm) + 2 bảng DynamoDB, ràng buộc/trigger, hạn lưu, DQ-D01…10 | DDL **chưa chạy thử** |
| `03-api-socket.md` + `openapi.yaml` | Nguyên tắc API (P1–P14), mã lỗi, ánh xạ trường API ↔ cột (§1.2), endpoint → US/AC/màn, hợp đồng Socket.io, push SNS, DQ-A01…13 | openapi lint đạt |
| `04-luong-trang-thai.md` | Máy trạng thái phiên, thành viên, nhóm, khiếu nại; 12 sequenceDiagram; ánh xạ sơ đồ → BR/US/K-xx; DQ-F01…13 | Mermaid **chưa render** |

## 2. Tóm tắt ADR (01 §6)

| ADR | Quyết định | Trạng thái |
| --- | --- | --- |
| ADR-01 | Modular monolith Node.js/TypeScript (REST + Socket.io + cron) trên 1 EC2; trạng thái phiên trong bộ nhớ | Đề xuất |
| ADR-02 | Server là nguồn sự thật về thời gian và trạng thái; idempotent theo `event_id` | Theo BR-03, BR-31, BR-33 |
| ADR-03 | RDS cho lõi, sổ cái, nhật ký cá nhân (mã hóa), nhật ký truy cập; DynamoDB chỉ cho log sự kiện phiên (TTL) | Theo D-04; lệch 05 §3.3 ở DQ-D04, DQ-D06 |
| ADR-04 | Cron trong tiến trình + khóa tư vấn PostgreSQL + `job_runs` chạy bù | Đề xuất |
| ADR-05 | Cognito chỉ cho danh tính (+ nhóm `admin`); vai trò chủ nhóm/thành viên tra RDS | Theo D-10 |
| ADR-06 | Thông báo 2 kênh: socket khi mở app, SNS push khi không mở app và không ở phiên chưa kết thúc | Theo BR-27, BR-82 |
| ADR-07 | Flutter + Riverpod, plugin vòng đời native từ spike T-01 | Theo D-07; Riverpod chờ DQ-01 |
| ADR-08 | Build/ký iOS trên GitHub Actions macOS, đẩy TestFlight | Theo D-26 |
| ADR-09 | TLS bằng Nginx + Let's Encrypt trên EC2, không ALB/NAT ở MVP | Đề xuất; cần tên miền (DQ-02) |
| ADR-10 | Web Admin là SPA tĩnh [Should]; MVP dùng seed | Theo backlog |

## 3. Lệch đã sửa trong lần soát này

| # | Lệch | Sửa ở | Theo |
| --- | --- | --- | --- |
| 1 | `duration_min` trong openapi là `integer ≥ 1` | `DurationMin enum [25, 50]` dùng cho đặt lịch và sửa phiên | BR-02 (giải DQ-A05) |
| 2 | Trạng thái nhóm API `ACTIVE/DISSOLVED/SUSPENDED` | `GroupStatus` = ACTIVE/SCHEDULE_SUSPENDED/DISSOLVING/DISSOLVED; sơ đồ 1.3 ghi kèm mã | schema `group_status` |
| 3 | Trạng thái khiếu nại API `OPEN/…` | `AppealStatus` = PENDING/IN_REVIEW/ESCALATED/EXEMPTED/REJECTED; sơ đồ 1.4 + 2.10 ghi mã | schema `appeal_status` |
| 4 | Món Shop: `type FRAME`, `available`, giá ≥ 0; thiếu loại TITLE khi trang bị | `kind` (AVATAR_FRAME/BACKGROUND/TITLE), `status` ON_SALE/HIDDEN, giá 10–1000, thêm `title_item_id` | schema `item_kind`, `item_status`; BR-93, BR-95 |
| 5 | `cancel_reason` API `OWNER_CANCELLED/OUTAGE`; payload socket `"OUTAGE"` | `SessionCancelReason` = enum schema; socket dùng `SERVER_OUTAGE`, `OWNER_CANCEL`… | schema `session_cancel_reason` |
| 6 | Sổ Coins API `PURCHASE`, `EXEMPTION_REFUND` | `SESSION_REWARD/SHOP_PURCHASE/ADMIN_ADJUST`; hoàn miễn trừ = SESSION_REWARD `reason = APPEAL_RESTORE` | schema `ledger_type`, BR-88 |
| 7 | Báo cáo tháng `READY/NO_DATA` | `PENDING/GENERATED/FAILED` | schema `report_status` |
| 8 | Tên trường API khác cột: `purpose`, `text`, `reason_code`, `note`, `start_time` (PATCH), `purchased_at`, `resource`, `recurrence.rule/until` | `report_purpose`, `body`, `category`, `decision_reason`, `started_at`, `acquired_at`, `object_type`, `weekdays/end_date`; bảng ánh xạ 03 §1.2 | schema / 02 (giải DQ-A02) |
| 9 | Độ dài: tên nhóm 50, mục đích 300, nhật ký 2000 | 60 / 500 / 5000 | schema CHECK; BR-100 |
| 10 | Nhật ký truy cập ghi "DynamoDB" (01, 03 P12); nhật ký cá nhân "DynamoDB" (01) | PostgreSQL `access_logs`, `journals`; C4, module, ADR-03 cập nhật | 02 §4.3, DQ-D04, DQ-D06 |
| 11 | `access_logs.object_type` thiếu loại chủ nhóm xem (giải trình, điểm danh) | Thêm `EXPLANATION`, `ATTENDANCE` ở schema, 02, openapi | BR-73 |
| 12 | Tên bảng 01 không có trong schema: `config_params`, `devices`, `invites`, `streaks`, `purchases`, `notification_log` | `system_params`, `device_tokens`, `group_invites`/`invite_attempts`, `users.*_streak` + `achievement_log`, `user_items`, `notifications` | schema |
| 13 | Thiếu bảng cho idempotency REST và `job_runs` (01, 03 P6 dùng nhưng schema không có) | Thêm `idempotency_keys`, `job_runs` vào schema + 02 §3.22b | 03 P6, 01 §2.4 |
| 14 | POST/DELETE thiếu `Idempotency-Key`: đổi mã mời, thêm món Shop, xóa nhật ký | Đã thêm | 03 P6 |
| 15 | Sĩ số: chỉ `maximum: 10` ở một chỗ | `MemberCount` 0–10, ghi rõ không gồm chủ nhóm, dùng ở mọi view nhóm/đồng ý | BR-74, D-02, D-25 |
| 16 | 04 dùng tên sự kiện kiểu spike (`eventId`, `graceDeadlineServerTs`, `startedAtServerTs`, "hỏi tiền cảnh"), gửi `session:state EXITED` cho người thoát | Theo 03 §3: `event_id`, `grace_deadline`, `session:countdown {countdown_starts_at, started_at}`, `member:state`, ack; bỏ sự kiện "hỏi tiền cảnh" | 03-api-socket |
| 17 | `SESSION_FORFEITED` vẽ như sự kiện riêng ở 04 | Một `MEMBER_EXITED` có trường `forfeited` (gộp); hộp thông báo vẫn giữ `type` để lọc | BR-38 (giải DQ-A09) |
| 18 | `EXEMPTION_GRANTED`: 03 chỉ gửi người được miễn, 04 gửi cả chủ nhóm; payload có `coins_refunded` | Hai bản: bản cho người được miễn có Coins; bản đính chính cho người khác (gồm chủ nhóm) **không** Coins | BR-53, D-12; Q-138 vẫn Chờ |
| 19 | Hủy phiên không do sự cố thiếu mã thông báo (DQ-F09) | Dùng `SESSION_CANCELLED` + `reason` theo `session_cancel_reason` | 03 §3.3 |
| 20 | DQ-A01 đề xuất "EC2 sau ALB" trái ADR-09 | Ghi theo ADR-09 (Nginx, ALB là Should) | ADR-09 |
| 21 | 01 §3.4: mọi sự kiện mất mạng xếp hàng gửi lại | Trừ `session:leave` (không xếp hàng) | D-29, BR-118 |
| 22 | Sơ đồ nhóm dùng `locked_at` | `groups.suspended_at` | schema |

Đã kiểm, không lệch: enum `session_status` (SCHEDULED/COUNTDOWN/ACTIVE/COMPLETED/CANCELLED, không FAILED) và `member_state` giống nhau ở schema, openapi, sơ đồ 1.1/1.2; mọi `*OwnerView`, `PublicUser`, `ReportRow*`, `SessionMemberOwnerRow`, view `owner_session_member_view`, `monthly_report_rows` (CHECK cấm khóa coins/streak) không có Coins/chuỗi; `PublicProfile.shown_streak` luôn null khi người gọi là chủ nhóm (D-12); trigger chặn chủ nhóm là thành viên/người trong phiên (D-25); trần 10 bằng trigger (BR-74).

## 4. Câu hỏi thiết kế (đã loại trùng)

Ký hiệu cột "Ai chốt": **ND** = Người dùng (nghiệp vụ, quyền riêng tư, chi phí); **KT** = Nhóm kỹ thuật. ★ = **ND phải chốt trước khi code Sprint 1**.

### 4.1 Đã giải (không cần chốt)

| Mã | Lý do |
| --- | --- |
| DQ-A01 | Lệch tài liệu: đã ghi theo ADR-09. Phần tên miền gộp vào DQ-02 |
| DQ-A02 | Lệch tài liệu: tên trường API đã đổi theo schema (03 §1.2) |
| DQ-A05 | Lệch tài liệu: BR-02 đã cố định {25, 50}; openapi đã sửa |
| DQ-A08 | Trùng DQ-F04 — gộp vào DQ-F04 |
| DQ-A09 | BR-38 bắt buộc "một thông báo" → gộp `forfeited` trong `MEMBER_EXITED` |
| DQ-A13 | Trùng DQ-F08 — gộp vào DQ-F08 |
| DQ-F09 | Dùng `SESSION_CANCELLED` có `reason` (03 §3.3); không cần mã mới |

### 4.2 Còn chờ — 41 câu

| Mã | Câu hỏi | Đề xuất | Ảnh hưởng | Ai chốt | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| DQ-01 | Riverpod hay Bloc | Riverpod | Cấu trúc app Flutter | KT | Chờ |
| ★ DQ-02 | Tên miền cho API/WSS: mua tên miền hay DNS miễn phí | Mua tên miền rẻ, DNS của nhà đăng ký | TLS Let's Encrypt, deploy staging, chi phí | ND | Chờ |
| DQ-03 | Mở phiên: cron 30 s + bộ hẹn giờ hay cron mỗi phút | Cron 30 s + bộ hẹn giờ (sai số < 1 s) | Độ chính xác BR-04, BR-63 | KT | Chờ |
| DQ-04 | Amplify Auth hay `amazon_cognito_identity_dart_2` | Amplify Auth, kiểm kích thước app | Đăng nhập Sprint 1 | KT | Chờ |
| DQ-05 | Parameter Store hay Secrets Manager | Parameter Store ở MVP | Chi phí, NFR-13 | KT | Chờ |
| DQ-06 | Staging dùng chung instance RDS? Dựng khi nào | Chung instance, DB riêng; dựng từ Sprint 3 | Chi phí, thử tải | KT | Chờ |
| DQ-07 | Terraform hay CDK | CDK TypeScript | Hạ tầng dạng mã | KT | Chờ |
| DQ-08 | `drift` hay `hive`; có xếp hàng ghi offline | `drift`, không xếp hàng ghi | Cache app | KT | Chờ |
| DQ-09 | Prisma / Drizzle / Kysely | Drizzle hoặc Kysely + SQL migration (`schema.sql`) | Truy cập DB, migration | KT | Chờ |
| DQ-10 | Android Foreground Service trong phiên | Chờ spike T-01 trên ≥ 2 hãng | Độ tin cậy phát hiện rời app | KT | Chờ |
| DQ-11 | Host Web Admin | Nginx trên EC2 | Should | KT | Chờ |
| DQ-12 | Khóa mã hóa nhật ký: KMS CMK hay Parameter Store | KMS CMK, chỉ role EC2 | NFR-P05 (gộp phần "nơi lưu" của DQ-D06) | KT | Chờ |
| DQ-13 | Đổi tham số khi phiên đang chạy | Chụp tham số lúc mở phiên, áp phiên sau (gộp DQ-D07 cho trần ngày: áp dòng ghi sau thời điểm đổi) | Engine phiên, sổ cái | KT | Chờ |
| DQ-14 | Chặn deploy khi có phiên chạy | Bước CI gọi endpoint đếm phiên | BR-22, NFR-15 | KT | Chờ |
| DQ-D01 | Trigger trong CSDL cho trần 10 / D-21 | Giữ cả ứng dụng + trigger | `schema.sql` | KT | Chờ |
| ★ DQ-D02 | `session_members` có xóa sau 13 tháng không | Xóa sau 13 tháng; điểm danh/chuỗi giữ đến xóa tài khoản | Nội dung màn đồng ý V-05 (Sprint 1), job purge | ND | Chờ |
| DQ-D03 | Ngoại lệ `dropit.purge` cho sổ cái chỉ-thêm khi xóa tài khoản | Chấp nhận, vai trò CSDL riêng, ghi `admin_audit` | BR-72, BR-44 | KT | Chờ |
| DQ-D04 | Nhật ký truy cập ở PostgreSQL thay DynamoDB | Giữ PostgreSQL | ADR-03 (đã áp vào thiết kế) | KT | Chờ |
| DQ-D05 | Không bảng `streaks` | Giữ cột trên `users` + `achievement_log` | BR-92 (đã áp) | KT | Chờ |
| DQ-D06 | Nhật ký cá nhân ở PostgreSQL thay DynamoDB | Giữ PostgreSQL + mã hóa phong bì KMS | ADR-03 (đã áp) | KT | Chờ |
| DQ-D07 | Đổi `coins_daily_cap` giữa ngày | Gộp vào DQ-13 | — | KT | Chờ (gộp) |
| DQ-D08 | CHECK cứng 12 tuần ở `schedules` vs tham số Admin | Giữ 12 là trần tối đa | Lịch lặp (Should) | KT | Chờ |
| DQ-D09 | Danh sách lý do tạm dừng chính thức | 4 mục tạm trong `system_params` | Tạm dừng (Should, Sprint 3) | ND | Chờ |
| ★ DQ-D10 | Độ dài: tên nhóm 1–60, khiếu nại ≤ 1000, báo cáo lạm dụng ≤ 1000 (chưa có BR) | Giữ như schema | Tạo nhóm Sprint 1, validate API | ND | Chờ |
| DQ-A03 | Chặn bản app cũ (426) | Có, theo `X-App-Version` | Client | KT | Chờ |
| DQ-A04 | Ngưỡng rate limit | 60/phút, 10/phút ghi, 20 sự kiện/10 s socket | NFR | KT | Chờ |
| DQ-A06 | Tắt long-polling | Có | Pin, NFR-08 | KT | Chờ |
| ★ DQ-A07 | `session:resume` từ thiết bị khác khi DISCONNECTED | Không — chỉ cùng `device_id` | BR-70, một thiết bị/phiên; handshake socket T-02 | ND | Chờ |
| DQ-A10 | Thông báo không liên quan phiên khi người nhận đang trong phiên: hoãn hay gửi | Hoãn đến sau phiên (mở rộng BR-82) — cần tạo Q- | BR-82 | ND | Chờ |
| DQ-A11 | Giữ `event_id` C→S bao lâu | Đến hết phiên + 1 giờ, trong bộ nhớ | BR-31 | KT | Chờ |
| DQ-A12 | Đồng ý lại dùng chung `POST /consent` không mã mời | Có, server kiểm `group_members` | US-01.06 | KT | Chờ |
| ★ DQ-F01 (+F02) | Khi nào tạo INVITED, ai được INVITED; người vào nhóm/chưa đồng ý lại sau khi đã SCHEDULED | Tạo INVITED tại `started_at` cho thành viên tại lúc đó; chưa đồng ý lại → bị chặn BR-06 rồi ABSENT | `session_members`, "lượt dự kiến" báo cáo, luồng 2.2 | ND | Chờ |
| DQ-F03 | Hỏi trạng thái tiền cảnh tại `started_at` | Dùng trạng thái cuối nhận trong COUNTDOWN, không sự kiện hỏi (đã vẽ ở 2.2) | BR-64 | KT | Chờ |
| DQ-F04 (+A08) | Server khởi động lại giữa phiên: ai đặt CANCELLED, lấy EXITED từ đâu | Ghi EXITED/`forfeited` xuống RDS ngay khi xảy ra; khi khởi động quét phiên COUNTDOWN/ACTIVE → BR-22 | BR-22, BR-68, ADR-01 | KT | Chờ |
| DQ-F05 | Nối lại từ DISCONNECTED (trước đó PAUSED) khi hạn tạm dừng đã hết | Áp BR-18 lúc nối lại | Máy trạng thái 1.2 | ND | Chờ |
| DQ-F06 | WAITING mất kết nối: phát hiện bằng gì, nối lại sau `started_at` | Chỉ dùng socket đóng; nối lại muộn xử lý như vào muộn nếu US-03.11 có | Q-153 | ND | Chờ (theo Q-153) |
| DQ-F07 | `lock_reclassified` (GRACE → FOCUSING khi tín hiệu khóa đến trễ) | Chờ S-12 của spike | Q-151, rủi ro lách luật | KT (đo) → ND (Q-151) | Chờ |
| DQ-F08 (+A13) | Tên sự kiện spike lệch hợp đồng (`member:join`, `session:end`) | Chuẩn hóa theo 03 §3 khi viết T-02; giữ `clock:ping` (đã có ở 03) | Code spike | KT | Chờ |
| DQ-F10 | Thiếu ca kiểm thử K-xx cho nhóm, khiếu nại, báo cáo, phòng chờ, tạm dừng | Bổ sung K-17+ | Kế hoạch kiểm thử | KT | Chờ |
| DQ-F11 | `SESSION_RESULT` push cho ai | Socket nếu mở app; push cho COMPLETED/EXITED/LOST không mở app; ABSENT không push | BR-91 | ND | Chờ |
| DQ-F12 | Chốt phiên khi còn DISCONNECTED tại `ends_at` | Chốt tại `ends_at + disconnect_hold_s` | Transaction cuối phiên, NFR-07 | KT | Chờ |
| DQ-F13 | Chủ nhóm thấy PAUSED/LOST/vào muộn trước `ends_at`? | Chỉ sau `ends_at`; trong phiên chỉ trạng thái phiên + EXITED (đã áp ở `SessionOwnerView`) | BR-116, riêng tư | ND | Chờ |

Đếm: 50 mã gốc (14 + 10 + 13 + 13) → 7 đã giải/gộp (§4.1), DQ-F02 gộp vào DQ-F01, DQ-D07 gộp vào DQ-13 → **41 câu còn Chờ** (42 dòng bảng, kể cả dòng gộp DQ-D07). Phân bổ: KT 30, ND 11 (DQ-F07: KT đo rồi ND chốt qua Q-151).

### 4.3 Người dùng phải chốt trước khi code Sprint 1 (5 câu)

1. **DQ-02** — Tên miền (chi phí, chặn TLS và deploy).
2. **DQ-D02** — Hạn lưu kết quả phiên từng người (phải in đúng trên màn đồng ý V-05, Sprint 1).
3. **DQ-D10** — Giới hạn độ dài tên nhóm/khiếu nại/báo cáo lạm dụng (validate ở tạo nhóm Sprint 1).
4. **DQ-F01 (+F02)** — Thời điểm và đối tượng tạo INVITED (quyết định cách ghi `session_members`).
5. **DQ-A07** — Nối lại phiên chỉ từ cùng thiết bị (handshake socket T-02, BR-70).

Ngoài DQ, thiết kế đang giả định theo đề xuất của **Q-141** (sĩ số không gồm chủ nhóm), **Q-149**, **Q-153**, **Q-138** — các câu này nằm trong sổ quyết định, trạng thái Chờ; nếu chốt khác thì phải sửa `MemberCount`, luồng 2.6, cạnh WAITING → ABSENT và bản đính chính `EXEMPTION_GRANTED`.

## 5. Cổng G3 (sẵn sàng code)

| Hạng mục | Kết quả | Lý do |
| --- | --- | --- |
| Kiến trúc | **Đạt** | C4, module + bảng sở hữu, nguồn sự thật, job, ADR-01…10 đầy đủ; tên bảng đã khớp schema. Còn DQ-01…14 ở mức KT, có đề xuất mặc định để bắt đầu |
| ERD + DDL | **Đạt** | `schema.sql` áp thành công trên PostgreSQL 16 (docker, DB sạch). `tests/schema_test.sql`: **53 PASS / 0 FAIL** (25/50 phút, `ends_at`, chồng phiên BR-78, D-21, D-25, trần 10 BR-74, sổ cái chỉ-thêm/chống trùng/không âm/trần 100, trạng thái cuối BR-32, bản chụp báo cáo BR-56, không Coins/chuỗi BR-53, view chủ nhóm). Lần chạy đầu 8 FAIL thật ở báo cáo tháng → đã sửa: trigger `monthly_reports_freeze` khóa mọi cột (trừ `emailed_at`, `pdf_key`, `attempts`) và chặn DELETE ngoài job hết hạn; thêm trigger `monthly_report_rows_freeze`; thêm CHECK `mr_no_coins_streak` cho `group_summary`. Còn ★ DQ-D02, DQ-D10, DQ-F01 |
| API REST | **Đạt** | `openapi.yaml` lint lại bằng `@redocly/cli@1.34.5`: hợp lệ, 0 lỗi, 0 cảnh báo. Enum, tên trường, `duration` {25, 50}, sĩ số, idempotency khớp schema/BR. Chưa có kiểm thử hợp đồng tự động |
| Socket | **Đạt** | Hợp đồng sự kiện C→S / S→C, ack, `event_id`, nối lại, mã lỗi; 01 và 04 dùng đúng tên. Còn ★ DQ-A07 |
| Luồng / máy trạng thái | **Đạt** | Nội dung khớp BR/D- và tên ở 03, schema. Render bằng mermaid-cli 12.0.0: **22/22 sơ đồ** (01: 5, 02: 1, 04: 16) không lỗi cú pháp, SVG ở `render/` (danh sách `render/README.md`). Còn ★ DQ-F01 |
| CI | **Đạt** (chưa chạy trên GitHub) | `.github/workflows/backend-ci.yml`: 3 job `openapi` (redocly 1.34.5), `schema` (service `postgres:16`, áp schema, chạy `schema_test.sql`, fail nếu có dòng FAIL), `mermaid` (render kiểm cú pháp); kích hoạt khi push/PR chạm `design/**`. Đã kiểm cục bộ: YAML hợp lệ (yaml-lint, PyYAML), các lệnh của từng job chạy đúng trên máy/container. **Chưa chạy trên GitHub Actions** (thư mục chưa là repo git) |
| Bảo mật & riêng tư | **Đạt** | Không endpoint đọc nội dung máy/app khác; Coins/chuỗi không có trong mọi view chủ nhóm (`additionalProperties: false`, view CSDL, CHECK `metrics`); nhật ký mã hóa phong bì KMS; `access_logs`; OIDC cho deploy; bí mật ở Parameter Store. Chờ DQ-12 (khóa) — mặc định KMS |

**Kết luận G3: Đạt có điều kiện.** Đã xong (2) chạy thử `schema.sql` + kiểm thử ràng buộc (53/53 PASS) và render 22/22 sơ đồ; (3) đã có workflow `backend-ci` (kiểm cục bộ, chờ lần chạy đầu trên GitHub). Còn lại duy nhất (1): người dùng chốt 5 câu ★ ở §4.3 trước khi bắt đầu Sprint 1.
