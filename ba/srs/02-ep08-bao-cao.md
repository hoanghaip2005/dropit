# EP-08 Báo cáo tháng

Nguồn: GĐ1 §4.8, §6, §8, §11; D-03, D-05, D-10, D-11, D-12, D-13, D-21, D-22, D-24 · MoSCoW: Must (tạo tự động, xem theo nhóm, dòng của mình, email tóm tắt, mục đích, chi tiết phiên cho chủ nhóm — US-08.10); Should (tổng nhóm cho thành viên, so sánh, tải PDF trong app, kỳ trống — D-13, D-24) · Phụ trách: (chưa giao)

Cập nhật 2026-10-07 theo D-21 (thành viên thuộc tối đa 1 nhóm; báo cáo luôn theo **một** nhóm/thành viên, không có màn gộp mọi nhóm), D-22 (báo cáo có tên người thoát ở từng phiên; không hiện tổng số lần thoát của người khác cho thành viên — đề xuất Q-137), D-24 (email tóm tắt, không PDF; PDF chỉ tải trong app, Should), T-BA-57.

Cập nhật 2026-10-19 theo D-25 (chủ nhóm không tham gia phiên → không có dòng báo cáo: AC-08.01.7, AC-08.02.7, .8), Q-141 (sĩ số không gồm CN) và review lần 3 T-BA-58 (AC-08.02.4 gắn nhãn phạm vi US-01.11).

Việc: T-BA-16. Quy tắc dùng: §Báo cáo trong `ba/srs/03-quy-tac.md` (BR-55…BR-62, BR-101…BR-105, định nghĩa chỉ số §2, §3). Riêng tư: `ba/srs/04-nfr-rieng-tu.md` §3 (ma trận ai thấy gì), NFR-P07, NFR-P09, NFR-P10, NFR-17.

Thuật ngữ (D-11): **hoàn thành** = COMPLETED (kể cả phiên `forfeited`); **hoàn thành có thưởng** = COMPLETED và phiên không `forfeited`. Báo cáo **không có chỉ số chuỗi** (D-12, BR-57); số ngày điểm danh chỉ tính trên phiên của nhóm đó (§2).

Câu hỏi còn **Chờ** dùng đề xuất: Q-12 (thông báo mục đích), Q-24 (tổng nhóm cho thành viên), Q-137 (không hiện số lần thoát tích lũy của người khác). Q-36, Q-64 đã chốt ở D-24. Các chỉ số có nhãn đề xuất trong BR (Q-23, Q-42, Q-43) giữ nguyên nhãn.

Vai trò theo D-10: **Chủ nhóm** và **Thành viên** tính theo từng nhóm; **Quản trị** là vai trò hệ thống. Sĩ số viết dạng "CN + n TV" (BR-74).

---

## US-08.01 Tạo báo cáo tháng tự động

**Là một** Chủ nhóm, **tôi muốn** hệ thống tự tạo báo cáo tháng cho từng nhóm của tôi vào đầu tháng **để** có số liệu khách quan mà không phải tự tổng hợp.

