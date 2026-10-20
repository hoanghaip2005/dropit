# Đối chiếu 44 story Must với code (2026-10-20)

Phạm vi: 44 US Must theo `ba/03-truy-vet.md`, đối chiếu với `backend/src` (+ `backend/README.md`) và `app/lib` (+ `app/README.md`).
Chỉ đọc, không sửa code. Bằng chứng lấy từ route đã đăng ký, service, chuỗi giao diện và các mục "Giả định" / "Phát hiện" trong hai README.
AC cần máy thật (NFR-04, NFR-08) **không** tính là thiếu code; chúng thuộc T-01 (spike/kiểm thử máy thật).

Trạng thái:
- **Đủ**: mọi AC kiểm được ở local đã có trong code.
- **Thiếu một phần**: có luồng chính, còn AC thiếu hoặc làm lệch quy tắc.
- **Chưa có**: không có route/màn (hoặc chỉ có placeholder "Sắp có").
- **Phụ thuộc AWS**: phần còn thiếu chủ yếu cần Cognito, push FCM/APNs (SNS) hoặc SES.

Ước lượng: S ≤ 0,5 ngày · M 1–2 ngày · L > 2 ngày (một người, gồm test).

## Tổng hợp

| Trạng thái | Số US |
| --- | --- |
| Đủ | 16 |
| Thiếu một phần | 19 |
| Chưa có | 4 |
| Phụ thuộc AWS | 5 |
| **Tổng** | **44** |

## 1. Phần làm được ở local

