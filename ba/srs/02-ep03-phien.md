# EP-03 Phiên & Lockdown

Nguồn: GĐ1 §4.2, §4.3, §6, §10 #3; D-05, D-06, D-07, D-08, D-10, D-11, D-13, D-19, D-20, D-21, D-22, D-25 · MoSCoW: Must (Should: US-03.06, US-03.12 theo D-13; US-03.11 theo D-13 và 01 §5; US-03.14 Should (giả định); US-03.13 Hủy — D-25) · Phụ trách: BA (T-BA-09)

Thuật ngữ (D-11): **hoàn thành** = trạng thái cuối COMPLETED (kể cả khi phiên `forfeited`); **hoàn thành có thưởng** = COMPLETED và phiên không `forfeited`. Mốc giờ phiên (BR-04): giờ lịch = `started_at`; COUNTDOWN bắt đầu `started_at − 5s`. Mốc mất kết nối (BR-19): mọi hạn giữ chỗ tính từ `disconnected_at`.
Sửa 2026-10-06 theo review lần 1: T-BA-29 (AC-03.12.1, .2 ngoại lệ BR-68), T-BA-31/T-BA-43 (MoSCoW D-13), T-BA-35 (AC-03.07.x mốc `disconnected_at`), T-BA-36 (AC-03.02.1, .2 mốc đếm ngược), T-BA-45 (nguồn GĐ1/D- cho US-03.07, 03.11, 03.12), D-11 (thuật ngữ ở US-03.10), D-14 (US-03.09 nhận AC từ US-04.02, AC-03.09.6–11).
Sửa 2026-10-07 theo D-19…D-22 và review lần 2: US-03.09 viết lại (có tên người thoát, gửi cả nhóm + cả phiên, BR-27/BR-38/BR-82); LOST không làm phiên mất thưởng (AC-03.07.3, .10; AC-03.08.3, .8); "báo chủ nhóm" → `MEMBER_EXITED` (BR-27); T-BA-58: AC-03.09.11 chuyển sang AC-03.12.6, AC-03.02.5 và AC-03.01.3 gắn nhãn phạm vi; CN nhiều nhóm theo BR-114 (AC-03.13.4).
Sửa 2026-10-19 theo D-25 và review lần 3: US-03.13 Hủy (chủ nhóm không tham gia phiên); AC-03.01.3 viết lại (chủ nhóm bị từ chối vào phòng chờ); AC-03.09.x bỏ ca "CN tham gia"; T-BA-73: thêm AC-03.02.7 (Lỗi, Must); T-BA-70: thêm AC-03.10.7, AC-03.10.8 ghi ABSENT trong phạm vi Must.

Quy ước: trạng thái/sự kiện lấy đúng `ba/srs/03-quy-tac.md` §Phiên. Quy tắc không định nghĩa lại — chỉ tham chiếu `BR-xx`. Vai trò theo nhóm: **chủ nhóm** / **thành viên** (D-10). Ứng dụng Flutter chạy iOS và Android (D-07): mọi AC phát hiện rời app phải đạt trên **cả hai** nền tảng (NFR-19). Tham số dùng giá trị mặc định ở §Phiên §5 (cấu hình được).

---

## US-03.01 Vào phòng chờ phiên theo lịch

**Là một** thành viên, **tôi muốn** vào phòng chờ của phiên nhóm đã được chủ nhóm xếp lịch **để** bắt đầu tập trung cùng nhóm đúng giờ.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.1, §4.2; D-06 · Liên quan: BR-01, BR-02, BR-06, BR-09, BR-29

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.01.1 | Bình thường | Thành viên đã đồng ý phiên bản điều khoản hiện hành; nhóm có phiên SCHEDULED 25 phút; thành viên không ở phiên nào khác | Mở phiên trước giờ bắt đầu | Thành viên chuyển INVITED → WAITING; thấy thời lượng, giờ bắt đầu theo giờ server, số người trong phòng chờ (BR-01, BR-02) |
| AC-03.01.2 | Lỗi | Thành viên chưa đồng ý (hoặc chưa đồng ý lại phiên bản điều khoản mới) | Bấm vào phòng chờ | Bị chặn, chuyển tới màn đồng ý có nêu luật tập thể D-05; vẫn INVITED (BR-06) |
| AC-03.01.3 | Lỗi | Người dùng là chủ nhóm của nhóm có phiên SCHEDULED (chủ nhóm không tham gia phiên, D-25) | Gọi API vào phòng chờ phiên đó (app không hiện nút vào cho chủ nhóm) | Từ chối 403 kèm thông báo “Chủ nhóm không tham gia phiên”; không tạo bản ghi INVITED/WAITING cho chủ nhóm; chủ nhóm không tính vào lượt dự kiến (BR-114, BR-60, D-25) |
| AC-03.01.4 | Lỗi | Chủ nhóm hủy phiên trước giờ (SCHEDULED → CANCELLED) | Thành viên đang WAITING | Thành viên nhận thông báo hủy, chuyển VOID, không ghi sự kiện nào (BR-29) |
| AC-03.01.5 | Biên | Phiên có thời lượng khác 25/50 (dữ liệu sai) | Mở phiên | Server từ chối mở phiên, ghi lỗi; không vào COUNTDOWN (BR-02) |

**Ghi chú / giả định:** Phòng chờ mở trước giờ bắt đầu bao lâu: **BR-63** (10 phút, xem Q-83). Trạng thái WAITING khi chủ nhóm hủy: §2.2 chỉ định nghĩa “Phiên CANCELLED → VOID” cho trạng thái chưa kết thúc — áp dụng cho WAITING **(giả định)**.

---

## US-03.02 Đếm ngược 5 giây và bắt đầu phiên

**Là một** thành viên trong phòng chờ, **tôi muốn** thấy đếm ngược 5 giây đồng bộ với cả nhóm **để** mọi người cùng úp máy một lúc.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.2; `05-tham-chieu-ky-thuat.md` §1.5, §2 · Liên quan: BR-03, BR-04, BR-05, BR-33

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.02.1 | Bình thường | Phiên SCHEDULED lịch 09:00:00 (= `started_at`), ≥1 người WAITING | Giờ server đến 08:59:55 (`started_at − countdown_s`) | Phiên → COUNTDOWN; mọi client hiện đếm ngược 5→1 kết thúc đúng 09:00:00 theo mốc server gửi, không theo đồng hồ máy (BR-03, BR-04) |
| AC-03.02.2 | Bình thường | Phiên COUNTDOWN | Giờ server đến `started_at` (09:00:00) | Phiên → ACTIVE; `ends_at = started_at + duration` (09:25:00 với 25 phút); người WAITING ở app → FOCUSING; bắt đầu ghi sự kiện (BR-04, BR-05) |
| AC-03.02.6 | Biên | Phiên lịch 09:00:00 | Thành viên vào phòng chờ lúc 08:59:57 (đang COUNTDOWN) | Vào WAITING, thấy đếm ngược còn lại 3 giây; tham gia đầy đủ, không đánh dấu vào muộn (BR-07) |
| AC-03.02.3 | Biên | Phiên COUNTDOWN, đồng hồ máy thành viên lệch 30 giây | Đếm ngược chạy | Mốc bắt đầu trên mọi máy lệch ≤ 1 giây so với `started_at` server (BR-03) |
| AC-03.02.4 | Biên | Phiên COUNTDOWN còn 1 giây | Thành viên rời app | Không ghi sự kiện, không GRACE trong COUNTDOWN (BR-05); tại `started_at` người đó không ở app → GRACE hạn 3 giây tính từ `started_at`, trừ lượt khoan hồng (BR-64) **(đề xuất, Q-84)** |
| AC-03.02.5 | Lỗi | Phiên COUNTDOWN | Server xác nhận sự cố (BR-22) | Phiên → CANCELLED; người WAITING → VOID; client nhận `SESSION_CANCELLED_OUTAGE` “Phiên đã hủy do sự cố” *(chỉ kiểm khi US-03.12 trong phạm vi — T-BA-58)* |
| AC-03.02.7 | Lỗi | Phiên COUNTDOWN, `started_at` = 09:00:00 (giờ server); đồng hồ máy thành viên nhanh 10 giây | Client gửi `start` / sự kiện phiên lúc 08:59:56 giờ server | Server bỏ qua gói, phiên vẫn COUNTDOWN; không ghi sự kiện, không tính phút trước `started_at`; tại 09:00:00 phiên → ACTIVE theo mốc server (BR-03, BR-04, BR-05) *(Must, T-BA-73)* |