- Ưu tiên: Must · Ước lượng: L · Nguồn: GĐ1 §4.8, §8, §11; D-11 · Liên quan: BR-35, BR-37, BR-46, BR-55…BR-60, BR-62, BR-101, BR-102; NFR-17

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.01.1 | Bình thường | Nhóm A (CN + 6 TV) có 12 phiên COMPLETED trong tháng 9 (giờ Asia/Ho_Chi_Minh) | Lịch chạy lúc 02:00 ngày 01/10 | Tạo đúng 1 báo cáo kỳ 09 cho nhóm A, mỗi người có lượt dự kiến có 1 dòng với chỉ số theo §2, tổng nhóm theo §3 (BR-55, BR-56); hoàn tất trước 06:00 (NFR-17) |
| AC-08.01.2 | Bình thường | Nhóm có 1 phiên `forfeited = true` do thành viên X khởi phát; Y COMPLETED trong phiên đó | Tạo báo cáo | Dòng X: "Số lần gây mất thưởng tập thể" = 1. Dòng Y: "Số phiên hoàn thành" +1, "Trong đó: hoàn thành có thưởng" +0, "Số phiên bị mất thưởng tập thể đã tham gia" = 1, ngày đó tính vào "Số ngày điểm danh (trong nhóm)" (D-11, BR-46, §2) |
| AC-08.01.3 | Bình thường | Kỳ có 10 lượt dự kiến: 8 COMPLETED (2 trong phiên `forfeited`), 2 EXITED | Tạo báo cáo | "Tỉ lệ hoàn thành phiên" = 80,0%; "Tỉ lệ hoàn thành có thưởng" = 60,0% (§3, D-11) |
| AC-08.01.4 | Biên | Phiên có `started_at` 23:50 ngày 30/09 và kết thúc 00:15 ngày 01/10 | Tạo báo cáo | Phiên thuộc kỳ 09 (theo `started_at`, BR-55); không xuất hiện ở kỳ 10 |
| AC-08.01.5 | Biên | Phiên CANCELLED (chủ nhóm hủy hoặc sự cố BR-22) trong kỳ | Tạo báo cáo | Phiên không vào tử số lẫn mẫu số (BR-58) |
| AC-08.01.6 | Biên | Thành viên Y vào nhóm 15/09; thành viên Z rời nhóm 20/09 | Tạo báo cáo | Dòng Y ghi "vào ngày 15/09", chỉ tính phiên từ 15/09; dòng Z ghi "rời ngày 20/09", giữ số liệu đến 20/09 (BR-59) |
| AC-08.01.7 | Biên | Nhóm A (CN + 4 TV) có 3 phiên trong kỳ; CN không tham gia phiên (D-25) | Tạo báo cáo | Báo cáo có đúng 4 dòng (4 TV); CN không có dòng, không tính vào lượt dự kiến hay tổng nhóm (BR-60, BR-114, D-25) |
| AC-08.01.8 | Biên | Nhóm ĐÃ GIẢI TÁN ngày 18/09 | Đến 02:00 ngày 01/10 | Tạo báo cáo cho 01/09–18/09, gửi người từng là chủ nhóm (BR-62, đề xuất Q-44) |
| AC-08.01.9 | Lỗi | Lần chạy 02:00 thất bại (Lambda lỗi / DB không phản hồi) | Hệ thống phát hiện lỗi | Tự chạy lại tối đa 3 lần, cách nhau 1 giờ, không quá 06:00; không bao giờ có 2 báo cáo cho cùng (nhóm, kỳ); quá 06:00 vẫn lỗi → cảnh báo vào hộp việc quản trị (BR-101) |
| AC-08.01.10 | Lỗi | Báo cáo kỳ 09 đã tạo | Có giải trình mới, miễn trừ mới hoặc dữ liệu phiên kỳ 09 thay đổi sau 02:00 | Số liệu bản chụp không đổi (BR-56, BR-102); PDF nếu có (US-08.06, Should) cũng không đổi |
| AC-08.01.11 | Lỗi | Bất kỳ | Tạo báo cáo | Không có cột/chỉ số chuỗi nào trong báo cáo (D-12, BR-57) |

**Ghi chú / giả định:** EventBridge Scheduler + Lambda (Should; MVP có thể cron EC2). Mốc 02:00 là đề xuất (Q-132).

---

## US-08.02 Chủ nhóm xem báo cáo của từng nhóm

**Là một** Chủ nhóm, **tôi muốn** chọn một nhóm tôi làm chủ và xem báo cáo tháng của nhóm đó **để** nắm mức tập trung của từng thành viên và cả nhóm.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.8; D-10, D-12 · Liên quan: BR-53, BR-57, BR-61, BR-102, BR-103; NFR-P07, NFR-P10; 04 §3 (A-28, A-29)

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.02.1 | Bình thường | Người dùng U là chủ nhóm A và B | Mở "Báo cáo", chọn nhóm A, kỳ 09 | Thấy bảng dòng từng thành viên (§2) và tổng nhóm (§3) của A; không lẫn số liệu B |
| AC-08.02.2 | Bình thường | Thành viên X có EXITED kèm giải trình gửi trước lúc tạo báo cáo | Chủ nhóm xem dòng X trong app | Sự kiện thoát hiện kèm giải trình (BR-61, NFR-P10) |
| AC-08.02.3 | Bình thường | X gửi giải trình **sau** lúc tạo báo cáo | Chủ nhóm xem báo cáo trong app | Giải trình hiện kèm nhãn "thêm sau khi tạo báo cáo"; số liệu không đổi (BR-102) |
| AC-08.02.4 | Bình thường | Chủ nhóm mở báo cáo nhóm A | Hệ thống phục vụ báo cáo | Ghi nhật ký truy cập (BR-73). *(Phần "mỗi thành viên A thấy 'chủ nhóm đã xem báo cáo lúc…'" (NFR-P07, đề xuất Q-21): chỉ kiểm khi US-01.11 trong phạm vi — T-BA-58)* |
| AC-08.02.5 | Lỗi | U là chủ nhóm A, chỉ là thành viên nhóm B | Gọi API báo cáo tổng/chi tiết nhóm B | 403; không lộ dòng của người khác trong B (04 §3, D-10) |
| AC-08.02.6 | Lỗi | Báo cáo bất kỳ | Chủ nhóm xem (app hoặc API) | Không có Coins (BR-53, BR-61), không có chuỗi (D-12), không có tên app/nội dung máy (BR-34), không có số liệu phiên của nhóm khác |
| AC-08.02.7 | Biên | Nhóm CN + 4 TV (sàn 4, không gồm CN — đề xuất Q-141) | Chủ nhóm xem | Hiện 4 dòng; CN không có dòng (D-25, BR-60, BR-114) |
| AC-08.02.8 | Biên | Nhóm CN + 10 TV (đầy, Q-141); 1 TV rời giữa kỳ, 1 TV mới vào thay | Chủ nhóm xem | Hiện 11 dòng: 10 TV hiện tại + 1 TV đã rời (BR-59); không có dòng CN (D-25) |
| AC-08.02.9 | Bình thường | Phiên ngày 12/09 của nhóm A có X thoát (EXITED) | Chủ nhóm chạm phiên 12/09 trong báo cáo | Mở màn "Chi tiết phiên" (US-08.10) của phiên đó; thấy tên X là người thoát, giờ server, giải trình nếu có (D-22, AC-08.10.1) |
| AC-08.02.10 | Lỗi | U là chủ nhóm A và B | Mở "Báo cáo" | Không có lựa chọn/API "mọi nhóm" gộp số liệu; mỗi lần xem chỉ một nhóm (D-21) |
| AC-08.02.11 | Bình thường | Báo cáo nhóm A có các dòng "Vũ", "An", "Bình" (tên hiển thị) | Chủ nhóm xem bảng dòng thành viên (app, PDF nếu có) | Dòng sắp theo tên hiển thị A→Z (An, Bình, Vũ), so sánh không phân biệt hoa/thường theo chữ cái tiếng Việt, trùng tên thì theo thời điểm vào nhóm (sớm trước), vẫn trùng thì theo `user_id`; không phụ thuộc giá trị chỉ số nào (BR-115, D-03, NFR-P06) |
| AC-08.02.12 | Lỗi | Như AC-08.02.11 | Chủ nhóm tìm cách sắp/lọc bảng theo cột chỉ số (tỉ lệ hoàn thành, số lần thoát…) hoặc gọi API với tham số sắp theo chỉ số | Giao diện không có thao tác sắp theo cột chỉ số; API bỏ qua tham số đó và trả thứ tự theo tên; không có tô màu/huy chương/"top" theo chỉ số (BR-115, D-03, AC-08.05.4) |

