# EP-05 Thành tích

Nguồn: GĐ1 §4.4, §4.3; D-01, D-03, D-05, D-09, D-10, D-11, D-12, D-13  ·  MoSCoW: Must (US-05.01, 05.03, 05.04, 05.05); Should (US-05.02, 05.06, 05.07, 05.08, 05.09 — D-13)  ·  Phụ trách: T-BA-11

Sửa 2026-10-06 theo `ba/review/lan-1.md` (nguồn cũ đã xóa): T-BA-26 (thuật ngữ D-11), T-BA-28 (US-05.09 viết lại theo D-12: chủ nhóm không thấy chuỗi), T-BA-29 (ngoại lệ BR-68 khi hủy do sự cố), T-BA-41 (lối vào chủ nhóm: màn "Thành viên nhóm", không qua hồ sơ), T-BA-42 (AC-05.05.8 viết lại), D-13 (MoSCoW), D-16 (US-05.06 nhận AC-05.06.5–9 từ US-07.05).
Sửa 2026-10-07 theo D-19 (LOST không gây mất thưởng tập thể), D-21 (mỗi người là thành viên tối đa 1 nhóm), D-22 (nêu tên người thoát), D-23 (WITHDRAWN sau `forfeited_at` vẫn ngắt chuỗi) và `ba/review/lan-2.md` (nguồn cũ đã xóa): T-BA-56 (AC-05.03.7, AC-05.07.6), T-BA-58 (nhãn AC phụ thuộc story Should).
Thuật ngữ (D-11): **hoàn thành** = trạng thái cuối COMPLETED (kể cả phiên `forfeited`) → đủ điều kiện điểm danh (BR-46); **hoàn thành có thưởng** = COMPLETED và phiên không `forfeited` → đủ điều kiện Coins, +1 chuỗi, đếm huy hiệu số phiên.
Quy tắc tham chiếu: `03-quy-tac.md` §Thưởng (BR-46…BR-54), §Phiên (BR-08, BR-21, BR-22, BR-35, BR-37, BR-38). Riêng tư: `04-nfr-rieng-tu.md` §3, NFR-P03, NFR-P06, NFR-P18, NFR-21.
Vai trò theo D-10: **Người dùng** (mọi tài khoản), **Chủ nhóm**, **Thành viên**, **Quản trị**. Không có vai trò "Trưởng phòng".
Ngày tính theo Asia/Ho_Chi_Minh, mốc 00:00 (NFR-21; giả định ở §Thưởng). Câu hỏi chưa chốt ghi **(giả định, Q-xx)**; Q- mới của epic đã được cấp số chính thức trong `ba/02-so-quyet-dinh.md` (xem mục cuối).

---

## US-05.01 Ghi điểm danh ngày

**Là một** Thành viên, **tôi muốn** hệ thống tự ghi nhận ngày tôi đã điểm danh khi tôi hoàn thành phiên **để** công sức có mặt và tập trung của tôi được ghi nhận.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.4; D-05 · Liên quan: BR-46, BR-23, BR-35, BR-22, BR-32

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-05.01.1 | Bình thường | Thành viên chưa điểm danh hôm nay | Phiên đến `ends_at`, trạng thái cuối của người đó là COMPLETED | Ngày hôm nay (theo ngày của `started_at`) được ghi "đã điểm danh" (BR-46) |
| AC-05.01.2 | Bình thường | Phiên có `forfeited = true`, người đó COMPLETED | Phiên đến `ends_at` | Vẫn ghi điểm danh: người đó **hoàn thành** (dù không **hoàn thành có thưởng**) (BR-46, D-11) |
| AC-05.01.3 | Lỗi | Trạng thái cuối là EXITED, LOST, ABSENT, WITHDRAWN hoặc VOID | Phiên kết thúc / bị hủy | Không ghi điểm danh từ phiên này (bảng quyết định §Thưởng §2) |
| AC-05.01.4 | Lỗi | Phiên CANCELLED do sự cố (BR-22) | Server hủy phiên | Không ghi điểm danh, không ghi bản ghi nào cho ngày đó từ phiên này (người VOID; *phần "người đã EXITED trước sự cố — BR-68 giữ EXITED, ngắt chuỗi, không tạo điểm danh" chỉ kiểm khi US-03.12 trong phạm vi, T-BA-58*) |
| AC-05.01.5 | Biên | Người dùng đã điểm danh hôm nay | Hoàn thành thêm phiên thứ 2 cùng ngày của nhóm mình (D-21) | Vẫn chỉ 1 điểm danh cho ngày đó (BR-46) |
| AC-05.01.6 | Biên | Phiên 50 phút có `started_at` = 23:40 ngày N, `ends_at` = 00:30 ngày N+1 | Người đó COMPLETED | Điểm danh ghi cho ngày N (ngày của `started_at`) |
| AC-05.01.7 | Lỗi | Client gửi lại cùng `event_id` hoàn thành | Server nhận trùng | Không tạo thêm điểm danh (BR-31, idempotent) |

**Ghi chú / giả định:** Điểm danh của chính người dùng là cấp người dùng. Theo D-21, với thành viên con số này trùng với điểm danh trong nhóm; chỉ khác với người đổi nhóm trong tháng (BR-46). Chủ nhóm không tham gia phiên nhóm mình làm chủ (D-25). Chủ nhóm chỉ thấy điểm danh tính trên phiên của nhóm mình (BR-53 (c), D-12; US-05.09).

---

## US-05.02 Xem điểm danh của tôi