**Ghi chú / giả định:** AC-03.02.4: hành vi rời app trong COUNTDOWN: **BR-64** (Q-84).

---

## US-03.03 Giao diện tối tĩnh và chỉ báo “Phiên đang được ghi”

**Là một** thành viên đang tập trung, **tôi muốn** màn hình phiên tối, tĩnh, ít tiêu thụ pin và luôn biết khi nào đang bị ghi **để** không bị xao nhãng và yên tâm về quyền riêng tư.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.2, §6; D-08 · Liên quan: BR-05, BR-15, BR-34; NFR-P02, NFR-P08

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.03.1 | Bình thường | Thành viên FOCUSING | Xem màn phiên | Nền tối, không hoạt ảnh liên tục; hiện thời gian còn lại (tính từ `ends_at` server), nút “Rời phiên” (AC-03.04.7), nút “Tạm dừng” *(chỉ kiểm khi US-03.06 — Should — trong phạm vi)*, chỉ báo “Phiên đang được ghi” (BR-05) |
| AC-03.03.2 | Bình thường | Thành viên FOCUSING | Úp máy / để màn hình tự tắt | Không giữ màn hình sáng; không ghi sự kiện thoát (BR-15, D-08) |
| AC-03.03.3 | Lỗi | Thành viên đã ở trạng thái kết thúc (COMPLETED/EXITED/LOST/WITHDRAWN/VOID) | Xem app | Chỉ báo “Phiên đang được ghi” biến mất; không gửi thêm sự kiện (BR-05, NFR-P08) |
| AC-03.03.4 | Biên | Màn phiên | Kiểm tra dữ liệu gửi đi | Chỉ có loại sự kiện vòng đời + thời điểm; không có tên app, nội dung, vị trí (BR-34) |
| AC-03.03.5 | Biên | FOCUSING đã báo khóa màn hình, phiên 50 phút | Đo pin và lưu lượng mạng trên máy thật iOS và Android | Đạt ngưỡng NFR-08; client giảm/ngừng heartbeat khi khóa màn hình (BR-66) |

**Ghi chú / giả định:** Yêu cầu “tối, tĩnh” là UI/NFR pin, không cần BR. Số người trong phòng có hiện trong phiên hay không: không hiện danh sách tên trạng thái của người khác **(giả định)** để giữ NFR-P06. Chủ nhóm cũng **không** xem trạng thái từng người theo thời gian thực trong phiên (FOCUSING/GRACE/PAUSED/DISCONNECTED); chỉ nhận `MEMBER_EXITED` sau khi server xác nhận và xem chi tiết phiên ở US-08.10 (BR-28, NFR-P02; AC-08.10.4).

---

## US-03.04 Phát hiện rời app (khóa màn hình không tính)

**Là một** thành viên, **tôi muốn** hệ thống chỉ ghi nhận khi tôi thật sự rời app, không tính khi tôi khóa hay tắt màn hình **để** không bị phạt oan.