**Ghi chú / giả định:** Quyền xem kỳ cũ: BR-103. Quản trị không xem báo cáo cá nhân (04 §3, đề xuất). Chủ nhóm được tạo/quản lý nhiều nhóm (D-21, D-25) nhưng báo cáo luôn tách theo nhóm; chủ nhóm không tham gia phiên nên không có dòng (D-25).

---

## US-08.03 Thành viên xem dòng của chính mình

**Là một** Thành viên, **tôi muốn** xem số liệu tháng của chính tôi trong nhóm của tôi **để** biết chủ nhóm đang thấy gì về tôi.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §6; 04 §3; D-12 · Liên quan: BR-57, BR-59, BR-61, BR-102, BR-103; NFR-P07, NFR-P10

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.03.1 | Bình thường | X là thành viên nhóm A, báo cáo kỳ 09 đã tạo | X mở "Báo cáo của tôi", chọn nhóm A | Thấy đúng dòng của X với cùng các chỉ số chủ nhóm thấy (§2), kèm giải trình |
| AC-08.03.2 | Biên | Trong kỳ 09, X ở nhóm A đến 15/09 (hoàn thành 5 ngày), rời A rồi vào nhóm B (D-21, hoàn thành 3 ngày khác) | X mở "Báo cáo của tôi" kỳ 09 | Chọn từng nhóm một: dòng ở A "Số ngày điểm danh (trong nhóm)" = 5, ghi "rời ngày 15/09"; dòng ở B = 3 (§2, BR-59); không có màn gộp hai nhóm; không dòng nào có chuỗi (D-12) |
| AC-08.03.3 | Lỗi | X là thành viên nhóm A | X gọi API lấy dòng của Y cùng nhóm | 403 |
| AC-08.03.5 | Lỗi | Y cùng nhóm A thoát 3 phiên trong kỳ | X mở báo cáo của mình | Không thấy tổng số lần thoát hay chỉ số nào của Y (đề xuất Q-137); tên người thoát chỉ biết qua thông báo tức thời từng phiên (D-22, EP-04) |
| AC-08.03.4 | Biên | X rời nhóm A ngày 20/09 | X mở báo cáo kỳ 09 | X vẫn xem được dòng của mình kỳ 09 trong thời hạn lưu 13 tháng (BR-103, đề xuất Q-113) |

**Ghi chú / giả định:** Chuỗi chỉ xem ở hồ sơ của chính mình (US-07.01).

---

## US-08.04 Thành viên xem tổng nhóm (nhóm ≥ 5 thành viên)

**Là một** Thành viên, **tôi muốn** xem số liệu tổng nhóm **để** so mình với nhịp chung mà không thấy dữ liệu từng người.