**Là một** Người dùng, **tôi muốn** xem lịch điểm danh theo tháng **để** biết những ngày tôi đã có mặt và tập trung.

- Ưu tiên: **Should** (D-13) · Ước lượng: M · Nguồn: GĐ1 §4.4; D-13; 04 §3 · Liên quan: BR-46, BR-53, A-21, NFR-P03, NFR-P11, NFR-21

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-05.02.1 | Bình thường | Người dùng có điểm danh trong tháng hiện tại | Mở màn "Thành tích" → "Điểm danh" | Thấy lịch tháng, ngày đã điểm danh được đánh dấu bằng biểu tượng **và** chữ (không chỉ màu, NFR-20); tổng số ngày điểm danh tháng |
| AC-05.02.2 | Bình thường | — | Chạm vào một ngày đã điểm danh | Thấy danh sách phiên COMPLETED của ngày đó (nhóm, giờ, thời lượng, có/không mất thưởng tập thể) — chỉ của chính mình |
| AC-05.02.3 | Lỗi | Mất mạng | Mở màn điểm danh | Hiện dữ liệu đã lưu lần cuối kèm nhãn "Chưa cập nhật — thời điểm …" hoặc thông báo lỗi và nút thử lại; không hiện lịch trống như thể chưa điểm danh **(giả định)** |
| AC-05.02.4 | Lỗi | Người dùng A (kể cả khi A là chủ nhóm của B) | Gọi API lịch điểm danh cấp người dùng của B | Trả 403 (NFR-11). Chủ nhóm chỉ có API điểm danh theo nhóm (US-05.09, BR-53 (c)) |
| AC-05.02.5 | Biên | Thiết bị đặt múi giờ khác UTC+7 | Xem ngày gần nửa đêm | Ngày hiển thị theo Asia/Ho_Chi_Minh, không theo múi giờ máy (NFR-21) |
| AC-05.02.6 | Biên | Người dùng chưa có phiên nào | Mở màn điểm danh | Hiện trạng thái rỗng có hướng dẫn, không lỗi |

**Ghi chú / giả định:** Hiển thị được bao xa về quá khứ: theo thời hạn lưu "đến khi xóa tài khoản" (04 §4). Nhãn "Điểm danh của tôi" ở đây khác "Số ngày điểm danh trong nhóm" ở báo cáo tháng chỉ khi người dùng đổi nhóm trong tháng (D-21, BR-46; chủ nhóm không tham gia phiên — D-25).

---

## US-05.03 Cập nhật chuỗi ngày sau mỗi phiên