- Ưu tiên: Must · Ước lượng: L · Nguồn: GĐ1 §4.2, §10 #1; D-07, D-08, D-29 · Liên quan: BR-11, BR-15, BR-31, BR-34, BR-118; NFR-03, NFR-04, NFR-P15, NFR-19

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.04.1 | Bình thường | FOCUSING, còn lượt khoan hồng | Chuyển sang app khác / đưa app xuống nền (iOS và Android) | Client gửi sự kiện rời app ≤ 1 giây; server chuyển GRACE, đặt hạn 3 giây theo giờ server (BR-11, NFR-03) |
| AC-03.04.2 | Bình thường | FOCUSING | Khóa màn hình hoặc tắt màn hình | Vẫn FOCUSING; không ghi sự kiện rời app (BR-15, NFR-P15) |
| AC-03.04.3 | Bình thường | FOCUSING, đã khóa màn hình | Mở khóa rồi mở app khác | Tính rời app từ lúc rời app → GRACE (BR-15; §3 #17) |
| AC-03.04.4 | Lỗi | GRACE | Client gửi trùng sự kiện rời app / cùng `event_id` | Bỏ qua, trả kết quả cũ (BR-31; §3 #9, #10) |
| AC-03.04.5 | Biên | 20 lần khóa–mở khóa mỗi nền tảng | Kiểm thử máy thật | 0 sự kiện thoát (NFR-04, NFR-P15) |
| AC-03.04.6 | Lỗi | FOCUSING | Thành viên **chủ động** rời: bấm nút Back/Home, mở app khác, hoặc vuốt tắt app từ trình đa nhiệm | Xử lý như rời app: → GRACE (hoặc EXITED ngay nếu hết lượt khoan hồng, BR-13); không quay lại trước hạn → EXITED, kích hoạt BR-35. Không có lối "thoát phiên không bị tính". Vuốt tắt app: app xuống nền trước nên client gửi rời app trước khi socket đóng; socket đóng trong GRACE không đổi thành DISCONNECTED/LOST (AC-03.07.5) (BR-11, BR-13, BR-14) **(giả định, Q-61 — cần spike xác nhận client kịp gửi trên iOS/Android)** |
| AC-03.04.7 | Bình thường | FOCUSING, phiên ACTIVE | Bấm nút **"Rời phiên"** trên màn phiên | Hiện hộp xác nhận nêu hệ quả: "Cả phiên mất thưởng, chuỗi của bạn bị ngắt, cả nhóm thấy tên bạn". Bấm "Xác nhận" → server chuyển EXITED ngay theo giờ server (không qua GRACE), kích hoạt `forfeited` (BR-35), phát `MEMBER_EXITED`, 0 Coins, ngắt chuỗi; màn chuyển sang kết quả (BR-118, D-29, D-05, D-20, D-22). Không có lối "thoát phiên không bị tính"; cách ngừng không bị ghi thoát chỉ là tạm dừng (US-03.06, Should) hoặc rút đồng ý (BR-26 → WITHDRAWN). *(Viết lại 2026-10-19 theo D-29, T-BA-123.)* |
| AC-03.04.8 | Bình thường | Hộp xác nhận "Rời phiên" đang mở | Bấm "Hủy" (hoặc đóng hộp) | Hộp đóng, quay lại màn phiên, trạng thái giữ nguyên FOCUSING; không gửi sự kiện, không ghi gì (BR-118, D-29) |
| AC-03.04.9 | Lỗi | Hộp xác nhận đang mở; máy mất kết nối (DISCONNECTED) | Bấm "Xác nhận" | Client không gửi được `session:leave`; báo "Chưa rời phiên — không có kết nối"; **không** xếp hàng gửi sau; trạng thái giữ nguyên, màn phiên vẫn hiện. Khi nối lại, người dùng phải bấm "Rời phiên" lại nếu vẫn muốn rời. Nếu trong lúc mất mạng đã thành LOST hoặc phiên đã COMPLETED thì giữ kết quả đó (BR-118 (3), BR-21, BR-32, BR-33) |
| AC-03.04.10 | Biên | (a) WAITING ở phòng chờ V-06 (phiên SCHEDULED); (b) màn đếm ngược 5s V-07 (COUNTDOWN); (c) thành viên GRACE hoặc PAUSED *(PAUSED chỉ kiểm khi US-03.06 trong phạm vi)* | (a) Bấm "Rời phiên" rồi xác nhận; (b) rà màn đếm ngược; (c) bấm "Rời phiên" rồi xác nhận | (a) Hộp xác nhận nêu "bạn sẽ bị ghi vắng"; xác nhận → ABSENT, không `MEMBER_EXITED`, không kích hoạt `forfeited`, không vào lại được phiên đó (BR-118 (2), BR-32) **(giả định, Q-149)**. (b) Màn đếm ngược **không** có nút "Rời phiên"; rời app trong COUNTDOWN theo BR-64 (AC-03.02.4). (c) EXITED ngay, hủy hẹn GRACE/PAUSED đang chạy, hệ quả như AC-03.04.7 (BR-118 (1), D-29) |

**Ghi chú / giả định:** Cách phân biệt khóa màn hình và rời app trên iOS chờ spike (Q-61). Hệ điều hành treo socket khi khóa màn hình có thể sinh DISCONNECTED giả → phụ thuộc Q-61.

---

## US-03.05 Khoan hồng 3 giây

**Là một** thành viên, **tôi muốn** có 3 giây để quay lại khi lỡ tay rời app **để** một thao tác nhầm không làm cả nhóm mất thưởng.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.2, §4.3; `05-tham-chieu-ky-thuat.md` §1; D-05 · Liên quan: BR-11, BR-12, BR-13, BR-14, BR-33, BR-35

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.05.1 | Bình thường | GRACE (lượt khoan hồng đầu tiên) | Quay lại app trước hạn | → FOCUSING; ghi `grace_recovered`; không gửi thông báo cho ai; không đổi `forfeited` (BR-12, BR-36) |
| AC-03.05.2 | Lỗi | GRACE | Hết hạn 3 giây chưa quay lại | → EXITED; ghi sự kiện thoát giờ server; gửi `MEMBER_EXITED` theo BR-27 (US-03.09); áp BR-35 (BR-14) |
| AC-03.05.3 | Lỗi | FOCUSING, đã dùng hết lượt khoan hồng | Rời app lần nữa | → EXITED ngay, không qua GRACE (BR-13) |
| AC-03.05.4 | Biên | GRACE | Server nhận `return` ở 2,9 giây | FOCUSING, không ghi thoát (BR-12, BR-33) |
| AC-03.05.5 | Biên | GRACE | Server nhận `return` ở 3,0 giây hoặc sau, sau khi `grace_timeout` đã xử lý | EXITED giữ nguyên; `return` bị bỏ qua (BR-32, BR-33; §3 #11) |
| AC-03.05.6 | Biên | GRACE | Bấm “Tạm dừng” | Không cho; phải về app trước (§3 #14) |
| AC-03.05.7 | Biên | GRACE còn 1 giây | Đến `ends_at` | COMPLETED (§3 #6) |

**Ghi chú / giả định:** Client có hiện đếm ngược 3 giây (thông báo cục bộ “Quay lại ngay”) không — đề xuất có, dạng thông báo cục bộ không gửi server **(đề xuất, Q-85)**. Ranh giới đúng 3,000 giây: **BR-65** (hạn nửa mở — quay lại đúng 3,000s là quá hạn).

---

## US-03.06 Tạm dừng có lý do

**Là một** thành viên, **tôi muốn** tạm dừng một lần có lý do (cuộc gọi, việc gấp) **để** xử lý việc thật mà không làm cả nhóm mất thưởng.

- Ưu tiên: Should (D-13) · Ước lượng: M · Nguồn: GĐ1 §6; D-13; Q-11, Q-15 · Liên quan: BR-16, BR-17, BR-18, BR-36, BR-67

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.06.1 | Bình thường | FOCUSING, còn lượt tạm dừng | Bấm “Tạm dừng”, chọn lý do trong danh sách | → PAUSED; server hẹn 5 phút; ghi lý do; rời app trong PAUSED không ghi thoát, không kích hoạt BR-35 (BR-16, BR-36) |
| AC-03.06.2 | Bình thường | PAUSED | Bấm “Tiếp tục” | → FOCUSING; ghi thời lượng tạm dừng; `ends_at` không đổi; phút tạm dừng không cộng vào phút tập trung (BR-17) |
| AC-03.06.3 | Lỗi | FOCUSING, đã dùng lượt tạm dừng | Bấm “Tạm dừng” | Từ chối, giữ FOCUSING, hiện “Bạn đã dùng lượt tạm dừng” (§3 #13) |
| AC-03.06.4 | Lỗi | Bấm “Tạm dừng” | Không chọn lý do | Không gửi được; vẫn FOCUSING (BR-16) |
| AC-03.06.5 | Biên | PAUSED, đang ở app | Hết đúng 5 phút | → FOCUSING (BR-18) |
| AC-03.06.6 | Biên | PAUSED, không ở app | Hết 5 phút | → GRACE 3 giây, không trừ lượt khoan hồng; về app trước hạn → FOCUSING, không → EXITED (BR-18; §3 #4) |
| AC-03.06.7 | Biên | PAUSED | Đến `ends_at` | COMPLETED; phút tạm dừng không tính (§3 #5) |

**Ghi chú / giả định:** Danh sách lý do mặc định trong `pause_reasons`: **BR-67** ( “Cuộc gọi”, “Việc gấp của công việc”, “Việc cá nhân khẩn”, “Khác”). PAUSED không gửi thông báo cho người khác (D-20; 03-quy-tac ma trận thông báo); lý do tạm dừng chỉ hiện ở chi tiết phiên/báo cáo.

---

## US-03.07 Mất kết nối giữa phiên

**Là một** thành viên, **tôi muốn** được giữ chỗ khi mạng chập chờn **để** không bị ghi oan là thoát.

- Ưu tiên: Must · Ước lượng: L · Nguồn: GĐ1 §10 #3 (giảm phạt oan); D-05 (chỉ EXITED gây mất thưởng tập thể), D-08, D-19 (LOST không làm phiên mất thưởng); `05-tham-chieu-ky-thuat.md` §5 · Liên quan: BR-19, BR-20, BR-21, BR-36, BR-65, BR-66; §3 #1, #2, #7, #40–#43

Mốc dùng trong mọi AC dưới đây (BR-19): `last_seen_at` = lần cuối server nhận gói của (người, phiên); `disconnected_at` = sớm hơn giữa lúc socket đóng và `last_seen_at + 10s`; hạn giữ chỗ = `disconnected_at + 10s` (nửa mở, BR-65).

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.07.1 | Bình thường | FOCUSING hoặc PAUSED, chưa báo khóa màn hình; `last_seen_at` = T | Không gói nào tới | Tại T + 10s → DISCONNECTED, ghi `disconnected_at` = T + 10s, nhớ trạng thái trước; hẹn LOST tại T + 20s (BR-19, BR-66; §3 #42) |
| AC-03.07.2 | Bình thường | DISCONNECTED, `disconnected_at` = D | Kết nối lại kèm `session_id` khi `t < D + 10s` | Về đúng trạng thái trước (FOCUSING/PAUSED); ghi `reconnected`; thời gian DISCONNECTED không cộng phút tập trung (BR-20) |
| AC-03.07.3 | Lỗi | DISCONNECTED, `disconnected_at` = D | Đến D + 10s chưa nối lại | → LOST; ghi “mất kết nối” tách khỏi thoát; **không** gửi `MEMBER_EXITED` hay thông báo nào cho người khác; chỉ người đó không nhận Coins phiên; **không** đặt `forfeited` (BR-21, BR-36, D-19) |
| AC-03.07.4 | Lỗi | DISCONNECTED | Nối lại và báo đã rời app lúc mất mạng | Áp BR-11/BR-13 tính từ lúc nối lại (§3 #2) |
| AC-03.07.5 | Biên | GRACE | Mất kết nối | Không chuyển DISCONNECTED; hạn 3 giây vẫn chạy trên server; hết hạn → EXITED (§3 #1, Q-30) |
| AC-03.07.6 | Biên | DISCONNECTED, `disconnected_at` = D | Server nhận kết nối lại ở D + 9,999s / D + 10,000s | D + 9,999s → trạng thái trước; D + 10,000s → LOST, kết nối lại không đổi kết quả (BR-19, BR-65, BR-32; §3 #41) |
| AC-03.07.7 | Biên | FOCUSING, `last_seen_at` = T | Gói kế tiếp đến ở T + 9,999s / không đến trước T + 10,000s | T + 9,999s → vẫn FOCUSING, `last_seen_at` cập nhật; tại T + 10,000s → DISCONNECTED (BR-66, BR-65) |
| AC-03.07.8 | Biên | DISCONNECTED, `disconnected_at` = D, `ends_at` < D + 10s | Kết nối lại khi `t < D + 10s` (kể cả sau `ends_at`) / không nối lại | Nối lại → COMPLETED, phút tính đến D; không nối lại → LOST tại D + 10s. Không có hạn riêng `ends_at + 10s` (§3 #7) **(đề xuất, Q-31)** |
| AC-03.07.9 | Biên | FOCUSING, client đã báo khóa màn hình | Socket đóng / không heartbeat 60 giây | Không DISCONNECTED; sau khi client báo mở khóa, `last_seen_at` = lúc nhận báo mở khóa và áp lại ngưỡng 10s (BR-66; §3 #40, #43) **(đề xuất, Q-61)** |
| AC-03.07.10 | Bình thường | Phiên 25 phút, `forfeited = false`; X → LOST ở phút 10; không ai EXITED | Đến `ends_at` | Phiên không `forfeited`; người khác COMPLETED là **hoàn thành có thưởng** và nhận Coins; X giữ LOST, 0 Coins; chuỗi của X theo BR-48 (D-19, BR-21, BR-24) |

**Ghi chú / giả định:** Tính từ heartbeat cuối, LOST chậm nhất sau 20 giây với mặc định (BR-19 mục 5) — câu “mất mạng quá 10 giây” trong 01 §8 nghĩa là 10 giây kể từ `disconnected_at`. Client hiện “Đang kết nối lại…” khi mất mạng **(giả định)**.

---

## US-03.08 Ghi nhận mất thưởng tập thể khi có người thoát

**Là một** thành viên, **tôi muốn** phiên tiếp tục đến hết giờ dù có người thoát **để** vẫn hoàn thành buổi tập trung của mình, dù cả phiên mất Coins và chuỗi theo luật nhóm.

- Ưu tiên: Must · Ước lượng: M · Nguồn: D-05, D-19; GĐ1 §4.3 · Liên quan: BR-14, BR-21, BR-27, BR-35, BR-36, BR-37, BR-39; §3 #19–#24, #27

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.08.1 | Bình thường | Phiên ACTIVE, `forfeited = false` | Thành viên A → EXITED | Server đặt `forfeited = true`, ghi `forfeited_at` (giờ server), `forfeit_trigger_user_id = A`; phiên vẫn ACTIVE; người khác giữ nguyên trạng thái (BR-35) |
| AC-03.08.2 | Bình thường | `forfeited = true` | Thành viên B → EXITED | Ghi EXITED + gửi `MEMBER_EXITED` (không gửi lại `SESSION_FORFEITED`); không đổi `forfeit_trigger_user_id` (BR-39) |
| AC-03.08.3 | Lỗi | Phiên ACTIVE | Thành viên GRACE rồi quay lại / PAUSED / LOST / WITHDRAWN | `forfeited` giữ `false` (BR-36; LOST theo D-19) |
| AC-03.08.4 | Lỗi | `forfeited = true` | Bất kỳ yêu cầu đặt lại `false` (trừ sự cố BR-22) | Từ chối; cờ một chiều (BR-35) |
| AC-03.08.5 | Biên | `forfeited = false` | Hai người EXITED cách nhau vài mili-giây | Người server nhận trước là khởi phát; người sau ghi như BR-39 (§3 #19) |
| AC-03.08.6 | Biên | Phiên chỉ có 1 người | Người đó EXITED | `forfeited = true`; phạm vi chỉ chính người đó (§3 #27) |
| AC-03.08.7 | Biên | Đã có LOST trước | Người khác EXITED | `forfeited = true`; người LOST nằm trong phạm vi BR-37 (§3 #24) |
| AC-03.08.8 | Biên | Phiên 10 người; 3 người LOST, không ai EXITED | Đến `ends_at` | `forfeited` vẫn `false`; 7 người COMPLETED nhận Coins; 3 người LOST 0 Coins; không ai nhận thông báo mất thưởng (D-19, BR-21, BR-36) |
| AC-03.08.9 | Bình thường | Phiên ACTIVE, `forfeited = false` | Thành viên A chủ động rời (AC-03.04.6) và không quay lại trong 3 giây | A → EXITED; phiên `forfeited = true`, `forfeit_trigger_user_id = A` — giống hệt rời app do lỡ tay; không có loại "rời có chủ ý" riêng (BR-14, BR-35) |

**Ghi chú / giả định:** Tính Coins/chuỗi do EP-05, EP-06 thực hiện; story này chỉ đặt cờ. Số người LOST lớn có thể chạm ngưỡng sự cố BR-22 (US-03.12) — AC-03.08.8 giả sử chưa chạm ngưỡng.

---

## US-03.09 Thông báo người thoát và mất thưởng tập thể

**Là một** thành viên của nhóm, **tôi muốn** được báo ngay, kèm tên, khi có người thoát và phiên mất thưởng tập thể **để** biết rõ vì sao cả phiên mất Coins và giữ trách nhiệm với nhóm.

- Ưu tiên: Must · Ước lượng: **M** (tăng từ S: gửi cả nhóm + cả phiên, hai kênh push/banner, D-20, D-22) · Nguồn: D-05, D-20, D-22; GĐ1 §4.3, §6 · Liên quan: BR-27, BR-28, BR-34, BR-38, BR-39, BR-53, BR-81, BR-82; NFR-02, NFR-P06, NFR-P18; ma trận 04-nfr §3; ma trận thông báo 03-quy-tac

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.09.1 | Bình thường | Nhóm có CN + 7 TV; phiên ACTIVE `forfeited = false` có A, B, C tham gia; D là TV ABSENT; CN không tham gia | A → EXITED lúc 09:10:03 (giờ server) | Mọi người trừ A (B, C, D, CN và các TV còn lại của nhóm) nhận **một** thông báo gộp `MEMBER_EXITED` + `SESSION_FORFEITED`: “Phiên đã mất thưởng tập thể do ‹Tên A› rời phiên — vẫn tiếp tục đến hết giờ”, kèm giờ 09:10:03 (BR-27, BR-38, D-20, D-22) |
| AC-03.09.2 | Lỗi | Như AC-03.09.1 | Kiểm tra payload push, hộp thông báo, banner, API kết quả phiên bằng token của B và D | Chỉ có tên A, “đã rời phiên”, giờ server; **không** có tên app, lý do tạm dừng, giải trình/khiếu nại, Coins, số lần thoát tích lũy của A (BR-27, BR-34, BR-53, NFR-P06, NFR-P18) |
| AC-03.09.3 | Bình thường | Người nhận **không** có trạng thái chưa kết thúc trong phiên (D ABSENT, CN không tham gia, TV không được mời, người đã COMPLETED/EXITED/LOST trước) | A EXITED | Nhận push hệ thống + bản lưu trong hộp thông báo (BR-27, BR-81; ma trận §3 #48, #49) |
| AC-03.09.4 | Biên | A ở GRACE, hạn 3 giây hết lúc T | Server xác nhận EXITED tại T | `MEMBER_EXITED` được server phát ≤ 5 giây sau T (`notify_latency_s`); không gửi gì lúc A bắt đầu GRACE hay khi A quay lại trước hạn (BR-28, BR-12) |
| AC-03.09.5 | Biên | `forfeited = true` (A khởi phát) | B EXITED sau đó; hoặc A và B EXITED cách nhau vài mili-giây | Mọi người nhận `MEMBER_EXITED` có tên B; **không** nhận lại `SESSION_FORFEITED`; tên khởi phát là người server nhận trước (BR-39; §3 #19, #20) |
| AC-03.09.6 | Bình thường | B đang FOCUSING, app ở tiền cảnh, màn hình mở | A EXITED, phiên → `forfeited` | B thấy banner trong app có tên A ≤ 2 giây (p95) (NFR-02); banner không chặn thao tác, không âm thanh, tự ẩn (BR-82) |
| AC-03.09.7 | Bình thường | Phiên đã `forfeited` do A | Đến `ends_at`, B COMPLETED | B nhận `SESSION_RESULT`; màn kết quả ghi “Hoàn thành – 0 Coins – lý do: mất thưởng tập thể do ‹Tên A› rời phiên”; chuỗi bị ngắt (BR-38, BR-41, BR-47, D-22) |
| AC-03.09.8 | Bình thường | A là người thoát | A mở màn kết quả | A thấy mình là người khởi phát; A **không** nhận `MEMBER_EXITED` về chính mình (BR-27, NFR-P03) |
| AC-03.09.9 | Lỗi | B đang úp máy (khóa màn hình) hoặc GRACE; *(PAUSED: chỉ kiểm khi US-03.06 trong phạm vi)* | A EXITED, phiên → `forfeited` | Trong lúc B chưa ở trạng thái kết thúc: **không** push hệ thống, **không** thông báo cục bộ trên màn khóa; thông báo xếp hàng, hiện banner ≤ 2 giây (p95) sau khi B mở khóa/quay lại app; vẫn lưu trong hộp thông báo (BR-82, BR-81) |
| AC-03.09.10 | Biên | Phiên chỉ có A tham gia; nhóm có CN + 4 TV khác | A EXITED | `forfeited = true` (§3 #27); CN và 4 TV nhận push + hộp thông báo có tên A (BR-27 mục a) |
| AC-03.09.11 | (Chuyển) | — | — | Chuyển sang AC-03.12.6 (T-BA-58: kiểm hành vi sự cố BR-22 thuộc US-03.12 Should). Không dùng lại mã này. |
| AC-03.09.12 | Lỗi | Phiên ACTIVE | X → LOST / PAUSED / ABSENT / WITHDRAWN / GRACE rồi quay lại | **Không** ai khác nhận thông báo về X; không đặt `forfeited` (BR-21, BR-26, BR-36, D-19; ma trận thông báo 03-quy-tac) **(giả định, Q-136)** |

**Ghi chú / giả định:** Viết lại 2026-10-07 theo D-20, D-22 (thay bản “không nêu tên”, BR-38 cũ, NFR-P16 cũ). Chủ nhóm không tham gia phiên (D-25) nên không bao giờ là người khởi phát; chủ nhóm luôn là người nhận `MEMBER_EXITED` (AC-03.09.1, .3, .10). Kênh khi đang trong phiên theo BR-82 (đề xuất, Q-87). Người vào muộn sau `forfeited_at` được cảnh báo theo BR-37 (US-03.11). Thành viên khác **không** thấy số lần thoát tích lũy của A **(giả định, Q-137)**. Đính chính khi khiếu nại được miễn trừ (`EXEMPTION_GRANTED`) thuộc EP-04 (Q-138). Gộp từ US-04.02 (Hủy, D-14) giữ nguyên lịch sử mã.

---

## US-03.10 Kết thúc phiên và xem kết quả

**Là một** thành viên, **tôi muốn** phiên tự kết thúc đúng giờ và thấy kết quả của mình **để** biết mình đã hoàn thành và vì sao nhận/không nhận Coins.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.5; D-05, D-09 · Liên quan: BR-23, BR-24, BR-32, BR-33, BR-37, BR-41; §2.1 dòng “Đến `ends_at`”

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.10.1 | Bình thường | FOCUSING, `forfeited = false` | Đến `ends_at` | → COMPLETED (**hoàn thành có thưởng**, D-11); phiên → COMPLETED; màn kết quả hiện phút tập trung (FOCUSING + GRACE hồi phục) và Coins theo §Thưởng; dừng ghi (BR-23, BR-24, BR-05) |
| AC-03.10.2 | Bình thường | FOCUSING, `forfeited = true` | Đến `ends_at` | → COMPLETED (**hoàn thành** nhưng không phải hoàn thành có thưởng, D-11); phút được tính; vẫn tính điểm danh (BR-46); Coins = 0, lý do “mất thưởng tập thể do ‹Tên› rời phiên” (BR-38, D-22); chuỗi ngắt (BR-23, BR-37, BR-41, BR-47) |
| AC-03.10.3 | Lỗi | Thành viên đã EXITED/LOST | Đến `ends_at` | Giữ trạng thái kết thúc; không chuyển COMPLETED; 0 Coins (BR-32). LOST trong phiên không `forfeited` không ảnh hưởng người khác (D-19) |
| AC-03.10.4 | Lỗi | Phiên đã COMPLETED | Client gửi sự kiện sau `ends_at` | Bỏ qua (BR-33) |
| AC-03.10.5 | Biên | Phiên 50 phút; mọi thành viên đã kết thúc ở phút 20 | Thời gian trôi | Phiên vẫn ACTIVE đến `ends_at` rồi COMPLETED (§2.1) |
| AC-03.10.6 | Biên | Client tắt màn hình lúc `ends_at` | Mở app sau đó | Thấy kết quả do server chốt; không cần client online đúng `ends_at` (BR-03) |
| AC-03.10.7 | Lỗi | Phiên lịch 09:00:00; thành viên X vẫn INVITED (không vào phòng chờ); US-03.11 ngoài phạm vi nên hạn vào muộn = 0 (`late_join_max_min = 0`, BR-112) | Giờ server đến `started_at` | X → ABSENT ngay; không thông báo cho người khác, không đặt `forfeited`, không ngắt chuỗi, 0 Coins; màn kết quả của X ghi “Vắng” (BR-08, BR-24, BR-36) |
| AC-03.10.8 | Biên | Phiên lịch 09:00:00; nhóm CN + 4 TV; không TV nào vào phòng chờ | Giờ server đến `started_at` (hạn vào = 0) | 4 TV → ABSENT trước, rồi phiên → CANCELLED (BR-30, BR-08); chủ nhóm không có bản ghi trong phiên (D-25) **(giả định, T-BA-70)** |

**Ghi chú / giả định:** Có thông báo cục bộ “Phiên đã kết thúc” cho người úp máy **(giả định)**. AC-03.10.7–8 đưa việc ghi ABSENT vào phạm vi Must (T-BA-70): khi làm US-03.11 thì hạn vào đổi thành `late_join_max_min` (5 phút) và AC-03.11.3–5 thay thế mốc `started_at`. Quy tắc “không làm vào muộn → hạn vào = `started_at`” đã có ở BR-08 (`late_join_max_min = 0`; T-BA-127).

---

## US-03.11 Vào muộn và vắng mặt

**Là một** thành viên đến trễ, **tôi muốn** vẫn tham gia phần còn lại của phiên nếu trễ không quá 5 phút **để** không mất cả buổi vì trễ vài phút.

- Ưu tiên: Should (D-13; 01 §5) · Ước lượng: M · Nguồn: GĐ1 §4.1 (khung giờ chung theo lịch); D-05 (cảnh báo khi vào phiên đã mất thưởng), D-06, D-13; Q-18, Q-41 · Liên quan: BR-04, BR-07, BR-08, BR-09, BR-30, BR-37, BR-42, BR-65

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.11.1 | Bình thường | Phiên ACTIVE, `forfeited = false`, 3 phút sau `started_at`; thành viên INVITED đã đồng ý | Bấm vào phiên | → FOCUSING ngay (không đếm ngược); gắn cờ “vào muộn”; bắt đầu ghi (BR-07) |
| AC-03.11.2 | Bình thường | Phiên ACTIVE, `forfeited = true`, trong hạn vào muộn | Bấm vào phiên | Hiện cảnh báo “Phiên đã mất thưởng tập thể; vào thì bạn cũng mất Coins và chuỗi”; xác nhận → FOCUSING chịu BR-37; từ chối → vẫn INVITED, quá hạn thành ABSENT (BR-37; §3 #25) |
| AC-03.11.3 | Lỗi | 5 phút đã qua kể từ `started_at` | Bấm vào phiên | Từ chối “Đã quá thời gian vào muộn”; thành viên → ABSENT; không thông báo cho người khác, không kích hoạt BR-35, không ngắt chuỗi (BR-08) |
| AC-03.11.4 | Biên | Server nhận yêu cầu vào ở 4:59 / 5:00 sau `started_at` | Bấm vào phiên | 4:59,999 → FOCUSING (vào muộn); 5:00,000 → ABSENT (mốc nửa mở, BR-65; `started_at` = giờ lịch, BR-04) |
| AC-03.11.5 | Biên | Phiên ACTIVE, không ai vào | Hết hạn vào muộn | Phiên → CANCELLED; tất cả INVITED → ABSENT (BR-30, BR-08) |

**Ghi chú / giả định:** Ranh giới đúng 5:00: **BR-65** (vào đúng 5:00 là quá hạn). BR-30 đã sửa: ghi ABSENT trước rồi mới CANCELLED, không VOID (Q-88).

---

## US-03.12 Phiên bị hủy do sự cố server

**Là một** thành viên, **tôi muốn** không bị phạt khi lỗi do hệ thống **để** tin tưởng vào tính công bằng của app.

- Ưu tiên: Should (D-13) · Ước lượng: M · Nguồn: GĐ1 §10 #3 (không phạt oan); D-05 (gỡ mất thưởng tập thể khi lỗi hệ thống), D-13, D-19; `05-tham-chieu-ky-thuat.md` §5; Q-28, Q-123 · Liên quan: BR-22, BR-32, BR-35, BR-68; NFR-15; §3 #8, #28, #44, #45

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.12.1 | Bình thường | Phiên ACTIVE; không ai EXITED trước sự cố | Server lỗi / khởi động lại | Phiên → CANCELLED; mọi thành viên chưa kết thúc → VOID; không ai nhận Coins, không ai bị ngắt chuỗi; mọi người trong phiên nhận `SESSION_CANCELLED_OUTAGE` “Phiên đã hủy do sự cố hệ thống” ≤ 15 giây (BR-22, NFR-15). Người đã LOST trước sự cố giữ LOST (BR-22) |
| AC-03.12.2 | Bình thường | `forfeited = true`, A đã EXITED trước sự cố, B đang FOCUSING | Phiên CANCELLED do sự cố trước `ends_at` | Gỡ `forfeited`; B → VOID, không ngắt chuỗi; **ngoại lệ BR-68:** A giữ EXITED và giữ ngắt chuỗi cá nhân, nhận `SESSION_CANCELLED_OUTAGE_EXITED` (khác thông báo hủy chung) kèm lối khiếu nại; `MEMBER_EXITED` đã gửi cả nhóm không thu hồi (BR-68; §3 #28, #45) **(đề xuất, Q-123)** |
| AC-03.12.3 | Lỗi | 2/10 thành viên đang hoạt động mất kết nối trong 10 giây (dưới ngưỡng) | Hết hạn giữ chỗ | Không coi là sự cố; xử lý theo US-03.07 (LOST) (BR-22) |
| AC-03.12.4 | Biên | ≥ 80% thành viên đang hoạt động mất kết nối trong cửa sổ 10 giây | Server phát hiện | Coi là sự cố → như AC-03.12.1 (BR-22) |
| AC-03.12.5 | Biên | Thông báo sự cố | Thành viên và chủ nhóm nhận | `SESSION_CANCELLED_OUTAGE` không nêu cá nhân (ma trận thông báo 03-quy-tac) |
| AC-03.12.6 | Lỗi | Phiên `forfeited` (A khởi phát), B đang FOCUSING, rồi CANCELLED do sự cố (BR-22) | Phiên hủy | B → VOID, nhận `SESSION_CANCELLED_OUTAGE` “Phiên bị hủy do sự cố — kết quả của bạn không bị tính”; banner mất thưởng trước đó được thay thế; `forfeited` gỡ (BR-22). A nhận `SESSION_CANCELLED_OUTAGE_EXITED` (BR-68). *(Chuyển từ AC-03.09.11 — T-BA-58)* |

**Ghi chú / giả định:** Ngưỡng 80% đặt “trên mọi nhóm của server” nên mất mạng cục bộ văn phòng (cả nhóm cùng mạng) có thể không đạt ngưỡng → cả nhóm LOST (Q-28). AC-03.12.5 áp cho thông báo chung; thông báo riêng của người EXITED trước sự cố theo BR-68 chỉ gửi cho chính người đó.

---

## US-03.13 Chủ nhóm tham gia phiên của nhóm mình (Hủy — D-25)

Hủy 2026-10-19 theo D-25: chủ nhóm **không** tham gia phiên, chỉ quản lý. Mã AC-03.13.1–5 không dùng lại. Ca thay thế: chủ nhóm bị từ chối vào phòng chờ (AC-03.01.3); chủ nhóm luôn nhận `MEMBER_EXITED` (AC-03.09.1, .10); chủ nhóm không có dòng trong báo cáo (EP-08). Khái niệm “nhóm tham gia” (BR-114) không còn áp dụng. Q-19, Q-135, Q-139 → D-25; Q-67 không còn áp dụng.

---

## US-03.14 Lịch sử phiên của tôi

**Là một** thành viên, **tôi muốn** xem lại các phiên tôi đã được mời và kết quả của mình **để** hiểu vì sao từng phiên có hoặc không có Coins.

- Ưu tiên: Should **(giả định — mockup-tong-hop S10, T-BA-102)** · Ước lượng: S **(giả định)** · Nguồn: GĐ1 §4.5, §6; D-05, D-11, D-12, D-19, D-22 · Liên quan: BR-21, BR-22, BR-23, BR-24, BR-32, BR-38, BR-41, BR-53, BR-68, BR-103, BR-115, BR-119; NFR-P03, NFR-P06, NFR-P11, NFR-P18, NFR-11; Q-101

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-03.14.1 | Bình thường | X có các phiên đã kết thúc: COMPLETED (không `forfeited`), COMPLETED (`forfeited` do A), EXITED, LOST, ABSENT; một phiên CANCELLED khi X ở VOID | X mở "Lịch sử phiên" | Mỗi dòng: tên lịch, ngày giờ (giờ server, Asia/Ho_Chi_Minh), thời lượng, kết quả của X: "Hoàn thành có thưởng — +N Coins" / "Hoàn thành — 0 Coins — mất thưởng tập thể do ‹A› rời phiên" / "Rời app" / "Mất kết nối" / "Vắng" / "Phiên bị hủy — không tính" (D-11, D-19, D-22, BR-22, BR-38, BR-41) |
| AC-03.14.2 | Bình thường | Như AC-03.14.1 | Xem thứ tự | Mới nhất trước theo `started_at`; không sắp theo kết quả hay Coins |
| AC-03.14.3 | Lỗi (riêng tư) | Như AC-03.14.1 | Rà màn và API | Chỉ có kết quả của chính X; không có trạng thái/Coins/giải trình của người khác (trừ tên người khởi phát ở phiên `forfeited`, BR-38); không tên app (BR-34, NFR-P06, NFR-P18) |
| AC-03.14.4 | Lỗi | Người khác (kể cả chủ nhóm của X) | Gọi API lịch sử phiên của X | 403 — chủ nhóm xem qua US-05.09 / US-08.10, không qua màn này (NFR-11) |
| AC-03.14.5 | Lỗi | Lỗi tải trang kế tiếp | Cuộn xuống | Hiện lỗi + "Thử lại"; các dòng đã tải giữ nguyên |
| AC-03.14.6 | Biên | X chưa có phiên nào kết thúc | Mở "Lịch sử phiên" | Hiện "Chưa có phiên nào"; không lỗi |
| AC-03.14.7 | Biên | X rời nhóm A rồi vào nhóm B (D-21) | Mở lịch sử | Thấy cả phiên của A (đến ngày rời) và B, mỗi dòng ghi tên nhóm; giữ trong thời hạn lưu (BR-103) **(giả định)** |
| AC-03.14.8 | Biên | Phiên đang ACTIVE | Mở lịch sử | Phiên đang chạy không có trong lịch sử; chỉ hiện khi đã có trạng thái kết thúc |

**Ghi chú / giả định:** Story mới 2026-10-19 (mockup-tong-hop S10). Khác US-05.08 (lịch sử chuỗi/huy hiệu) và US-06.02 (sổ cái Coins): màn này theo phiên. Dòng "0 Coins" không ghi vào sổ cái (Q-101, BR-41). Chạm một dòng mở màn kết quả phiên (US-03.10). Ưu tiên Should cần điều phối viên xác nhận.

---

## Truy vết

Cập nhật 2026-10-19 (D-25, review lần 3: T-BA-70, T-BA-73). Trước đó 2026-10-07 (D-19…D-22, review lần 2). Dòng tương ứng trong `ba/03-truy-vet.md` cần cập nhật theo bảng này (điều phối viên ghi). **Ước lượng Must thay đổi:** US-03.09 S → M (D-20, D-22). Các story Must khác giữ nguyên ước lượng.

| US | Nguồn | MoSCoW | BR | NFR | AC |
| --- | --- | --- | --- | --- | --- |
| US-03.01 | GĐ1 §4.1, §4.2; D-06, D-25 | Must | BR-01, BR-02, BR-06, BR-29, BR-63, BR-114, BR-60 | NFR-P04 | AC-03.01.1–5 |
| US-03.02 | GĐ1 §4.2; `05-tham-chieu-ky-thuat.md` §1.5, §2 | Must | BR-03, BR-04, BR-05, BR-07, BR-22, BR-33, BR-64 | — | AC-03.02.1–7 |
| US-03.03 | GĐ1 §4.2, §6; D-08 | Must | BR-05, BR-15, BR-34, BR-66 | NFR-08, NFR-P02, NFR-P08 | AC-03.03.1–5 |
| US-03.04 | GĐ1 §4.2, §10 #1; D-05, D-07, D-08, D-29; T-BA-97, T-BA-123; Q-61 | Must | BR-11, BR-13, BR-14, BR-15, BR-26, BR-31, BR-34, BR-118 | NFR-03, NFR-04, NFR-P01, NFR-P15, NFR-19 | AC-03.04.1–10 |
| US-03.05 | GĐ1 §4.3; `05-tham-chieu-ky-thuat.md` §1; D-05 | Must | BR-11…BR-14, BR-32, BR-33, BR-35, BR-65 | NFR-03 | AC-03.05.1–7 |
| US-03.06 | GĐ1 §6; D-13; Q-11, Q-15, Q-26 | Should | BR-16, BR-17, BR-18, BR-36, BR-67 | — | AC-03.06.1–7 |
| US-03.07 | GĐ1 §10 #3; D-05, D-08, D-19; `05-tham-chieu-ky-thuat.md` §5; Q-30, Q-31 | Must | BR-19, BR-20, BR-21, BR-24, BR-32, BR-36, BR-48, BR-65, BR-66 | — | AC-03.07.1–10 |
| US-03.08 | D-05, D-19; GĐ1 §4.3 | Must | BR-14, BR-21, BR-27, BR-35, BR-36, BR-37, BR-39 | — | AC-03.08.1–9 |
| US-03.09 | D-05, D-20, D-22; D-14 (gộp US-04.02); GĐ1 §4.3, §6; Q-87, Q-136, Q-137 | Must (M) | BR-12, BR-21, BR-26, BR-27, BR-28, BR-34, BR-36, BR-38, BR-39, BR-41, BR-47, BR-53, BR-81, BR-82 | NFR-02, NFR-P03, NFR-P06, NFR-P18 | AC-03.09.1–10, .12 (.11 chuyển → AC-03.12.6) |
| US-03.10 | GĐ1 §4.5; D-05, D-09, D-11, D-19, D-22, D-25 | Must | BR-05, BR-08, BR-23, BR-24, BR-30, BR-32, BR-33, BR-36, BR-37, BR-38, BR-41, BR-46, BR-47, BR-112 | — | AC-03.10.1–8 |
| US-03.11 | GĐ1 §4.1; D-05, D-06, D-13; Q-18, Q-41 | Should | BR-04, BR-07, BR-08, BR-09, BR-30, BR-37, BR-65 | — | AC-03.11.1–5 |
| US-03.12 | GĐ1 §10 #3; D-05, D-13, D-19; `05-tham-chieu-ky-thuat.md` §5; Q-28, Q-123 | Should | BR-22, BR-32, BR-35, BR-68 | NFR-15 | AC-03.12.1–6 |
| US-03.13 | (Hủy — D-25) | — | — | — | (AC-03.13.1–5 không dùng lại) |
| US-03.14 (mới) | GĐ1 §4.5, §6; D-05, D-11, D-12, D-19, D-21, D-22; mockup-tong-hop S10 (T-BA-102); Q-101 | Should (giả định) | BR-21, BR-22, BR-23, BR-24, BR-32, BR-34, BR-38, BR-41, BR-53, BR-103, BR-119 | NFR-P03, NFR-P06, NFR-P11, NFR-P18, NFR-11 | AC-03.14.1–8 |

Sửa 2026-10-19 theo `review/mockup-tong-hop.md` §3: S9 → AC-03.04.6, .7 và AC-03.08.9 (rời chủ động = EXITED, T-BA-97); S3 → ghi chú US-03.03 (chủ nhóm không xem trạng thái thời gian thực); S10 → US-03.14 mới (Should). US-03.04 vẫn L, US-03.08 vẫn M — Must không đổi.

Sửa 2026-10-19 theo `review/lan-4.md`: T-BA-123 (D-29: AC-03.04.7 viết lại — có nút "Rời phiên" + hộp xác nhận; AC-03.04.8–10 mới; dải AC US-03.04 → 1–10); T-BA-125 (AC-03.01.3 và dòng US-03.01: BR-25/BR-69 Hủy → BR-114, BR-60); T-BA-127 (gỡ "cần BR mới" ở AC-03.10.7, ghi chú và dòng US-03.10 — đã có BR-08); T-BA-130 (AC-03.03.1 gắn nhãn phạm vi nút "Tạm dừng"). Ước lượng không đổi.

## Q- liên quan (đã ghi sổ)

Đã cấp số chính thức trong `ba/02-so-quyet-dinh.md`, trạng thái `Chờ`. Q-87 gộp với câu EP-04 (kênh báo `forfeited` khi không ở tiền cảnh).

| Mã | Câu hỏi | Phương án đề xuất | Ảnh hưởng |
| --- | --- | --- | --- |
| Q-83 | Phòng chờ mở trước giờ bắt đầu bao lâu? | 10 phút, cấu hình được | US-03.01, EP-02 |
| Q-84 | Rời app trong COUNTDOWN (chưa ghi) thì khi ACTIVE xử lý thế nào? | Khi ACTIVE mà không ở app → GRACE tính từ `started_at`, có trừ lượt | US-03.02 |
| Q-85 | Có đếm ngược 3 giây / thông báo cục bộ “Quay lại ngay” khi đang GRACE? | Có, thông báo cục bộ, không gửi server | US-03.05 |
| Q-86 | Mất bao nhiêu nhịp heartbeat thì DISCONNECTED? | Không nhận heartbeat trong 2 × `heartbeat_s` (10 giây) hoặc socket đóng | US-03.07, BR-19 |
| Q-87 | Thông báo mất thưởng tập thể có push khi thành viên đang úp máy? | Không push; hiện khi mở app và ở màn kết quả | US-03.09, BR-38 |
| Q-88 | BR-30: phiên không ai vào → thành viên ABSENT hay VOID? | ABSENT (ưu tiên BR-08), không ngắt chuỗi | US-03.11 |
| Q-135 | CN nhiều nhóm tham gia phiên nhóm nào, đổi thế nào? | Đã chốt → D-25 (CN không tham gia phiên) | — |
| Q-136 | Có hiện tên người LOST/ABSENT cho cả nhóm? | Không | US-03.09 |
| Q-137 | Thành viên khác thấy số lần thoát tích lũy của người khác? | Không | US-03.09 |
| Q-139 | CN tham gia phiên mà thoát có bị nêu tên? | Đã chốt → D-25 (không còn áp dụng) | — |

Sửa 2026-10-19 (khớp BR sau lần 4): AC-03.04.9 theo BR-118 (3) — mất kết nối thì báo "Chưa rời phiên — không có kết nối", không xếp hàng gửi sau; AC-03.04.10 theo BR-118 (2) — phòng chờ có nút "Rời phiên" → ABSENT (Q-149), màn đếm ngược 5s không có nút, GRACE/PAUSED → EXITED. Gỡ "cần BR mới". Ước lượng không đổi.