- Ưu tiên: Should · Ước lượng: S · Nguồn: GĐ1 §4.8, §6 (minh bạch, không lộ cá nhân); D-03; 04 §3; R-P06 · Liên quan: BR-57, BR-104 **(đề xuất, Q-24, Q-110)**

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.04.1 | Bình thường | Nhóm A có CN + 6 TV lúc tạo báo cáo | Thành viên mở tab "Tổng nhóm" | Thấy chỉ số §3, không có tên hay dòng của người khác |
| AC-08.04.2 | Lỗi | Nhóm A có CN + 4 TV lúc tạo báo cáo | Thành viên gọi API tổng nhóm | 403; giao diện hiện "Tổng nhóm chỉ hiển thị khi nhóm từ 5 thành viên" |
| AC-08.04.3 | Biên | Nhóm có CN + 5 TV lúc tạo báo cáo | Thành viên mở tổng nhóm | Được xem (`group_report_min_members = 5`, BR-104) |
| AC-08.04.4 | Biên | Nhóm có CN + 5 TV đầu tháng, CN + 4 TV lúc tạo báo cáo, CN + 6 TV lúc xem | Thành viên mở tổng nhóm kỳ đó | 403 — đếm theo số TV (không gồm CN) lúc tạo báo cáo, lưu cùng bản chụp (BR-104) |
| AC-08.04.5 | Lỗi | Nhóm CN + 6 TV, tổng nhóm được xem | Thành viên mở tổng nhóm | Không có danh sách tên người thoát, không có số lần thoát theo người (đề xuất Q-137, D-22 chỉ áp cho thông báo tức thời) |

---

## US-08.05 So sánh với tháng trước

**Là một** Chủ nhóm, **tôi muốn** thấy các chỉ số nhóm thay đổi thế nào so với tháng trước **để** biết nhóm đang tiến bộ hay đi xuống.

- Ưu tiên: Should · Ước lượng: S · Nguồn: GĐ1 §4.8; D-03, D-11 · Liên quan: §3 "So với tháng trước", BR-56

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.05.1 | Bình thường | Tỉ lệ hoàn thành phiên kỳ 08 = 80,0%, kỳ 09 = 85,2% | Xem báo cáo kỳ 09 | Hiện "+5,2 đpt" |
| AC-08.05.2 | Bình thường | Số phiên bị mất thưởng tập thể kỳ 08 = 3, kỳ 09 = 1 | Xem báo cáo kỳ 09 | Hiện "−2" (chênh lệch tuyệt đối) |
| AC-08.05.3 | Lỗi | Nhóm tạo trong tháng 09, không có báo cáo kỳ 08 | Xem báo cáo kỳ 09 | Hiện "không có dữ liệu so sánh"; không hiện 0 hay lỗi |
| AC-08.05.4 | Lỗi | Bất kỳ | Xem báo cáo | Không có so sánh theo từng cá nhân, không xếp hạng thành viên; thứ tự dòng theo tên (AC-08.02.11, BR-115) (D-03) |
| AC-08.05.5 | Biên | Kỳ 08 có báo cáo nhưng tỉ lệ = "không có dữ liệu" (không có lượt dự kiến) | Xem kỳ 09 | Tỉ lệ đó hiện "không có dữ liệu so sánh"; số đếm vẫn so bình thường **(giả định)** |

**Ghi chú / giả định:** So sánh lấy từ bản chụp kỳ trước (BR-56), không tính lại.

---

## US-08.06 Tải báo cáo PDF trong app

**Là một** Chủ nhóm, **tôi muốn** tải báo cáo tháng dạng PDF ngay trong app **để** lưu trữ hoặc gửi cho người liên quan.

- Ưu tiên: Should (D-13, D-24) · Ước lượng: M · Nguồn: GĐ1 §4.8; 01 A-30; D-13, D-24 · Liên quan: BR-57, BR-61, BR-73, BR-102, BR-105 (PDF chỉ tải trong app; Excel là Could, Q-36); NFR-P07; 04 §4 (lưu 13 tháng)

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.06.1 | Bình thường | Báo cáo kỳ 09 nhóm A đã tạo | Chủ nhóm bấm "Tải PDF" | Nhận PDF có cùng số liệu với bản chụp, kèm thông báo mục đích (US-08.08), kỳ, tên nhóm, thời điểm tạo; không có Coins, chuỗi (D-12) |
| AC-08.06.2 | Bình thường | Chủ nhóm tải PDF | Hệ thống phục vụ | Ghi nhật ký truy cập loại "xuất" (BR-73, NFR-P07); link tải là presigned URL |
| AC-08.06.3 | Biên | Link tải trong app tạo lúc T (`report_link_app_min = 15`, BR-105) | Mở link lúc T + 14 phút / T + 16 phút | 14 phút: tải được; 16 phút: hết hạn, phải bấm "Tải PDF" lại |
| AC-08.06.4 | Bình thường | Có giải trình thêm sau khi tạo báo cáo | Tải PDF | PDF giữ nguyên như lúc tạo, không có giải trình mới (BR-102) |
| AC-08.06.5 | Lỗi | Thành viên (không phải chủ nhóm) | Gọi API tải PDF nhóm | 403 (A-30) |
| AC-08.06.6 | Lỗi | Tệp PDF đã quá 13 tháng, bị S3 Lifecycle xóa | Chủ nhóm bấm tải | Hiện "Báo cáo đã hết thời hạn lưu"; không lỗi 500 |
| AC-08.06.7 | Biên | Nhóm CN + 10 TV (đầy, Q-141), CN không có dòng (D-25), 1 TV đã rời trong kỳ (11 dòng) | Tải PDF | Đủ 11 dòng, không cắt trang mất dữ liệu |