**Là một** Thành viên, **tôi muốn** chuỗi ngày của tôi được cộng/ngắt đúng quy tắc sau mỗi phiên **để** chuỗi phản ánh công bằng sự kiên trì của tôi và trách nhiệm đồng đội (D-05).

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.3, §4.4; D-05 · Liên quan: BR-47, BR-48, BR-49, BR-50, BR-51, BR-37, BR-22, BR-54

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-05.03.1 | Bình thường | `current_streak` = 4, hôm nay chưa +1 | Người đó COMPLETED một phiên không `forfeited` | `current_streak` = 5 (BR-49); nếu 5 > `longest_streak` thì `longest_streak` = 5 (BR-51) |
| AC-05.03.2 | Bình thường | Đã +1 hôm nay | COMPLETED thêm phiên không `forfeited` cùng ngày | Chuỗi không đổi (tối đa +1/ngày, BR-49) |
| AC-05.03.3 | Lỗi (D-05) | Người đó COMPLETED nhưng phiên `forfeited = true` | Phiên đến `ends_at` | `current_streak` = 0 tại `ends_at` (BR-47b); `longest_streak` giữ nguyên |
| AC-05.03.4 | Lỗi | Người đó EXITED | Server xác nhận EXITED | `current_streak` = 0 ngay (BR-47a) |
| AC-05.03.5 | Lỗi | Người đó LOST, phiên `forfeited = true` (do người khác EXITED) | Phiên đến `ends_at` | `current_streak` = 0 (BR-37, BR-47b, BR-48 ngoại lệ, **đề xuất, Q-27**) |
| AC-05.03.6 | Bình thường | Người đó LOST, không ai EXITED nên phiên không `forfeited` (LOST không kích hoạt mất thưởng, BR-36, D-19) | Phiên đến `ends_at` | Chuỗi của người LOST giữ nguyên, không +1 (BR-48, **đề xuất, Q-27**); người khác COMPLETED vẫn +1 chuỗi (D-19) |
| AC-05.03.7 | Bình thường | Người đó ABSENT hoặc VOID; hoặc WITHDRAWN **trước** `forfeited_at` (hoặc ở phiên không `forfeited`); hoặc WITHDRAWN do khóa tài khoản (BR-108); hoặc ngày không có lịch của nhóm người đó | Hết ngày / phiên đến `ends_at` | Chuỗi giữ nguyên (BR-37, BR-48, **đề xuất, Q-17**) |
| AC-05.03.14 | Lỗi (D-23) | `current_streak` = 5; phiên `forfeited` do người khác EXITED; người đó rút đồng ý hoặc rời nhóm **sau** `forfeited_at` → WITHDRAWN | Phiên đến `ends_at` | `current_streak` = 0 tại `ends_at`; không Coins (BR-26, BR-37, BR-47b, BR-48, D-23) |
| AC-05.03.15 | Biên (D-23) | Phiên `forfeited_at` = F | Người đó WITHDRAWN lúc `F − 1 ms` / lúc `F` | `F − 1 ms`: trước mốc, chuỗi giữ nguyên; `F`: không trước mốc, chuỗi = 0 tại `ends_at` (BR-37, BR-33 theo giờ server) **(giả định — so sánh "trước" là nghiêm ngặt)** → cần BR mới làm rõ nếu không đúng |
| AC-05.03.8 | Biên | Đã +1 lúc 9:30 (`current_streak` = 6) | 14:50 bị ngắt (EXITED hoặc phiên `forfeited`) | `current_streak` = 0 (BR-50) |
| AC-05.03.9 | Biên | Bị ngắt lúc 9:30 | 14:50 COMPLETED phiên không `forfeited` cùng ngày | `current_streak` = 1 (BR-50, **đề xuất, Q-40**) |
| AC-05.03.10 | Biên | `forfeited = true`, phiên sau đó CANCELLED do sự cố trước `ends_at` | Server hủy phiên | Người VOID không bị ngắt chuỗi; cờ `forfeited` bị gỡ (BR-22, BR-35, §Phiên §3 #28). *Ngoại lệ BR-68 (chỉ kiểm khi US-03.12 trong phạm vi, T-BA-58):* người đã EXITED trước sự cố giữ ngắt chuỗi (`current_streak` vẫn = 0) |
| AC-05.03.11 | Lỗi | Chuỗi đã bị ngắt | Thành viên viết giải trình cho sự kiện thoát | Chuỗi **không** được khôi phục (BR-54, **đề xuất, Q-16, Q-37**) |
| AC-05.03.12 | Biên | Hai phiên cùng ngày kết thúc gần như cùng lúc (một `forfeited`, một không) | Server chốt | Xử lý theo thứ tự thời điểm server; kết quả cuối đúng BR-50 |
| AC-05.03.13 | Bình thường | Chuỗi bị ngắt | Bất kỳ lúc nào | **Không** thay đổi Coins (chuỗi không cộng/trừ Coins, BR-51) |

**Ghi chú / giả định:**
- Chuỗi là cấp người dùng (theo D-21 thực tế tính trên phiên của nhóm người đó đang tham gia); chỉ chính người dùng thấy (chủ nhóm không thấy, BR-53 (b), D-12).
- Mất mạng (LOST) không làm cả phiên mất thưởng (D-19); chỉ EXITED mới kích hoạt ngắt chuỗi tập thể.
- +1 chuỗi chỉ khi **hoàn thành có thưởng** (D-11).
- Khi CN miễn trừ (NFR-P14, Should, Q-37) thì chuỗi có được khôi phục cho cả phiên không — quy tắc khôi phục chuỗi → **BR-87, BR-88** (tính lại `current_streak`/`longest_streak` bằng phát lại nhật ký BR-92).
- Ngày có lịch, người đó chỉ có phiên LOST (không `forfeited`): giữ nguyên — đã có ở BR-48.

---

## US-05.04 Xem chuỗi hiện tại và chuỗi dài nhất

**Là một** Người dùng, **tôi muốn** xem chuỗi hiện tại và chuỗi dài nhất của mình **để** có động lực giữ chuỗi.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.4 · Liên quan: BR-49, BR-51, BR-52, A-21, NFR-P03

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-05.04.1 | Bình thường | `current_streak` = 5, `longest_streak` = 12 | Mở màn "Thành tích" | Thấy "Chuỗi hiện tại: 5 ngày" và "Chuỗi dài nhất: 12 ngày", kèm mốc huy hiệu chuỗi kế tiếp (7 ngày, còn 2) (BR-52) |
| AC-05.04.2 | Bình thường | Hôm nay có lịch nhưng chưa có phiên đạt | Mở màn | Hiện trạng thái "Hôm nay chưa cộng chuỗi" (không phải "đã mất") |
| AC-05.04.3 | Lỗi | Lỗi tải dữ liệu | Mở màn | Hiện thông báo lỗi + thử lại; không hiện 0 sai |
| AC-05.04.4 | Biên | `current_streak` = 0 sau khi bị ngắt | Mở màn | Hiện 0, `longest_streak` không giảm (BR-51) |
| AC-05.04.5 | Biên | Đã đạt mốc cao nhất (100 ngày) | Mở màn | Không hiện "mốc kế tiếp", hiện "đã đạt mọi mốc chuỗi" |

**Ghi chú / giả định:** Không có bảng xếp hạng chuỗi giữa thành viên (D-03, NFR-P06). Màn này chỉ dành cho chính người dùng; chủ nhóm không có màn/API tương đương (BR-53 (b), D-12).

---

## US-05.05 Nhận huy hiệu theo mốc

**Là một** Người dùng, **tôi muốn** tự động nhận huy hiệu khi đạt mốc chuỗi, số phiên hoặc tổng giờ tập trung **để** được ghi nhận tích cực.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.4; D-01 · Liên quan: BR-52, BR-51, BR-23, BR-35, BR-31

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-05.05.1 | Bình thường | `current_streak` = 6, chưa có huy hiệu "Chuỗi 7 ngày" | Chuỗi +1 thành 7 | Cấp huy hiệu "Chuỗi 7 ngày" một lần, ghi thời điểm cấp; hiện thông báo trong app "Bạn nhận huy hiệu …" (BR-52) |
| AC-05.05.2 | Bình thường | Đã có 9 phiên **hoàn thành có thưởng** | Hoàn thành có thưởng phiên thứ 10 | Cấp huy hiệu "10 phiên" (BR-52) |
| AC-05.05.3 | Lỗi (D-05) | Đã có 9 phiên hoàn thành có thưởng | Hoàn thành (không có thưởng) một phiên `forfeited` | Không cấp huy hiệu "10 phiên" (BR-52 chỉ đếm hoàn thành có thưởng, D-11) |
| AC-05.05.4 | Lỗi | Đã có huy hiệu "Chuỗi 7 ngày" | Chuỗi bị ngắt rồi lại đạt 7 | Không cấp lại; huy hiệu cũ không bị thu hồi (BR-52) |
| AC-05.05.5 | Lỗi | Sự kiện hoàn thành gửi trùng | Server xử lý | Không cấp trùng huy hiệu (BR-31; khóa duy nhất người dùng–huy hiệu) |
| AC-05.05.6 | Biên | Tổng phút tập trung = 599 | Phiên mới cộng thêm ≥1 phút | Tổng ≥ 600 phút → cấp "10 giờ tập trung" (BR-52) |
| AC-05.05.7 | Biên | Một phiên làm vượt cùng lúc 2 mốc (vd. chuỗi 7 và 10 phiên) | Phiên kết thúc | Cấp đủ cả 2 huy hiệu |
| AC-05.05.8 | Biên | `current_streak` = 6, chưa có huy hiệu "Chuỗi 7 ngày" | Người đó **hoàn thành** (không có thưởng) một phiên `forfeited` hôm nay | `current_streak` = 0 tại `ends_at` (BR-47b); không cấp "Chuỗi 7 ngày"; không +1 vào số phiên của huy hiệu "10 phiên" (BR-52) |

**Ghi chú / giả định:**
- Huy hiệu chỉ để ghi nhận, không tiêu được, không cộng Coins, không bán (Shop là Could, Q-38).
- "Tổng giờ tập trung" có tính phút của phiên `forfeited` và phần trước khi EXITED/LOST không? → **BR-89**, Q-127 ( tính theo phút tập trung của phiên COMPLETED, kể cả `forfeited`, giống "phút tập trung" BR-23; không tính phần trước EXITED/LOST).
- Quản trị đổi `badge_milestones`: có cấp hồi tố cho người đã vượt mốc mới không → **BR-90** (cấp hồi tố, Q-125).
- Thông báo huy hiệu: chỉ trong app hay cả push → (giả định: chỉ trong app), Q-95.

---

## US-05.06 Xem bộ sưu tập huy hiệu và chọn hiển thị trên hồ sơ

**Là một** Người dùng, **tôi muốn** xem các huy hiệu đã có/chưa có và chọn huy hiệu nào hiện trên hồ sơ **để** tự quyết định điều người cùng nhóm thấy.

- Ưu tiên: **Should** (D-13; D-16 gộp US-07.05) · Ước lượng: S · Nguồn: GĐ1 §4.4, §4.7, §6; D-12; D-13; D-16; 04 §3 · Liên quan: BR-47, BR-51, BR-52, BR-99, A-03, A-21, NFR-P06

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-05.06.1 | Bình thường | Người dùng có 3 huy hiệu | Mở "Huy hiệu" | Thấy huy hiệu đã có (ngày nhận) và huy hiệu chưa có (điều kiện, tiến độ vd. "4/7 ngày") |
| AC-05.06.2 | Bình thường | — | Bật "hiện trên hồ sơ" cho 1 huy hiệu | Thành viên cùng nhóm xem hồ sơ thấy huy hiệu đó; không thấy huy hiệu chưa bật (04 §3, **giả định**) |
| AC-05.06.3 | Lỗi | Người ngoài nhóm của người dùng (D-21) | Xem hồ sơ | Bị từ chối (A-03, 403) |
| AC-05.06.4 | Biên | Mặc định khi mới nhận huy hiệu | — | Huy hiệu **không** tự hiện trên hồ sơ cho tới khi người dùng bật **(giả định, Q-94)** |
| AC-05.06.5 | Bình thường | Người dùng có 4 huy hiệu, mặc định không hiện huy hiệu/chuỗi công khai (BR-99, đề xuất Q-94) | Chọn hiện 2 huy hiệu và bật "hiện chuỗi hiện tại" | Người cùng nhóm (kể cả chủ nhóm) thấy đúng 2 huy hiệu và chuỗi hiện tại; không thấy 2 huy hiệu còn lại |
| AC-05.06.6 | Lỗi | — | Gọi API chọn hiển thị một huy hiệu chưa đạt | Từ chối (400); danh sách hiển thị không đổi |
| AC-05.06.7 | Biên | `showcase_max_badges = 3` (BR-99) | Chọn huy hiệu thứ 3 / thứ 4 | Thứ 3: chấp nhận; thứ 4: từ chối, báo "Tối đa 3" |
| AC-05.06.8 | Bình thường | Chuỗi hiện tại đang bật công khai, sau đó bị ngắt (BR-47) | Người cùng nhóm mở hồ sơ | Thấy chuỗi = 0; hồ sơ không hiện lý do ngắt hay số lần thoát (NFR-P06, NFR-P18; **giả định, Q-137**) — dù tên người thoát từng được báo cho cả nhóm khi sự kiện xảy ra (D-22) |
| AC-05.06.9 | Bình thường | Người dùng tắt "hiện chuỗi hiện tại" | Chủ nhóm gọi API hồ sơ của người đó | Phản hồi không có trường chuỗi (D-12) |
| AC-05.06.10 | Bình thường | Tài khoản mới tạo | Mở màn chọn hiển thị trên hồ sơ | Công tắc "hiện chuỗi hiện tại" ở trạng thái **tắt**; bấm bật → hiện câu "Mọi người cùng nhóm, kể cả chủ nhóm, sẽ thấy chuỗi này" kèm nút xác nhận; chỉ sau khi xác nhận trạng thái mới thành bật (NFR-P17, D-12) |
| AC-05.06.11 | Lỗi | Câu cảnh báo NFR-P17 chưa được hiển thị cho người dùng trong lần bật này (vd. gọi thẳng API bật, hoặc đóng hộp cảnh báo không xác nhận) | Yêu cầu bật "hiện chuỗi hiện tại" | Từ chối (400), trạng thái vẫn tắt; người cùng nhóm và chủ nhóm không thấy trường chuỗi (NFR-P17) **(giả định — API bật cần kèm mã xác nhận đã xem cảnh báo)** |

**Ghi chú / giả định:** Không hiện số lần bị ngắt chuỗi hay số lần thoát lên hồ sơ (NFR-P06). Giới hạn số huy hiệu trưng bày: `showcase_max_badges = 3` (BR-99). Theo D-16, US-07.05 đã gộp vào story này: AC-05.06.5–9 chuyển từ AC-07.05.1–5 (bảng ánh xạ ở EP-07). Không có Coins hay xếp hạng trên hồ sơ (D-03, BR-53). Chủ nhóm xem hồ sơ chỉ thấy phần công khai như mọi người cùng nhóm (BR-99), không phải dữ liệu quản lý (BR-53).

---

## US-05.07 Thông báo ngắt chuỗi

**Là một** Thành viên, **tôi muốn** được báo khi chuỗi của tôi bị ngắt và lý do **để** không thấy mất chuỗi không rõ nguyên nhân, nhất là khi do người khác thoát (D-05).

- Ưu tiên: **Should** (D-13) · Ước lượng: M · Nguồn: D-05; D-13; GĐ1 §4.3, §9 · Liên quan: BR-47, BR-38, BR-37, BR-114, BR-68, BR-82, BR-91, NFR-P18, NFR-02

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-05.07.1 | Bình thường (D-05) | Thành viên C COMPLETED trong phiên `forfeited`, `current_streak` = 5 | Phiên đến `ends_at` | Màn kết quả phiên hiện "Chuỗi 5 ngày đã bị ngắt vì phiên mất thưởng tập thể do ‹Tên người khởi phát› rời phiên" (BR-38, D-22). Không hiện lý do, giải trình, số lần thoát của người khác (NFR-P18) |
| AC-05.07.2 | Bình thường | Chính người đó EXITED | Server xác nhận EXITED | Người đó thấy "Chuỗi đã bị ngắt vì bạn rời app quá 3 giây" (BR-47a) kèm lối vào giải trình (EP-04) |
| AC-05.07.3 | Lỗi (riêng tư) | Thành viên C cùng phiên | Gọi API kết quả phiên / nhận push | Payload có tên người khởi phát (D-22) nhưng **không** chứa giải trình, khiếu nại, lý do tạm dừng, số lần thoát tích lũy của người đó (NFR-P18, **giả định, Q-137**) |
| AC-05.07.4 | (Hủy — D-25) | — | — | Chủ nhóm không tham gia phiên nên không thể là người thoát. Mã không dùng lại. |
| AC-05.07.5 | Biên | `current_streak` = 0 trước phiên `forfeited` | Phiên đến `ends_at` | Không gửi thông báo "ngắt chuỗi" (không có gì để ngắt); kết quả phiên chỉ ghi "mất thưởng tập thể" |
| AC-05.07.6 | Lỗi | Trong phiên `forfeited`: người đó ABSENT, VOID, WITHDRAWN **trước** `forfeited_at`, hoặc WITHDRAWN do khóa tài khoản | Phiên kết thúc | Không nhận thông báo ngắt chuỗi (BR-37, BR-48) |
| AC-05.07.9 | Bình thường (D-23) | `current_streak` = 5; người đó WITHDRAWN **sau** `forfeited_at` | Phiên đến `ends_at` | Chuỗi = 0; người đó được báo "Chuỗi 5 ngày đã bị ngắt vì phiên mất thưởng tập thể trước khi bạn rút khỏi phiên" — qua hộp thông báo (BR-81); nếu đã rời nhóm vẫn nhận vì là dữ liệu của chính mình (BR-37, D-23) **(giả định)** |
| AC-05.07.10 | Lỗi (D-19) | Người khác trong phiên LOST, không ai EXITED | Phiên đến `ends_at` | Không ai nhận thông báo ngắt chuỗi hay "mất thưởng tập thể"; không nêu tên người LOST (BR-36, NFR-P18, **giả định, Q-136**) |
| AC-05.07.7 | Biên | Phiên CANCELLED do sự cố sau khi đã `forfeited` | Hủy phiên | Người VOID: không nhận thông báo ngắt chuỗi; nếu đã hiện cảnh báo "mất thưởng" trong phiên thì hiện "Phiên bị hủy do sự cố — chuỗi không bị ảnh hưởng" (BR-22). **Ngoại lệ BR-68:** người đã EXITED trước sự cố nhận thông báo riêng "…Lần rời app của bạn trước sự cố vẫn được ghi; chuỗi đã ngắt. Bạn có thể khiếu nại." |
| AC-05.07.8 | Biên | Ngắt chuỗi xảy ra | — | Thông báo xuất hiện trong app ≤ 2 giây (p95) nếu đang mở app (NFR-02) |

**Ghi chú / giả định:**
- Kênh: trong app ở màn kết quả phiên + lịch sử (US-05.08); có push riêng cho "ngắt chuỗi" hay gộp vào push "phiên mất thưởng" (SNS, 04 ánh xạ AWS) → **BR-91** (gộp một push duy nhất tại `ends_at`, Q-93).
- R-P08 (nhóm nhỏ đoán ra người thoát) không còn là rủi ro riêng tư vì D-22 cho nêu tên.
- AC-05.07.7 phần ngoại lệ BR-68: chỉ kiểm khi US-03.12 trong phạm vi (T-BA-58).

---

## US-05.08 Lịch sử thành tích

**Là một** Người dùng, **tôi muốn** xem dòng thời gian điểm danh, cộng/ngắt chuỗi và huy hiệu **để** hiểu chuỗi của tôi thay đổi vì sao.

- Ưu tiên: **Should** (D-13) · Ước lượng: M · Nguồn: GĐ1 §4.4; D-13; 04 §3, §5 · Liên quan: BR-46, BR-47, BR-49, BR-50, BR-52, BR-53, BR-92, NFR-P03, NFR-P11, NFR-P06

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-05.08.1 | Bình thường | Người dùng có hoạt động | Mở "Lịch sử thành tích" | Thấy các mục mới nhất trước: ngày, loại (điểm danh / chuỗi +1 / ngắt chuỗi / bắt đầu lại / huy hiệu), giá trị chuỗi sau thay đổi, phiên liên quan (nhóm, giờ) |
| AC-05.08.2 | Bình thường | Mục "ngắt chuỗi" do phiên `forfeited` | Xem chi tiết | Lý do "Phiên mất thưởng tập thể do ‹Tên người khởi phát› rời phiên" (BR-38, D-22); không có giải trình/số lần thoát của người đó (NFR-P18) |
| AC-05.08.3 | Lỗi | Lỗi tải trang kế tiếp | Cuộn xuống | Hiện lỗi + thử lại; các mục đã tải giữ nguyên |
| AC-05.08.4 | Lỗi | Bất kỳ người dùng khác, **kể cả chủ nhóm** của người này | Gọi API lịch sử thành tích của người này | 403 (NFR-11; BR-53 (b), D-12) |
| AC-05.08.5 | Biên | Ngắt rồi bắt đầu lại cùng ngày (BR-50) | Xem lịch sử ngày đó | Thấy đủ 2 mục theo thứ tự thời điểm server |
| AC-05.08.6 | Biên | Phiên CANCELLED do sự cố | Xem lịch sử | Người VOID: không có mục ngắt chuỗi từ phiên đó. Người đã EXITED trước sự cố: có mục "ngắt chuỗi — bạn rời app" (BR-68) |

**Ghi chú / giả định:** Lịch sử là bản ghi chỉ-thêm (giống tinh thần sổ cái BR-44) để giải thích được mọi giá trị chuỗi; lưu đến khi xóa tài khoản (04 §4). Có trong tệp xuất dữ liệu cá nhân (NFR-P12, Should). Định dạng bản ghi lịch sử chuỗi → **BR-92** (nhật ký thay đổi chuỗi bất biến).

---

## US-05.09 Chủ nhóm xem điểm danh và kết quả phiên của thành viên trong nhóm mình

**Là một** Chủ nhóm, **tôi muốn** xem điểm danh và kết quả phiên của từng thành viên, chỉ tính trên các phiên của nhóm mình, **để** ghi nhận sự có mặt và tập trung của họ mà không biết gì về hoạt động của họ ở nhóm khác.

- Ưu tiên: **Should** (D-13) · Ước lượng: S · Nguồn: GĐ1 §4.4, §6; D-10; D-12; D-13; 01 A-21; 04 §3 · Liên quan: BR-46, BR-53, BR-57, BR-59, BR-73, BR-99, NFR-P03, NFR-P06, NFR-P07, NFR-11

Lối vào duy nhất: màn **"Thành viên nhóm"** của chủ nhóm (04 §3 ràng buộc "Lối vào duy nhất"; review #18). Mở hồ sơ thành viên chỉ hiện phần công khai (BR-99), không có dữ liệu thành tích quản lý.

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-05.09.1 | Bình thường | X là thành viên nhóm A; trong tháng X hoàn thành 6 phiên nhóm A ở 5 ngày khác nhau (1 phiên `forfeited`) | Chủ nhóm A mở "Thành viên nhóm" → X | Thấy: "Điểm danh trong nhóm này: 5 ngày", số phiên và số phút tập trung trong nhóm A, danh sách kết quả từng phiên nhóm A (hoàn thành / hoàn thành có thưởng / EXITED / LOST / ABSENT / vào muộn) (BR-53 (c), D-11) |
| AC-05.09.2 | Lỗi (riêng tư) | Như AC-05.09.1 | Chủ nhóm A gọi API "Thành viên nhóm" của X | Phản hồi **không** chứa `current_streak`, `longest_streak`, lịch sử/lý do ngắt chuỗi, Coins, huy hiệu theo chuỗi hay điểm danh cấp người dùng (kiểm tra bằng schema phản hồi, BR-53 (a)(b), D-12) |
| AC-05.09.3 | Lỗi (riêng tư, D-12, D-21) | X từng là thành viên nhóm A, đã rời A và vào nhóm B; Y là chủ nhóm A, không phải chủ nhóm B | X EXITED trong một phiên nhóm B | Mọi màn/API/báo cáo của Y về X trả dữ liệu **giống hệt** trước phiên đó (không suy ra được việc ở nhóm B) (04 §3 "Không suy luận chéo nhóm", BR-59) |
| AC-05.09.4 | Biên | Trong tháng, X hoàn thành phiên nhóm A ngày 1–10, rời A ngày 10, vào nhóm B và hoàn thành phiên nhóm B ngày 11–20 (D-21) | Chủ nhóm A xem | Chỉ đếm điểm danh/phiên/phút nhóm A ngày 1–10; phiên nhóm B không xuất hiện |
| AC-05.09.5 | Lỗi | Y là chủ nhóm A, không sở hữu nhóm B (D-21: Y không thể là thành viên nhóm khác cùng lúc) | Y gọi API "Thành viên nhóm" của nhóm B | 403 (NFR-11) |
| AC-05.09.6 | Bình thường | — | Chủ nhóm A mở dữ liệu của X | Ghi nhật ký truy cập (BR-73); X thấy "Chủ nhóm đã xem lúc …" (NFR-P07, **đề xuất Q-21**; phần X thấy chỉ kiểm khi US-01.11 trong phạm vi) |
| AC-05.09.7 | Lỗi | X đã rời nhóm A | Chủ nhóm A xem | Chỉ thấy số liệu nhóm A đến ngày rời (BR-59), không thấy dữ liệu mới |
| AC-05.09.8 | Biên | X tự bật hiện chuỗi/huy hiệu trên hồ sơ (BR-99) | Chủ nhóm A mở hồ sơ X | Thấy chuỗi/huy hiệu đã bật **như mọi thành viên khác** trên hồ sơ công khai; màn "Thành viên nhóm" và báo cáo vẫn không có trường chuỗi (BR-53 (b)) |
| AC-05.09.9 | Bình thường | — | X mở "Dữ liệu của tôi" | Thấy đúng các trường chủ nhóm A thấy về mình, ghi rõ "Chủ nhóm không thấy chuỗi và Coins của bạn" (NFR-P03) |
| AC-05.09.10 | Biên | Nhóm A có TV "Vũ", "An", "Bình" với số ngày điểm danh khác nhau | Chủ nhóm A mở danh sách "Thành viên nhóm" | Danh sách sắp theo tên hiển thị A→Z, không theo điểm danh/số phiên/phút; không có thao tác sắp theo chỉ số (BR-115, D-03, NFR-P06) |
| AC-05.09.11 | Lỗi (phủ định) | Phiên nhóm A đang ACTIVE, X đang GRACE | Chủ nhóm A mở "Thành viên nhóm" → X | Không có trạng thái phiên thời gian thực của X; không nút Nhắc/Rung/Tạm dừng (BR-28, NFR-P02, BR-116); kết quả phiên chỉ có sau khi kết thúc, chi tiết phiên xem ở US-08.10 |

**Ghi chú / giả định:** Không xếp hạng hay so sánh thành viên (D-03, NFR-P06). Chạm một phiên trong danh sách kết quả mở màn "Chi tiết phiên" (US-08.10, Must). Mâu thuẫn "lối vào duy nhất" (04 §3) với ưu tiên Should: xem Q-146 (mockup-tong-hop S2). Q-96 đã chốt bằng D-12. Danh sách trường ở màn "Thành viên nhóm" phải có trong mục 2 màn đồng ý (04 §2, NFR-P19). Màn "Thành viên nhóm" dùng chung với EP-04/EP-08; nếu EP-02/EP-08 đã có story cho màn này thì cần đối chiếu để tránh trùng (việc của điều phối viên).

---

## Truy vết

Không sửa `ba/03-truy-vet.md` theo chỉ đạo; các dòng dưới để điều phối viên chép vào.

| Story | Nguồn (GĐ1 / D-) | BR | NFR / quyền | Q- liên quan | MoSCoW |
| --- | --- | --- | --- | --- | --- |
| US-05.01 | GĐ1 §4.4; D-05; D-11; D-21 | BR-46, BR-23, BR-22, BR-31, BR-35, BR-68 | NFR-21 | Q-17 (Q-39 → D-11) | Must |
| US-05.02 | GĐ1 §4.4; D-12; D-13; D-21 | BR-46, BR-53 | A-21, NFR-P03, NFR-P11, NFR-11, NFR-20, NFR-21 | Q-43 | Should |
| US-05.03 | GĐ1 §4.3, §4.4; D-05; D-11; D-12; D-19; D-21; D-23 | BR-26, BR-33, BR-36, BR-37, BR-47, BR-48, BR-49, BR-50, BR-51, BR-22, BR-54, BR-68, BR-87, BR-88, BR-108 | NFR-21 | Q-16, Q-17, Q-27, Q-37, Q-40 (Q-51, Q-131 → D-19, D-23) | Must |
| US-05.04 | GĐ1 §4.4; D-03; D-12 | BR-49, BR-51, BR-52, BR-53 | A-21, NFR-P03, NFR-P06 | Q-17 | Must |
| US-05.05 | GĐ1 §4.4; D-01, D-05; D-11 | BR-52, BR-51, BR-47, BR-23, BR-31, BR-89, BR-90 | — | Q-38, Q-95 | Must |
| US-05.06 | GĐ1 §4.4, §4.7, §6; D-03; D-12; D-13; D-16 (gộp US-07.05); D-22; T-BA-68 (AC-05.06.10, .11) | BR-47, BR-51, BR-52, BR-99 | A-03, A-21, NFR-P06, NFR-P18, NFR-P17 | Q-94, Q-137 | Should |
| US-05.07 | GĐ1 §4.3, §9; D-05; D-13; D-19; D-22; D-23; D-25 (AC-05.07.4 Hủy) | BR-36, BR-37, BR-38, BR-47, BR-48, BR-22, BR-68, BR-81, BR-82, BR-91 | NFR-P18, NFR-02, A-16 | Q-93, Q-136, Q-137 (Q-139 → D-25) | Should |
| US-05.08 | GĐ1 §4.4; D-12; D-13; D-22 | BR-38, BR-46, BR-47, BR-49, BR-50, BR-52, BR-53, BR-68, BR-92 | NFR-P03, NFR-P11, NFR-P12, NFR-P18, NFR-11 | — | Should |
| US-05.09 | GĐ1 §4.4, §6; D-10; D-12; D-13; D-21; 01 A-21 | BR-28, BR-46, BR-53, BR-57, BR-59, BR-73, BR-99; BR-115; BR-116 | NFR-P02, NFR-P03, NFR-P19, NFR-P06, NFR-P07, NFR-11; 04 §3 "Không suy luận chéo nhóm" | Q-21, Q-23, Q-150, Q-146 (Q-96 → D-12) | Should |

Sửa 2026-10-06: AC-05.01.2, .4; AC-05.02.4; AC-05.03.10; AC-05.05.2, .3, .8; AC-05.07.7; AC-05.08.4, .6; US-05.09 viết lại (AC-05.09.1–.9).
Sửa 2026-10-07: AC-05.01.4 (nhãn T-BA-58), .5; AC-05.03.5, .6, .7 (T-BA-56), .10 (nhãn T-BA-58), AC-05.03.14, .15 (mới, D-23); AC-05.06.8; AC-05.07.1, .3, .4, .6 (T-BA-56), AC-05.07.9, .10 (mới); AC-05.08.2; AC-05.09.3–.6.
Sửa 2026-10-19 theo `review/mockup-tong-hop.md` S2–S4: AC-05.09.10 (thứ tự theo tên), AC-05.09.11 (phủ định thời gian thực/nút can thiệp) mới; ghi chú nối US-08.10, Q-146. Ước lượng giữ S.
Sửa 2026-10-19: D-25 (AC-05.07.4 Hủy; ghi chú điểm danh không còn ca "chủ nhóm nhiều nhóm"); T-BA-68 (AC-05.06.10, .11 kiểm câu cảnh báo NFR-P17, mặc định tắt).

**Ước lượng Must EP-05:** không đổi (US-05.03 giữ M — thêm 2 AC D-23 chỉ là điều kiện so `forfeited_at` trong luồng chốt chuỗi đã có). Story Should US-05.07 thêm 2 AC, giữ M.

Sửa 2026-10-19 theo `review/lan-4.md`: T-BA-125 (US-05.07 Liên quan: BR-25 Hủy → BR-114); T-BA-131 (nhãn "nguồn cũ đã xóa").

**BR đã cấp (`03-quy-tac.md`):**
1. Khôi phục chuỗi khi chủ nhóm miễn trừ (NFR-P14, Q-37) → BR-87, BR-88 (tính lại hồi tố; cấp huy hiệu mới đạt, không thu hồi). (US-05.03)
2. Định nghĩa "tổng giờ tập trung" cho huy hiệu → BR-89 (Q-127). (US-05.05)
3. Đổi `badge_milestones` → BR-90 (Q-125). (US-05.05)
4. Kênh và thời điểm thông báo ngắt chuỗi / nhận huy hiệu → BR-91. (US-05.05, US-05.07)
5. Nhật ký thay đổi chuỗi/điểm danh/huy hiệu chỉ-thêm → BR-92. (US-05.08)
6. Hiển thị huy hiệu/chuỗi trên hồ sơ → BR-99 (Q-94). (US-05.06)

## Q- liên quan (đã ghi sổ)

Đã cấp số chính thức trong `ba/02-so-quyet-dinh.md`, trạng thái `Chờ`. Q-94 gộp với câu EP-07 (huy hiệu/chuỗi mặc định ẩn hay hiện).

| Mã | Câu hỏi | Phương án đề xuất | Ảnh hưởng |
| --- | --- | --- | --- |
| Q-93 | Thông báo ngắt chuỗi do D-05 gửi qua push riêng hay gộp vào push "phiên mất thưởng"? | Gộp một push tại `ends_at` ("Phiên mất thưởng tập thể — chuỗi bị ngắt"), chi tiết ở màn kết quả; tránh 2 push liên tiếp | EP-05, EP-04, SNS |
| Q-94 | Huy hiệu/chuỗi mặc định hiện trên hồ sơ cho thành viên cùng nhóm hay ẩn? | Mặc định ẩn, người dùng tự bật (04 §3 "người đó chọn hiện") | EP-05, EP-07, riêng tư |
| Q-95 | Nhận huy hiệu có push không? | Chỉ thông báo trong app (giảm push) | EP-05 |
| Q-96 | Chuỗi là cấp người dùng (mọi nhóm): chủ nhóm A thấy chuỗi bị ngắt do phiên nhóm B — có lộ hoạt động nhóm khác không? | **Đã chốt → D-12**: chủ nhóm không thấy chuỗi; chỉ điểm danh và kết quả phiên trong nhóm mình | EP-05, EP-08, NFR riêng tư |
| Q-97 | Thuật ngữ 01 §8 "Hoàn thành phiên = không ai thoát" mâu thuẫn BR-23 | **Đã chốt → D-11**: "hoàn thành" = COMPLETED; "hoàn thành có thưởng" = COMPLETED và phiên không `forfeited` | EP-05, EP-06, EP-08 |