| US | Trạng thái | AC thiếu / sai | Nơi cần sửa | Ước |
| --- | --- | --- | --- | --- |
| US-01.02 Đăng xuất | Thiếu một phần | AC-01.02.3: chưa khóa nút Đăng xuất khi đang FOCUSING (BR-70). AC-01.02.1/.2 phần thu hồi refresh token và hủy push → nhóm AWS | app `features/profile/profile_screens.dart` (đọc trạng thái `session_controller`) | S |
| US-01.03 Hồ sơ cá nhân | Thiếu một phần | AC-01.03.1, .3: chưa có `GET /users/{id}/public-profile` (người cùng nhóm xem; ngoài nhóm → 403). Avatar chưa cắt vuông, thu nhỏ, xóa EXIF | backend `modules/profile/routes.ts` (route mới + kiểm cùng nhóm); app màn hồ sơ công khai | M |
| US-01.05 Đồng ý minh bạch | Thiếu một phần | AC-01.05.5: nút "Đồng ý" chưa khóa đến khi cuộn hết nội dung (app dùng công tắc từng mục, mặc định tắt — đúng phần "không đánh dấu sẵn") | app `features/groups/group_screens.dart` (ConsentScreen) | S |
| US-01.07 Rút đồng ý / rời nhóm | **Chưa có** | AC-01.07.1–7. Không có API rời nhóm; app V-21 là "Sắp có". Thiếu xử lý WITHDRAWN trong phiên đang chạy (trước/sau `forfeited_at`, BR-26, BR-37, D-23), bỏ INVITED ở phiên SCHEDULED, cảnh báo "Nhóm dưới 4 người" | backend `modules/groups/service.ts` + `sessions/manager.ts`/`engine.ts` (sự kiện WITHDRAWN); app thay placeholder `/leave-group/:gid` | L |
| US-01.08 Dữ liệu của tôi | **Chưa có** | AC-01.08.1–5. Không có `/me/data`; app V-25 là "Sắp có" | backend route mới (gom kết quả phiên, sự kiện thoát, giải trình, điểm danh của mình); app màn V-25 | M |
| US-02.06 Nhóm của tôi | Thiếu một phần | AC-02.06.1: `/me/groups` không trả trạng thái nhóm. AC-02.06.6: thiếu tỉ lệ hoàn thành tháng hiện tại riêng từng nhóm; nhóm sở hữu đang sắp theo `created_at`, chưa theo tên (BR-117) | backend `modules/groups/service.ts` (`myGroup`, `listMyGroups`); app danh sách nhóm | S |
| US-02.08 Chủ nhóm xóa thành viên | **Chưa có** | AC-02.08.1–6. Không có `DELETE /groups/{id}/members/{user_id}`; chưa có hiệu lực sau `ends_at` khi đang trong phiên (BR-77), chưa có thông báo cho người bị xóa | backend `modules/groups` + kiểm phiên đang chạy; app màn thành viên (V-43) | M |
| US-02.11 Sửa / hủy lịch | **Chưa có** | AC-02.11.1–5. Chỉ có POST/GET lịch; không có PATCH/DELETE, không chặn từ mốc COUNTDOWN (`started_at − 5s`), không thông báo TV | backend `modules/schedules/routes.ts` + báo `sessions/manager.ts` hủy runtime; app màn lịch chủ nhóm | M |
| US-03.01 Vào phòng chờ | Thiếu một phần | AC-03.01.4 (CN hủy khi TV đang WAITING → VOID + thông báo) chưa kiểm được vì chưa có hủy lịch (phụ thuộc US-02.11). AC-03.01.1–3, .5 có (`CONSENT_REQUIRED`, `OWNER_CANNOT_JOIN_SESSION`, `ALREADY_IN_OTHER_SESSION`) | backend `sessions/manager.ts` (hủy runtime có người WAITING) | S |
| US-04.05 Giải trình | Thiếu một phần | AC-04.05.5: chưa lưu lịch sử bản cũ khi sửa (không có bảng/cột). App không đọc lại được giải trình của mình (không có API GET của chính mình). Cần xác nhận AC-04.05.3 trả 400 cho loại sự kiện không phải EXITED | backend `modules/appeals/service.ts` + schema (bảng lịch sử); route `GET /sessions/{id}/explanation` của mình; app `appeal_screens.dart` | M |
| US-04.06 CN xem giải trình | Thiếu một phần | AC-04.06.6: chưa có nhãn "đã sửa lúc …". `owner-detail` chỉ trả `has_explanation` (app phải mở màn riêng — chấp nhận được) | backend `appeals/service.ts` (trả `edited_at`); app `appeal_screens.dart` | S |
| US-05.03 Chuỗi | Thiếu một phần | AC-05.03.7 (nhánh WITHDRAWN), .14, .15: chưa có WITHDRAWN nên chưa kiểm được mốc `forfeited_at` (phụ thuộc US-01.07). Các AC còn lại có (phát lại chuỗi, test unit) | backend `achievements/service.ts` khi làm US-01.07 | S |
| US-05.04 Màn chuỗi | Thiếu một phần | AC-05.04.2: chưa có trạng thái "Hôm nay chưa cộng chuỗi" | app `features/achievements/achievements_screen.dart` (cần cờ "đã +1 hôm nay" từ `/me/achievements`) | S |
| US-06.02 Coins của tôi | Thiếu một phần | AC-06.02.5: mất mạng chưa hiện số dư cũ kèm "có thể chưa cập nhật" (đang hiện màn lỗi). AC-06.02.6: chưa có câu "đã đạt trần, phiên tiếp theo hôm nay không cộng Coins" ở màn Coins | app `profile_screens.dart` (CoinsScreen), bộ nhớ đệm provider | S |
| US-06.04 Mua món | Thiếu một phần | AC-06.04.9: màn xác nhận chưa ghi "Không hoàn Coins" | app `features/shop/shop_screen.dart` | S |
| US-06.05 Trang bị | Thiếu một phần | AC-06.05.5, .6: người cùng nhóm / người ngoài xem hồ sơ của tôi — chưa có API hồ sơ công khai (cùng việc với US-01.03) | như US-01.03 | S (gộp US-01.03) |
| US-07.01 Màn hồ sơ | Thiếu một phần | AC-07.01.3: mất mạng chưa hiện bản lưu gần nhất kèm "Chưa cập nhật" | app `profile_screens.dart` + lưu đệm cục bộ | S |
| US-07.04 Hiển thị đồ trang bị | Thiếu một phần | AC-07.04.1: người cùng nhóm chưa xem được hồ sơ có khung/hình nền (cần hồ sơ công khai) | như US-01.03; app dùng `FramedAvatar` ở danh sách thành viên | S (gộp US-01.03) |
| US-07.07 Viết nhật ký | Thiếu một phần | AC-07.07.6: mất mạng chưa giữ bản nháp + "Chưa lưu lên máy chủ" / "Thử lại". Câu lỗi AC-07.07.2 "Nhật ký trống" chưa thấy ở app | app `features/journal/journal_screens.dart` | S |
| US-08.01 Tạo báo cáo tháng | Thiếu một phần | AC-08.01.8: nhóm ĐÃ GIẢI TÁN — `roleIn` trả 404 nên người từng là chủ chưa xem được báo cáo cuối (README đã ghi). AC-08.01.9: cron thử lại mỗi giờ tối đa 4 lượt nhưng chưa chặn "không quá 06:00" | backend `modules/reports/*`, `groups/service.ts` (`roleIn`), `jobs/cron.ts` | M |
| US-08.02 CN xem báo cáo | Thiếu một phần | AC-08.02.3: chưa trả nhãn "thêm sau khi tạo báo cáo" dù có cột `explanations.added_after_report` (bị chặn bởi `ReportRowOwnerView` additionalProperties: false — cần sửa `design/openapi.yaml`). Lưu ý: khi **sửa** giải trình, code đặt `added_after_report = true` nếu đã có báo cáo, kể cả khi bản gửi đầu trước báo cáo — cần chốt quy tắc | backend `reports/routes.ts`, `appeals/service.ts`; `design/openapi.yaml`; app `report_screens.dart` | S |
| US-08.03 Báo cáo của tôi | Thiếu một phần | AC-08.03.4: sau khi rời nhóm, xem lại dòng kỳ cũ — cần kiểm lại đường `roleIn`/membership cũ (chưa có rời nhóm nên chưa kiểm được; phụ thuộc US-01.07) | backend `reports/routes.ts` | S |
| US-08.10 CN xem chi tiết phiên | Thiếu một phần | AC-08.10.8 câu "Không có ai rời app", AC-08.10.10 "Phiên đã hủy lúc hh:mm" chưa thấy ở app. AC-08.10.4 (phiên ACTIVE: chỉ sự kiện đã xác nhận) backend trả `members` rỗng + `exit_events` — cần kiểm app hiện đúng. AC-08.10.11 "Đã miễn trừ" chưa có nhãn (`appeal_status` có) | app `group_screens.dart` (màn `/owner/sessions/:sid`) | S |