**Ghi chú / giả định:** Excel: Could, không làm ở MVP. PDF chỉ tải trong app, **không** gửi qua email (D-24). Không story Must nào phụ thuộc US-08.06 (T-BA-57).

---

## US-08.07 Gửi email tóm tắt báo cáo cho chủ nhóm

**Là một** Chủ nhóm, **tôi muốn** nhận email tóm tắt báo cáo nhóm mỗi đầu tháng **để** nắm nhanh tình hình mà không cần mở app.

- Ưu tiên: Must (D-24) · Ước lượng: M · Nguồn: GĐ1 §11; 01 G-02; D-24 · Liên quan: BR-53, BR-56, BR-57, BR-62, BR-105, BR-122; NFR-17; AWS SES · Không phụ thuộc US-08.06

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.07.1 | Bình thường | Báo cáo kỳ 09 nhóm A tạo lúc 02:00 | Hệ thống gửi email | Chủ nhóm A (tại thời điểm tạo, BR-57) nhận email ≤ 1 giờ sau khi tạo (NFR-17); thân thư có đúng các mục tóm tắt cấp nhóm theo BR-105 và link mở báo cáo trong app (yêu cầu đăng nhập) |
| AC-08.07.2 | Bình thường | U là chủ của 2 nhóm | Đầu tháng | U nhận 2 email, mỗi email một nhóm, không gộp số liệu (D-21) **(giả định)** |
| AC-08.07.3 | Lỗi | SES từ chối (địa chỉ chưa xác minh ở sandbox / hộp thư lỗi) | Gửi email | Thử lại tối đa 3 lần trong 24 giờ; vẫn lỗi thì ghi "gửi thất bại", báo cáo vẫn xem trong app; không gửi cho người khác thay thế (BR-105) |
| AC-08.07.4 | Lỗi | Bất kỳ | Gửi email | Không gửi email báo cáo nhóm cho thành viên, không gửi cho Quản trị (04 §3) |
| AC-08.07.5 | Biên | Gửi xong ở phút 59 sau khi tạo / phút 61 | Đo NFR-17 | 59 phút: đạt; 61 phút: không đạt NFR-17 |
| AC-08.07.6 | Lỗi | Bất kỳ email báo cáo | Kiểm tra nội dung email | Không có tệp đính kèm, không có link tải PDF, không có dòng từng thành viên, không có tên người thoát, không chuỗi/Coins (BR-105, BR-53, D-24) |
| AC-08.07.8 | Lỗi (riêng tư) | Bất kỳ email báo cáo | Rà mã nguồn email | Không có ảnh theo dõi mở thư (ảnh tải từ xa kèm mã người nhận), không link chuyển hướng/tham số theo dõi; link mở báo cáo trỏ thẳng đích (BR-122, D-27) |
| AC-08.07.7 | Bình thường | Chủ nhóm bấm link trong email khi chưa đăng nhập | Mở link | App/Web yêu cầu đăng nhập rồi mở đúng báo cáo nhóm A kỳ 09; người không phải chủ nhóm A → 403 (BR-105) |

**Ghi chú / giả định:** MVP không cho tắt email (BR-105, đề xuất Q-114). Kỳ trống: email ngắn (US-08.09). Tham số `report_link_email_days` đã Hủy (D-24).

---

## US-08.08 Thông báo mục đích sử dụng báo cáo

**Là một** Thành viên, **tôi muốn** thấy rõ báo cáo được dùng vào việc gì **để** biết số liệu của tôi có thể ảnh hưởng thế nào.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §6; R-P03 · Liên quan: BR-61 **(đề xuất, Q-12)**; NFR-P09; 01 A-06

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.08.1 | Bình thường | Nhóm A có mục đích chủ nhóm đã khai khi tạo nhóm (NFR-P09) | Thành viên hoặc chủ nhóm mở báo cáo trong app / email tóm tắt / PDF (nếu có US-08.06) | Đầu báo cáo hiện nguyên văn mục đích đó |
| AC-08.08.2 | Bình thường | Chủ nhóm sửa mục đích trong tháng 10 | Xem báo cáo kỳ 09 | Báo cáo kỳ 09 vẫn hiện mục đích tại lúc tạo (bản chụp, BR-56) |
| AC-08.08.3 | Lỗi | Dữ liệu cũ thiếu trường mục đích | Tạo báo cáo | Hiện câu mặc định "Chưa khai báo mục đích — báo cáo chỉ mang tính tham khảo" **(giả định)**; không chặn tạo báo cáo |

**Ghi chú / giả định:** Có dùng để đánh giá/kỷ luật hay không do công ty quyết (Q-12); app chỉ hiển thị. Sửa mục đích tăng phiên bản đồng ý (BR-71), xử lý ở EP-01/EP-02.

---

## US-08.09 Nhóm chưa có dữ liệu trong kỳ

**Là một** Chủ nhóm, **tôi muốn** thấy thông báo rõ ràng khi nhóm không có phiên nào trong tháng **để** không hiểu nhầm là lỗi hay tỉ lệ 0%.

- Ưu tiên: Should (D-13) · Ước lượng: S · Nguồn: GĐ1 §4.8; D-13 · Liên quan: BR-56, BR-58, BR-105, §3 (Tỉ lệ hoàn thành phiên)

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.09.1 | Bình thường | Nhóm A không có lượt dự kiến nào trong kỳ 09 | Đến 02:00 ngày 01/10 | Vẫn tạo báo cáo với nhãn "Kỳ này chưa có phiên nào"; hai tỉ lệ hiện "không có dữ liệu", không hiện 0% (§3); email ngắn "không có phiên trong kỳ" (BR-105) |
| AC-08.09.2 | Bình thường | Nhóm có 3 phiên trong kỳ nhưng đều CANCELLED | Tạo báo cáo | Như AC-08.09.1 (BR-58) |
| AC-08.09.3 | Lỗi | Nhóm tạo ngày 05/10 | Chủ nhóm mở "Báo cáo" trước 01/11 | Hiện "Báo cáo đầu tiên sẽ có vào 01/11"; không lỗi |
| AC-08.09.4 | Biên | Nhóm có 4 lượt dự kiến, 0 COMPLETED (đều EXITED/ABSENT) | Tạo báo cáo | Báo cáo đầy đủ; "Tỉ lệ hoàn thành phiên" = 0,0% (có lượt dự kiến nên không phải "không có dữ liệu") |

---

## US-08.10 Chủ nhóm xem chi tiết phiên của nhóm

**Là một** Chủ nhóm, **tôi muốn** mở chi tiết một phiên của nhóm tôi làm chủ **để** biết ai đã rời app, lúc nào và họ giải trình gì, mà không theo dõi ai trong lúc phiên chạy.

- Ưu tiên: Must · Ước lượng: S **(giả định)** · Nguồn: GĐ1 §4.3, §6, §10 #3; D-03, D-10, D-12, D-22, D-25; `review/mockup-tong-hop.md` S2, S3 (T-BA-105) · Liên quan: BR-23, BR-27, BR-28, BR-29, BR-32, BR-34, BR-35, BR-38, BR-39, BR-53, BR-61, BR-73, BR-85, BR-116, BR-115, BR-123; NFR-P02, NFR-P19, NFR-P06, NFR-P07, NFR-P10, NFR-P18, NFR-11; 04 §3