### Đủ (16)

| US | Ghi chú |
| --- | --- |
| US-02.01 Tạo nhóm | Mục đích bắt buộc, tên 1–60, ≤ 10 nhóm sở hữu (BR-75), `below_minimum` |
| US-02.03 Mã mời | Đổi mã, khóa 5 lần sai/15 phút (BR-76), từ chối nhóm không HOẠT ĐỘNG, `ALREADY_IN_GROUP` (D-21), đủ 10 TV |
| US-02.10 Đặt lịch | 25/50, lead ≥ 1 phút, chống chồng (BR-78, ràng buộc DB), nhóm không HOẠT ĐỘNG bị chặn |
| US-03.02 Đếm ngược | Engine thuần + test; `/time`, `clock:ping` |
| US-03.03 Màn phiên | Lockdown đen tĩnh; AC-03.03.5 (pin) cần máy thật (T-01) |
| US-03.04 Rời app | Khoan hồng, idempotent `event_id`, `session:leave` có xác nhận; AC-03.04.5 cần máy thật |
| US-03.05 Khoan hồng 3s | Test engine biên 2,9/3,0s |
| US-03.07 Mất kết nối | DISCONNECTED/LOST, khóa màn hình không DISCONNECTED |
| US-03.08 Mất thưởng tập thể | Cờ một chiều, người khởi phát |
| US-03.10 Kết thúc phiên | ABSENT tại `started_at`, CANCELLED `NO_ATTENDEE` |
| US-05.01 Điểm danh | Theo ngày `started_at` giờ VN |
| US-05.05 Huy hiệu | Cấp một lần, nhiều mốc cùng lúc; app chưa có tiến độ phiên/giờ (không thuộc AC) |
| US-06.01 Coins thưởng | Trần 100/ngày, khóa duy nhất sổ cái, bù miễn trừ |
| US-06.03 Shop | 3 tab, ẩn món, không ngẫu nhiên (BR-121) |
| US-07.10 Nhật ký riêng tư | AES-256-GCM, CN/người khác 403. AC-07.10.5/.6 (DynamoDB, CloudWatch) kiểm lại khi lên AWS |
| US-08.08 Mục đích báo cáo | Bản chụp mục đích, `PurposeCard` ở đầu |

## 2. Nhóm Phụ thuộc AWS (5)