Lối vào: (1) chạm thông báo `MEMBER_EXITED` (US-04.01); (2) danh sách phiên của nhóm; (3) chạm một phiên trong báo cáo tháng (AC-08.02.9). Màn này là nơi AC-04.06.1 và AC-08.02.9 tham chiếu.

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-08.10.1 | Bình thường | Phiên "Sáng thứ Hai" nhóm A đã COMPLETED, `forfeited = true`; A EXITED 09:10:03 (khởi phát) có giải trình; B EXITED 09:15:40 chưa giải trình | Chủ nhóm A chạm thông báo `MEMBER_EXITED` của A, hoặc mở phiên từ danh sách/báo cáo | Màn hiện: tên lịch, ngày, giờ bắt đầu–kết thúc, thời lượng; "Phiên mất thưởng tập thể do A rời phiên" (BR-38, BR-39); danh sách rời app theo giờ server tăng dần (danh sách sự kiện — ngoại lệ thứ hai BR-115): "A — 09:10:03 — ‹giải trình›", "B — 09:15:40 — Chưa có giải trình" (D-22, BR-61, NFR-P10) |
| AC-08.10.2 | Bình thường | Như AC-08.10.1; nhóm có TV "Vũ", "An", "Bình" | Xem phần "Thành viên trong phiên" | Mỗi dòng: tên + trạng thái kết thúc (Hoàn thành / Rời app / Mất kết nối / Vắng); sắp theo tên A→Z, không sắp theo trạng thái hay chỉ số (BR-115, D-03). Chỉ hiện trường đã liệt kê ở màn đồng ý 04 §2 mục 2 (NFR-P19) **(giả định)** |
| AC-08.10.3 | Bình thường | Như AC-08.10.1 | Chủ nhóm mở màn | Ghi nhật ký truy cập (BR-73, NFR-P07) |
| AC-08.10.4 | Lỗi (phủ định) | Phiên đang ACTIVE; B đang GRACE, C đang PAUSED, D đang DISCONNECTED; A đã EXITED (đã xác nhận) | Chủ nhóm mở chi tiết phiên (app hoặc API) | Chỉ thấy "Phiên đang diễn ra — kết quả có sau khi kết thúc" và danh sách EXITED đã xác nhận (A, giờ server). **Không** có trạng thái thời gian thực của từng người (FOCUSING/GRACE/PAUSED/DISCONNECTED), không online/offline, không "đang rời app"; phản hồi API không chứa các trường đó (BR-28, NFR-P02, BR-116) **(đề xuất, Q-144)** |
| AC-08.10.5 | Lỗi (phủ định) | Phiên ở bất kỳ trạng thái nào | Chủ nhóm xem màn / rà API | **Không** có nút hay API Nhắc, Rung, Tạm dừng thành viên/phiên, Kết thúc sớm, Duyệt/Hoàn tất phiên, Bảo lưu chuỗi; chủ nhóm không đổi được kết quả từng người (BR-23, BR-32, D-25). Gọi các đường dẫn đó → 404 |
| AC-08.10.6 | Lỗi (riêng tư) | Như AC-08.10.1 | Rà màn và phản hồi API | Không có Coins, chuỗi, điểm/hạng, tên app, nội dung máy, vị trí, số lần thoát tích lũy của ai (BR-34, BR-53, D-03, D-12, NFR-P06) |
| AC-08.10.7 | Lỗi | Người gọi là thành viên nhóm A, hoặc chủ nhóm B (không làm chủ A) | Gọi API chi tiết phiên của nhóm A | 403; không lộ tên hay giải trình (NFR-11, NFR-P18) |
| AC-08.10.8 | Biên | Phiên COMPLETED, không ai EXITED, 1 TV LOST | Chủ nhóm mở | Hiện "Không có ai rời app"; phiên không mất thưởng (D-19); TV LOST hiện "Mất kết nối" trong danh sách thành viên, không trong danh sách rời app |
| AC-08.10.9 | Biên | Nhóm CN + 10 TV (đầy, đề xuất Q-141); cả 10 EXITED | Chủ nhóm mở | Danh sách rời app đủ 10 dòng theo giờ server (ngoại lệ thứ hai BR-115); danh sách thành viên đủ 10 dòng theo tên; CN không có dòng (D-25) |
| AC-08.10.10 | Biên | Phiên bị chủ nhóm hủy khi SCHEDULED (BR-29) | Chủ nhóm mở | Hiện "Phiên đã hủy lúc hh:mm"; không có danh sách thành viên hay sự kiện |
| AC-08.10.12 | Bình thường | Chủ nhóm đang mở màn chi tiết phiên đang ACTIVE; A EXITED sau khi mở | Không thao tác / kéo xuống để làm mới | Không thao tác: màn không đổi, không tự làm mới, không có đẩy cập nhật; kéo làm mới: hiện thêm A (BR-123, D-28) |
| AC-08.10.11 | Bình thường | EXITED của A được MIỄN TRỪ *(chỉ kiểm khi US-04.08 trong phạm vi)* | Chủ nhóm mở | Dòng A giữ nguyên, thêm nhãn "Đã miễn trừ"; dòng trạng thái mất thưởng cập nhật theo BR-87 |

**Ghi chú / giả định:** Màn chi tiết phiên **không** có bản thời gian thực cho chủ nhóm ở MVP (đề xuất, Q-144). Lý do tạm dừng chỉ hiện khi US-03.06 (Should) trong phạm vi. Giải trình sửa trong hạn: theo AC-04.06.6. Quy tắc nội dung màn: BR-116; thứ tự dòng: BR-115. Theo 04 §3 hiện hành (Q-146), lối vào Must cho sự kiện thoát là US-08.10 và báo cáo US-08.02; US-05.09 giữ Should. Làm mới: BR-123 (D-28).

---

## Truy vết

(Đồng bộ với `ba/03-truy-vet.md`; tệp đó do điều phối viên cập nhật.)

| US | Nguồn | BR / NFR | Q- liên quan | MoSCoW |
| --- | --- | --- | --- | --- |
| US-08.01 | GĐ1 §4.8, §8, §11; D-05, D-11, D-12, D-25 | BR-35, BR-37, BR-46, BR-55…BR-60, BR-62, BR-101, BR-102, BR-114; NFR-17 | Q-42, Q-43, Q-44, Q-115, Q-132 | Must |
| US-08.02 | GĐ1 §4.8; D-03, D-10, D-12, D-21, D-22, D-25; Q-141; AC-08.02.4 phụ thuộc US-01.11 (T-BA-58); T-BA-106 | BR-115, BR-34, BR-53, BR-57, BR-59, BR-60, BR-61, BR-73, BR-102, BR-103, BR-114; NFR-P07, NFR-P10 | Q-21, Q-23, Q-112 | Must |
| US-08.03 | GĐ1 §6; D-12, D-21, D-22; 04 §3 | BR-57, BR-59, BR-61, BR-103; §2; NFR-P07, NFR-P10 | Q-43, Q-113, Q-137 | Must |
| US-08.04 | GĐ1 §4.8, §6; D-03, D-22; 04 §3; R-P06 | BR-57, BR-104 | Q-24, Q-110, Q-137 | Should |
| US-08.05 | GĐ1 §4.8; D-03, D-11 | §3 So với tháng trước; BR-56 | — | Should |
| US-08.06 | GĐ1 §4.8; 01 A-30; D-13, D-24 | BR-57, BR-61, BR-73, BR-102, BR-105; NFR-P07; 04 §4 | Q-36, Q-111 | Should |
| US-08.07 | GĐ1 §11; 01 G-02; D-21, D-24 | BR-53, BR-56, BR-57, BR-62, BR-105, BR-122; NFR-17 | Q-114 | Must (D-24) |
| US-08.08 | GĐ1 §6; R-P03 | BR-61, BR-71; NFR-P09 | Q-12 | Must |
| US-08.09 | GĐ1 §4.8; D-13 | BR-56, BR-58, BR-105; §3 | Q-114 | Should |
| US-08.10 (mới) | GĐ1 §4.3, §6, §10 #3; D-03, D-10, D-12, D-19, D-22, D-25; mockup-tong-hop S2, S3 (T-BA-105) | BR-23, BR-27, BR-28, BR-29, BR-32, BR-34, BR-38, BR-39, BR-53, BR-61, BR-73, BR-85, BR-87; BR-116; BR-115; BR-123; NFR-P02, NFR-P19, NFR-P06, NFR-P07, NFR-P10, NFR-P18, NFR-11 | Q-141, Q-144, Q-146 | Must |

Sửa 2026-10-19 theo `review/mockup-tong-hop.md` §3: S2/S3 → US-08.10 mới (Must, S — **Must tăng S**, cần điều phối viên cập nhật tổng Must); AC-08.02.9 tham chiếu US-08.10; S4 → AC-08.02.11, .12 (mới, thứ tự theo tên), AC-08.05.4 thêm tham chiếu. Dòng US-08.02 thêm BR-115.

Sửa 2026-10-19 theo `review/lan-4.md`: T-BA-125 (AC-08.01.7, AC-08.02.7, dòng US-08.01/08.02: BR-69 Hủy → BR-114, BR-60); T-BA-126 (AC-08.02.11 trùng tên theo `user_id`, BR-115); T-BA-127 (ghi chú US-08.10 dẫn BR-115/BR-116; Q-144, Q-146 đã ghi sổ). Ước lượng không đổi.

Sửa 2026-10-19 theo `review/lan-5.md`: T-BA-134 (AC-08.10.1, .9 dẫn ngoại lệ thứ hai BR-115); T-BA-135 (NFR-P04a → NFR-P19); T-BA-136 (AC-08.07.8 theo BR-122/D-27, AC-08.10.12 theo BR-123/D-28); T-BA-138 (ghi chú US-08.10 theo 04 §3 hiện hành).

## Q- liên quan (đã ghi sổ)

Đã cấp số chính thức trong `ba/02-so-quyet-dinh.md`, trạng thái `Chờ`.

| Mã | Câu hỏi | Đề xuất | Ảnh hưởng |
| --- | --- | --- | --- |
| Q-110 | Ngưỡng "nhóm ≥5" đếm lúc nào, có tính chủ nhóm? | Đếm thành viên (không gồm CN) lúc tạo báo cáo (BR-104) | US-08.04 |
| Q-111 | Link PDF hết hạn sau bao lâu? | 15 phút trong app (BR-105); email không có link PDF (D-24) | US-08.06 |
| Q-112 | Giải trình thêm sau khi tạo có hiện trong báo cáo? | Hiện trong app kèm nhãn; PDF không đổi (BR-102) | US-08.01, US-08.02, US-08.06 |
| Q-113 | Người đã rời còn xem dòng mình ở kỳ cũ? | Có, 13 tháng (BR-103) | US-08.03 |
| Q-114 | Kỳ trống có gửi email? Tắt email được? | Có gửi email ngắn; không cho tắt (BR-105) | US-08.07, US-08.09 |
| Q-115 | Tạo báo cáo lỗi: chạy lại bao nhiêu lần? | 3 lần đến 06:00; lỗi báo quản trị (BR-101) | US-08.01 |
| Q-144 (đã ghi sổ) | MVP có màn "phiên đang chạy" cho chủ nhóm không? | Không; khi ACTIVE chỉ hiện EXITED đã xác nhận, không trạng thái thời gian thực | US-08.10 |
| Q-146 (đã ghi sổ) | US-05.09 (Should) được 04 §3 gọi là "lối vào duy nhất" dữ liệu thành viên — nâng Must hay sửa 04 §3? | Giữ US-05.09 Should; sửa 04 §3: lối vào Must cho sự kiện thoát là US-08.10 và báo cáo US-08.02 | US-05.09, US-08.10 |

Sửa 2026-10-19 (khớp BR-115): AC-08.02.11 trùng tên theo thời điểm vào nhóm rồi `user_id`.