| US | Phần local đã có | AC chờ AWS | Dịch vụ | Ước |
| --- | --- | --- | --- | --- |
| US-01.01 Đăng ký / đăng nhập | `POST /dev/token`, `TokenVerifier` thay được | AC-01.01.1–10 (đăng ký, mã xác minh, sai mật khẩu, khóa tài khoản, refresh 60 phút, quên mật khẩu) | Cognito | L |
| US-01.04 Vai trò | AC-01.04.1–3, .5 đúng (vai trò lưu ở `groups`/`group_members`, 403 `NOT_GROUP_OWNER`) | AC-01.04.4: API quản trị theo Cognito group "admin" (chưa có `/admin/*`) | Cognito | M |
| US-03.09 Thông báo thoát | Banner trong app có tên, hộp thông báo, không gửi khi LOST/GRACE, đính chính miễn trừ | AC-03.09.3, .10: push hệ thống cho người không ở trong phiên (`ConsoleNotificationSender` chỉ log) | SNS → FCM/APNs | M |
| US-04.01 Thông báo cho chủ nhóm | Lưu hộp thông báo, room `user:{id}`, CN nhiều nhóm nhận đúng một bản | AC-04.01.1, .6 (push + thử lại BR-81), .7 (không push lúc khóa màn hình — cần kiểm trên thiết bị) | SNS → FCM/APNs | M |
| US-08.07 Email tóm tắt | Ghi `outbox/*.eml`, không đính kèm, không ảnh theo dõi, link `dropit://` | AC-08.07.1, .3, .5 (gửi thật ≤ 1 giờ, thử lại 3 lần/24 giờ), .7 (deep link + đăng nhập) | SES (+ Cognito cho .7) | M |

Phần AWS còn kéo theo: US-01.02 (thu hồi refresh token, hủy đăng ký push), US-07.10 (KMS thay `JOURNAL_MASTER_KEY`, rà DynamoDB/CloudWatch), avatar lên S3.

## 3. Việc làm local theo thứ tự ưu tiên

1. **US-02.11 Sửa / hủy lịch** (M) — mở khóa luôn AC-03.01.4; chặn từ mốc COUNTDOWN; thông báo TV.
2. **US-01.07 Rút đồng ý / rời nhóm** (L) — WITHDRAWN trong phiên theo `forfeited_at` (D-23, BR-37), bỏ INVITED; mở khóa AC-05.03.14/.15 và AC-08.03.4. Quyền riêng tư cứng (GĐ1 §6) nên ưu tiên cao.
3. **US-02.08 Chủ nhóm xóa thành viên** (M) — dùng chung phần dọn INVITED / hiệu lực sau `ends_at` với việc 2.
4. **Hồ sơ công khai `GET /users/{id}/public-profile`** (M) — đóng một lượt US-01.03, US-06.05, US-07.04.
5. **US-01.08 Dữ liệu của tôi** (M) — thay placeholder V-25; đối chiếu đủ trường với `owner-detail` và báo cáo (NFR-P03).
6. **US-08.01 + US-08.02 báo cáo** (M + S) — `roleIn` cho nhóm ĐÃ GIẢI TÁN (BR-62, BR-103); trả nhãn "thêm sau khi tạo báo cáo" (sửa openapi) và chốt quy tắc khi sửa giải trình; cron dừng sau 06:00.
7. **US-04.05 / US-04.06 giải trình** (M + S) — lưu lịch sử bản cũ, API đọc giải trình của mình, nhãn "đã sửa lúc".
8. **US-02.06 Nhóm của tôi** (S) — trạng thái nhóm, tỉ lệ hoàn thành tháng từng nhóm, sắp theo tên (BR-117).
9. **Gói app nhỏ** (S mỗi việc): khóa Đăng xuất khi FOCUSING (AC-01.02.3); khóa nút Đồng ý tới khi cuộn hết (AC-01.05.5); "Hôm nay chưa cộng chuỗi" (AC-05.04.2); "Không hoàn Coins" (AC-06.04.9); câu "Không có ai rời app" / "Phiên đã hủy lúc" / "Đã miễn trừ" (US-08.10).
10. **Ngoại tuyến** (S mỗi việc): bản đệm hồ sơ + "Chưa cập nhật" (AC-07.01.3), số dư Coins cũ (AC-06.02.5), nháp nhật ký (AC-07.07.6).

Sau đó mới đến nhóm AWS: Cognito (US-01.01, US-01.04) → SNS push (US-03.09, US-04.01) → SES (US-08.07).

## Giới hạn của lần đối chiếu

- Phần app được kiểm bằng route và chuỗi giao diện (grep), chưa chạy từng màn; các AC ghi "cần kiểm" nên chạy lại trên emulator.
- Không chạy `npm test` / `flutter test` trong lần này; dựa vào kết quả README ngày 2026-10-19 (75 ca backend qua).
