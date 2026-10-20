# EP-02 Nhóm

Nguồn: GĐ1 §4.1, §6; D-02, D-06, D-10, D-13, D-14, D-17, D-20, D-21; `01-pham-vi.md` §3 (A-04…A-10), §5; `03-quy-tac.md` BR-01, BR-02, BR-04, BR-09, BR-29, BR-74…BR-80, BR-99, BR-108, BR-109, BR-114 (viết lại theo D-25), §Trạng thái nhóm; `04-nfr-rieng-tu.md` §2, §3 · MoSCoW: Must (Should: US-02.02, 02.04, 02.09 theo D-13; US-02.10b, 02.13, 02.14; US-02.12 Hủy — D-21) · Phụ trách: BA (T-BA-08)

Quy ước: **CN** = chủ nhóm (người tạo nhóm, D-10), **TV** = thành viên, **ND** = người dùng. Quyền CN chỉ áp dụng cho nhóm người đó tạo; server kiểm tra theo cặp (người dùng, nhóm) (NFR-11).
**Sĩ số** (BR-74) = số TV đang hoạt động, **không gồm CN** vì CN không tham gia phiên (D-25) **(đề xuất, Q-141)**; AC ghi rõ dạng “CN + n TV”. Sàn 4 TV, trần 10 TV cố định (D-02). Ví dụ: CN + 10 TV = đầy; CN + 3 TV = dưới sàn.
**Trạng thái nhóm** dùng đúng tên `03-quy-tac.md` §Trạng thái nhóm: HOẠT ĐỘNG, TẠM NGƯNG LỊCH, CHỜ GIẢI TÁN, ĐÃ GIẢI TÁN.
**Mốc giờ phiên** (BR-04): giờ bắt đầu trên lịch = `started_at`; COUNTDOWN bắt đầu lúc `started_at − 5s`.
Sửa 2026-10-06 theo review lần 1: T-BA-30 (AC-02.04.5 sĩ số), T-BA-36 (AC-02.11.5 mốc đếm ngược), T-BA-37 (trạng thái nhóm), T-BA-42 (AC-02.03.4, AC-02.12.2), T-BA-43 (US-02.10 chỉ lịch một lần; lịch lặp tách US-02.10b Should; D-13), T-BA-44 (US-02.13 báo cáo lạm dụng, US-02.14 nhắc trước giờ), T-BA-45 (nguồn US-02.12), T-BA-50 (Q-71); D-14 (US-02.05 → US-01.05, US-02.07 → US-01.07).
Sửa 2026-10-07: D-21 (thành viên tối đa 1 nhóm — AC-02.03.7, AC-02.04.8; US-02.12 Hủy; bỏ cảnh báo trùng lịch nhiều nhóm ở AC-02.11.1); D-20 (bỏ `notify_mode` — BR-83 Hủy — ở AC-02.01.1, US-02.02); D-17 (US-02.10 giữ M); T-BA-63 (AC-02.06.2 theo BR-99).
Sửa 2026-10-19: D-25 (CN không tham gia phiên, quản lý nhiều nhóm — bỏ “nhóm tham gia” ở AC-02.01.1; AC-02.01.4, .6 dựa D-25 thay giả định Q-135); Q-141 (sĩ số tính TV, không gồm CN — AC-02.01.5, AC-02.04.5, AC-02.08.6, AC-02.10.6).

---

## US-02.01 Tạo nhóm

**Là một** Người dùng, **tôi muốn** tạo một nhóm có tên và mục đích sử dụng báo cáo **để** trở thành chủ nhóm và tổ chức phiên tập trung chung.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.1; D-02, D-10, D-21, D-25 · Liên quan: A-04, A-06, NFR-P09, NFR-11, BR-114, BR-74, BR-75

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.01.1 | Bình thường | ND đã đăng nhập | Nhập tên nhóm, mục đích báo cáo, bấm "Tạo nhóm" | Nhóm được tạo ở trạng thái HOẠT ĐỘNG; ND được ghi là CN (đúng 1 CN/nhóm); hệ thống sinh mã mời. CN không có bản ghi tham gia phiên nào của nhóm (D-25) |
| AC-02.01.2 | Lỗi | ND đang ở form tạo nhóm | Để trống trường mục đích báo cáo | Không tạo được nhóm; báo "Cần nhập mục đích sử dụng báo cáo" (NFR-P09) |
| AC-02.01.3 | Lỗi | ND đang ở form tạo nhóm | Để trống tên nhóm | Không tạo được nhóm; báo lỗi tại trường tên |
| AC-02.01.4 | Bình thường | ND đã là CN nhóm A và TV nhóm B | Tạo nhóm C | Tạo thành công; ND là CN của A và C, vẫn là TV của B và vẫn tham gia phiên của B như TV; ở A và C ND chỉ quản lý, không tham gia phiên (D-10, D-25, BR-75 c) **(giả định, Q-150)** |
| AC-02.01.5 | Biên | Nhóm vừa tạo chỉ có CN (CN + 0 TV, sĩ số 0) | CN xem nhóm | Nhóm HOẠT ĐỘNG kèm cảnh báo "Nhóm dưới 4 người — mời thêm"; CN vẫn mời được và đặt lịch được (BR-74) **(đề xuất, Q-68)** |
| AC-02.01.6 | Biên | ND đang là CN của 10 nhóm chưa giải tán | Tạo nhóm thứ 11 | Từ chối kèm thông báo đã đạt giới hạn; với 9 nhóm → tạo được (BR-75 b, `max_groups_owned = 10`). D-25 cho phép quản lý nhiều nhóm; con số 10 vẫn là **(giả định, Q-71)** |

**Ghi chú / giả định:** Không có vai trò "Trưởng phòng" — không ai gán quyền (D-10).

## US-02.02 Sửa thông tin nhóm

**Là một** Chủ nhóm, **tôi muốn** sửa tên và mục đích báo cáo của nhóm **để** thông tin nhóm luôn đúng.

- Ưu tiên: Should (D-13) · Ước lượng: S · Nguồn: GĐ1 §6; D-10, D-13, D-20 (bỏ chế độ báo); A-05, A-14; 04 §2 "Khi nội dung đồng ý thay đổi" · Liên quan: BR-06, BR-71, NFR-P04, NFR-P09, NFR-11

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.02.1 | Bình thường | CN của nhóm A | Đổi tên nhóm | Lưu thành công; TV thấy tên mới; không tăng phiên bản đồng ý (BR-71) |
| AC-02.02.2 | Bình thường | CN của nhóm A có TV đã đồng ý | Đổi mục đích báo cáo | Lưu; phiên bản đồng ý tăng 1; TV chưa đồng ý lại không vào được phiên (BR-06, BR-71; luồng ở US-01.06) |
| AC-02.02.3 | Lỗi | ND là TV (không phải CN) của nhóm A | Gọi API sửa nhóm A | 403; không thay đổi dữ liệu (NFR-11) |
| AC-02.02.4 | Lỗi | CN nhóm A | Xóa trống mục đích báo cáo | Từ chối lưu (NFR-P09) |
| AC-02.02.5 | Biên | Một phiên của nhóm đang ACTIVE | CN đổi mục đích báo cáo | Phiên đang chạy giữ phiên bản đồng ý cũ; yêu cầu đồng ý lại áp dụng cho phiên có `started_at` sau lúc lưu (BR-71) **(đề xuất, Q-72)** |

## US-02.03 Mời bằng mã nhóm

**Là một** Chủ nhóm, **tôi muốn** chia sẻ mã mời **để** đồng nghiệp tự tham gia nhanh.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.1; D-02; A-07 · Liên quan: BR-74, BR-76, NFR-11

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.03.1 | Bình thường | CN nhóm A | Mở "Mời thành viên" | Thấy mã mời 8 ký tự và nút sao chép/chia sẻ (BR-76) |
| AC-02.03.2 | Bình thường | CN nhóm A | Bấm "Tạo mã mới" | Mã cũ hết hiệu lực ngay; mã mới dùng được (BR-76) |
| AC-02.03.3 | Lỗi | ND nhập mã sai / mã đã bị thay | Gửi mã | Báo "Mã không hợp lệ"; không lộ tên nhóm |
| AC-02.03.4 | Lỗi | ND đã nhập sai 4 lần trong 15 phút | Nhập sai lần thứ 5 | Khóa nhập mã 15 phút cho tài khoản đó; trong thời gian khóa, mã đúng cũng bị từ chối "Thử lại sau hh:mm" (BR-76) **(đề xuất, Q-73)** |
| AC-02.03.5 | Biên | Nhóm A có CN + 10 TV (đầy, Q-141) | ND nhập mã đúng rồi bấm đồng ý | Từ chối "Nhóm đã đủ 10 thành viên" (BR-74; kiểm tra lúc đồng ý, AC-01.05.6). Với CN + 9 TV → vào được, thành CN + 10 TV **(đề xuất, Q-141)** |
| AC-02.03.6 | Lỗi | Nhóm A ở CHỜ GIẢI TÁN hoặc ĐÃ GIẢI TÁN | ND nhập mã của A | Báo "Mã không hợp lệ"; không mở màn đồng ý (BR-80) |
| AC-02.03.7 | Lỗi | ND đang là TV nhóm B (chưa giải tán) | Nhập mã đúng của nhóm A rồi bấm đồng ý | Từ chối “Bạn đang ở nhóm B. Rời nhóm B trước khi tham gia nhóm khác.”; không lưu bản ghi đồng ý; vẫn là TV nhóm B (BR-75 a, D-21; AC-01.05.10) |

**Ghi chú / giả định:** Nhập mã chỉ dẫn đến màn đồng ý (US-01.05), chưa tạo tư cách TV (BR-76). Giới hạn 1 nhóm kiểm tra lúc bấm đồng ý, cùng lúc với trần sĩ số (BR-75, BR-74).

## US-02.04 Mời bằng email

**Là một** Chủ nhóm, **tôi muốn** mời đồng nghiệp qua email **để** mời đúng người mà không cần gửi mã thủ công.

- Ưu tiên: Should (D-13) · Ước lượng: M · Nguồn: GĐ1 §4.1; D-02, D-13, D-21; A-07 · Liên quan: BR-74, BR-75, BR-76, NFR-11

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.04.1 | Bình thường | CN nhóm A (HOẠT ĐỘNG) | Nhập email hợp lệ, gửi | Tạo lời mời "đang chờ"; người nhận nhận email có liên kết; nếu đã có tài khoản thì thấy lời mời trong app |
| AC-02.04.2 | Bình thường | Người nhận chưa có tài khoản | Mở liên kết | Được dẫn đăng ký rồi đến màn đồng ý (US-01.05) |
| AC-02.04.3 | Lỗi | CN nhập email sai định dạng | Gửi | Báo lỗi, không tạo lời mời |
| AC-02.04.4 | Lỗi | Email thuộc người đã là TV nhóm A | Gửi | Báo "Người này đã ở trong nhóm"; không gửi email |
| AC-02.04.5 | Biên | Nhóm A có CN + 9 TV (sĩ số 9, còn 1 chỗ) và 3 lời mời đang chờ | CN gửi thêm lời mời; sau đó một người được mời đồng ý | Gửi được (không giới hạn lời mời chờ, kiểm tra trần lúc đồng ý); người đồng ý đầu tiên vào → CN + 10 TV = đầy (Q-141); các lời mời còn lại vẫn mở được nhưng bấm đồng ý bị từ chối "Nhóm đã đủ 10 thành viên" (BR-74, BR-76) **(đề xuất, Q-74)** |
| AC-02.04.6 | Bình thường | Lời mời đang chờ | CN thu hồi | Liên kết hết hiệu lực |
| AC-02.04.7 | Biên | Lời mời gửi lúc T | Người nhận mở liên kết lúc T + 7 ngày | Hết hạn (mốc nửa mở, BR-65); trước mốc đó → mở được (BR-76) **(đề xuất, Q-73)** |
| AC-02.04.8 | Lỗi | Người được mời đang là TV nhóm B | Mở liên kết mời vào nhóm A, bấm đồng ý | Từ chối như AC-02.03.7; lời mời vẫn “đang chờ” đến hết hạn (BR-75 a, D-21). CN nhóm A không được biết người đó ở nhóm nào **(giả định)** |

**Ghi chú / giả định:** Gửi lời mời không kiểm tra người nhận đang ở nhóm khác (để không lộ tư cách thành viên cho CN nhóm A); chặn ở bước đồng ý **(giả định)**. Dùng SES cần địa chỉ đã xác minh ở sandbox (Q-64). Thông báo cho người được mời không nêu dữ liệu của TV khác.

## US-02.05 Tham gia nhóm kèm đồng ý minh bạch (Hủy — gộp vào US-01.05)

Hủy theo D-14. Toàn bộ nội dung nằm ở US-01.05 (`02-ep01-tai-khoan.md`). Ánh xạ AC cũ: AC-02.05.1 → AC-01.05.1; .2 → AC-01.05.2; .3 → AC-01.05.3; .4 → AC-01.05.6; .5 → AC-01.05.4; .6 → AC-01.05.7 (mới chuyển); .7 → AC-01.05.8 (mới chuyển). Không dùng mã AC-02.05.x cho việc mới.

## US-02.06 Xem nhóm của tôi và danh sách thành viên

**Là một** Người dùng, **tôi muốn** thấy các nhóm mình làm chủ và tham gia, cùng danh sách thành viên **để** biết mình thuộc nhóm nào, vai trò gì.

- Ưu tiên: Must · Ước lượng: S · Nguồn: D-10; A-03 · Liên quan: NFR-P06, NFR-11, 04 §3

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.06.1 | Bình thường | ND là CN nhóm A, TV nhóm B | Mở "Nhóm của tôi" | Thấy A (nhãn "Chủ nhóm") và B (nhãn "Thành viên"), mỗi nhóm kèm trạng thái nhóm nếu khác HOẠT ĐỘNG (TẠM NGƯNG LỊCH / CHỜ GIẢI TÁN) |
| AC-02.06.2 | Bình thường | TV nhóm B | Mở danh sách TV nhóm B | Thấy hồ sơ công khai (tên, avatar, khung) và ai là CN; **không** thấy số lần thoát tích lũy, Coins, xếp hạng của người khác; chuỗi/huy hiệu chỉ thấy phần công khai người đó tự bật (BR-99) (NFR-P06, 04 §3, D-12) |
| AC-02.06.3 | Lỗi | ND không thuộc nhóm C | Gọi API danh sách TV nhóm C | 403 (A-03, NFR-11) |
| AC-02.06.4 | Biên | ND không ở nhóm nào | Mở "Nhóm của tôi" | Thấy trạng thái trống + nút "Tạo nhóm" / "Nhập mã" |
| AC-02.06.5 | Biên | Nhóm B ở trạng thái ĐÃ GIẢI TÁN | TV cũ mở "Nhóm của tôi" | B không còn trong danh sách nhóm đang tham gia; dữ liệu của mình ở B vẫn xem được ở "Dữ liệu của tôi" (US-01.08) |
| AC-02.06.6 | Lỗi | ND là CN của nhóm A, B, C | Mở "Nhóm của tôi" (app hoặc API) | Mỗi nhóm hiện tên, nhãn vai trò, trạng thái nhóm, sĩ số, phiên kế tiếp và **tỉ lệ hoàn thành phiên tháng hiện tại của riêng nhóm đó** (tạm tính đến hôm qua); danh sách nhóm sắp theo tên nhóm A→Z; **không** có chỉ số cộng dồn nhiều nhóm (tổng phiên, tổng lần thoát, tỉ lệ chung…) và không so sánh/xếp nhóm theo chỉ số (BR-117, D-21, D-25, D-03) **(đề xuất, Q-145)** |
| AC-02.06.7 | Biên | Nhóm B có TV "Vũ", "An", "Bình" | Mở danh sách TV nhóm B | CN hiện ở dòng riêng đầu danh sách (nhãn "Chủ nhóm", không tham gia phiên — D-25) (ngoại lệ ghi trong BR-115); TV sắp theo tên hiển thị A→Z (An, Bình, Vũ), trùng tên thì theo thời điểm vào nhóm (sớm trước), vẫn trùng thì theo `user_id`; không sắp theo chỉ số hay hoạt động (BR-115, NFR-P06) |

**Ghi chú / giả định:** Theo D-21 một ND là TV của tối đa 1 nhóm; danh sách chỉ có nhiều dòng khi ND làm chủ nhiều nhóm (BR-75 b). CN nhóm A không thấy ND đó làm chủ nhóm nào khác (04 §3) **(giả định)**.

## US-02.07 Thành viên rời nhóm (Hủy — gộp vào US-01.07)

Hủy theo D-14. Rời nhóm = rút đồng ý với nhóm đó; toàn bộ nội dung ở US-01.07 (`02-ep01-tai-khoan.md`). Ánh xạ AC cũ: AC-02.07.1 → AC-01.07.1 (đã thêm “INVITED ở phiên SCHEDULED bị bỏ”); .2 → AC-01.07.2; .3 → AC-01.07.4; .4 → AC-01.07.3; .5 → AC-01.07.6; .6 → AC-01.07.1 (giữ Coins/chuỗi/đồ Shop, BR-59).

## US-02.08 Chủ nhóm xóa thành viên

**Là một** Chủ nhóm, **tôi muốn** xóa một thành viên khỏi nhóm **để** quản lý đúng người trong nhóm.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.1; D-10; A-07 · Liên quan: BR-32, BR-59, BR-74, BR-77, NFR-11

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.08.1 | Bình thường | CN nhóm A, TV Y không trong phiên | Chọn "Xóa khỏi nhóm", xác nhận | Y không còn là TV; Y nhận thông báo "Bạn không còn trong nhóm A"; số liệu đến ngày xóa giữ theo BR-59 (BR-77) |
| AC-02.08.2 | Lỗi | TV (không phải CN) | Gọi API xóa TV khác | 403 (NFR-11) |
| AC-02.08.3 | Lỗi | CN nhóm A | Xóa chính mình | Không cho; gợi ý "Giải tán nhóm" |
| AC-02.08.4 | Biên | Y đang có trạng thái chưa kết thúc trong phiên COUNTDOWN/ACTIVE của nhóm A | CN xóa Y | Hiệu lực sau `ends_at`; kết quả phiên của Y giữ nguyên, không thành WITHDRAWN, không gỡ/kích hoạt D-05 (BR-77) **(đề xuất, Q-76)** |
| AC-02.08.5 | Bình thường | CN đã xóa Y | Xem lại các sự kiện EXITED cũ của Y | Không sửa/xóa được (BR-32) |
| AC-02.08.6 | Biên | Nhóm A có CN + 4 TV (sĩ số 4, đúng sàn, Q-141) | CN xóa 1 TV | Cho xóa; sĩ số 3; hiện cảnh báo "Nhóm dưới 4 người — mời thêm" (BR-74) |

## US-02.09 Giải tán nhóm

**Là một** Chủ nhóm, **tôi muốn** giải tán nhóm **để** kết thúc nhóm khi không còn dùng.

- Ưu tiên: Should (D-13) · Ước lượng: M · Nguồn: D-10, D-13; A-05, A-09; Q-34 · Liên quan: BR-29, BR-62, BR-80, §Trạng thái nhóm, 04 §4; Q-44, Q-77

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.09.1 | Bình thường | Nhóm A HOẠT ĐỘNG, không có phiên COUNTDOWN/ACTIVE | CN chọn "Giải tán", nhập lại tên nhóm để xác nhận | Nhóm → ĐÃ GIẢI TÁN; mọi phiên SCHEDULED → CANCELLED; mọi TV nhận thông báo; mã/lời mời hết hiệu lực (BR-80) |
| AC-02.09.2 | Bình thường | Nhóm A có phiên COUNTDOWN hoặc ACTIVE | CN xác nhận giải tán | Nhóm → CHỜ GIẢI TÁN; phiên đang chạy tiếp tục đến `ends_at`, không ai bị tính thoát/WITHDRAWN do giải tán; phiên SCHEDULED khác → CANCELLED; tại `ends_at` nhóm → ĐÃ GIẢI TÁN (BR-80; §3 #35) **(đề xuất, Q-77)** |
| AC-02.09.3 | Lỗi | TV (không phải CN) | Gọi API giải tán | 403 |
| AC-02.09.4 | Lỗi | Nhóm A ở CHỜ GIẢI TÁN | CN đặt lịch mới hoặc ND bấm đồng ý vào nhóm | Từ chối; nhóm không nhận lịch/thành viên mới (§Trạng thái nhóm) |
| AC-02.09.5 | Bình thường | Nhóm A giải tán ngày 15 | Đến chạy báo cáo tháng | Có báo cáo phần tháng đến ngày 15, gửi người từng là CN (BR-62) **(đề xuất, Q-44)** |
| AC-02.09.6 | Bình thường | Nhóm ở trạng thái ĐÃ GIẢI TÁN | TV cũ xem Coins/chuỗi/huy hiệu | Giữ nguyên; dữ liệu phiên lưu theo 04 §4 (Q-25) |
| AC-02.09.7 | Lỗi | CN nhập sai tên nhóm ở bước xác nhận | Xác nhận | Không giải tán; nhóm giữ trạng thái cũ |

**Ghi chú / giả định:** MVP không chuyển giao CN (BR-80, Q-34; chuyển giao là Could). CN xóa tài khoản → nhóm giải tán (BR-72). Quản trị giải tán nhóm bị báo lạm dụng → US-02.13 / EP-09 (BR-109).

## US-02.10 Đặt lịch phiên một lần

**Là một** Chủ nhóm, **tôi muốn** đặt lịch một phiên 25 hoặc 50 phút vào một ngày giờ cụ thể **để** nhóm có khung giờ tập trung chung.

- Ưu tiên: Must · Ước lượng: M (ước lại từ L sau khi tách lịch lặp; D-17) · Nguồn: GĐ1 §4.1; D-06, D-13 · Liên quan: A-10, BR-01, BR-02, BR-03, BR-04, BR-74, BR-78, BR-79, BR-108, NFR-21

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.10.1 | Bình thường | CN nhóm A (HOẠT ĐỘNG) | Chọn ngày, giờ bắt đầu (giờ VN), thời lượng 25, lưu | Tạo phiên SCHEDULED với `started_at` = giờ đã chọn (BR-04); TV nhóm A thấy lịch và được ghi INVITED |
| AC-02.10.2 | Biên | CN chọn thời lượng | Nhập 30 hoặc 0 | Từ chối; chỉ cho {25, 50} (BR-02) |
| AC-02.10.3 | Lỗi | CN chọn giờ bắt đầu đã qua (theo giờ server) | Lưu | Từ chối "Giờ bắt đầu phải ở tương lai" (BR-03, BR-79) |
| AC-02.10.4 | Lỗi | TV (không phải CN) | Gọi API tạo lịch | 403 (BR-01, D-06) |
| AC-02.10.5 | Lỗi | Phiên mới có [`started_at`, `started_at` + `duration`) giao với phiên chưa hủy khác **của cùng nhóm A** | Lưu | Từ chối "Trùng phiên khác của nhóm" (BR-78) |
| AC-02.10.6 | Biên | Nhóm A có CN + 3 TV (sĩ số 3, Q-141) | CN đặt lịch | Cho đặt; hiện cảnh báo "Nhóm dưới 4 người — mời thêm" (BR-74) **(đề xuất, Q-68)** |
| AC-02.10.7 | Biên | Giờ server là 08:59:00 | CN lưu phiên bắt đầu 08:59:59 / 09:00:00 | 08:59:59 → từ chối (dưới `schedule_min_lead_min` = 1 phút); 09:00:00 → chấp nhận (BR-79) **(đề xuất, Q-79)** |
| AC-02.10.8 | Lỗi | Nhóm A ở TẠM NGƯNG LỊCH (CN bị khóa) hoặc CHỜ GIẢI TÁN | Gọi API tạo lịch | Từ chối; không tạo phiên (BR-108, BR-80, §Trạng thái nhóm) |

**Ghi chú / giả định:** Lịch lặp tách sang US-02.10b (Should). Nhắc TV trước giờ phiên: US-02.14. Phiên tự do không có ở MVP (BR-01).

## US-02.10b Đặt lịch phiên lặp lại

**Là một** Chủ nhóm, **tôi muốn** đặt lịch phiên lặp theo ngày trong tuần **để** không phải tạo tay từng phiên cho khung giờ cố định.

- Ưu tiên: Should (tách khỏi US-02.10 theo review lần 1 #20; ngoài nguồn GĐ1 trực tiếp) · Ước lượng: M · Nguồn: GĐ1 §4.1 (khung giờ chung); D-06, D-13; Q-78 · Liên quan: BR-02, BR-78, BR-79, BR-113

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.10b.1 | Bình thường | CN nhóm A (HOẠT ĐỘNG) | Chọn lặp "Thứ 2–Thứ 6, 9:00, 50 phút" | Tạo chuỗi lịch; mỗi lần lặp là một phiên SCHEDULED riêng, mỗi phiên kiểm tra BR-78 riêng **(đề xuất, Q-78)** |
| AC-02.10b.2 | Bình thường | Phiên thuộc chuỗi lặp, còn SCHEDULED | CN hủy và chọn "chỉ lần này" | Chỉ phiên đó → CANCELLED; các lần khác giữ nguyên (BR-79) |
| AC-02.10b.3 | Bình thường | Như trên | CN hủy và chọn "lần này và các lần sau" | Phiên đó và mọi lần sau còn SCHEDULED → CANCELLED; lần đã qua không đổi (BR-79) |
| AC-02.10b.4 | Lỗi | Một lần lặp trùng phiên một lần đã có của nhóm A | Lưu chuỗi | Từ chối cả chuỗi, chỉ rõ ngày trùng (BR-78) |
| AC-02.10b.5 | Biên | Lần lặp hiện tại đã COUNTDOWN | CN chọn "lần này và các lần sau" | Lần hiện tại không đổi (BR-29); chỉ các lần sau → CANCELLED |

**Ghi chú / giả định:** Ngày kết thúc chuỗi bắt buộc, tối đa `recurrence_max_weeks` = 12 tuần: BR-113 **(đề xuất, Q-78)**.

## US-02.11 Sửa / hủy lịch phiên

**Là một** Chủ nhóm, **tôi muốn** sửa hoặc hủy lịch phiên chưa bắt đầu **để** điều chỉnh theo công việc của nhóm.

- Ưu tiên: Must · Ước lượng: M · Nguồn: D-06; A-10 · Liên quan: BR-02, BR-04, BR-29, BR-65, BR-78, BR-79

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.11.1 | Bình thường | Phiên SCHEDULED của nhóm A | CN đổi giờ hoặc thời lượng (25↔50) | Lưu; TV được thông báo thay đổi; kiểm tra lại BR-78, BR-79 (không kiểm tra trùng với nhóm khác — D-21, BR-10 Hủy) |
| AC-02.11.2 | Bình thường | Phiên SCHEDULED | CN hủy | Phiên → CANCELLED; không ghi dữ liệu; TV được thông báo (BR-29) |
| AC-02.11.3 | Lỗi | Phiên đã COUNTDOWN hoặc ACTIVE | CN sửa hoặc hủy | Từ chối; CN không dừng được phiên đã bắt đầu đếm ngược (BR-29, BR-79) **(đề xuất, Q-29)** |
| AC-02.11.4 | Biên | Phiên lịch 09:00:00 (= `started_at`), COUNTDOWN bắt đầu 08:59:55 (BR-04) | Server nhận yêu cầu hủy lúc 08:59:54,999 / 08:59:55,000 | 08:59:54,999 → hủy được (còn SCHEDULED); 08:59:55,000 → từ chối như AC-02.11.3 (BR-04, BR-65, BR-33) |
| AC-02.11.5 | Lỗi | Phiên SCHEDULED | CN sửa giờ bắt đầu thành thời điểm < giờ server + 1 phút | Từ chối (BR-79) |

**Ghi chú / giả định:** Sửa/hủy lần lặp: US-02.10b.

## US-02.12 Cảnh báo trùng lịch giữa nhiều nhóm (Hủy — D-21)

Hủy theo D-21: một người chỉ là thành viên của tối đa 1 nhóm nên không còn trùng lịch giữa nhiều nhóm của cùng thành viên (BR-10 Hủy). Chủ nhóm sở hữu nhiều nhóm không tham gia phiên (D-25) nên cũng không trùng lịch; không cảnh báo trùng. Mã AC-02.12.1–5 không dùng lại. Q-81 không còn áp dụng; Q-82 (“báo vắng trước”) chuyển ảnh hưởng sang EP-03/EP-08.

## US-02.13 Báo cáo nhóm hoặc hồ sơ lạm dụng

**Là một** Thành viên, **tôi muốn** báo cáo nhóm dùng app để giám sát không mong muốn, hoặc tên/avatar không phù hợp của người cùng nhóm **để** quản trị xem xét mà chủ nhóm không biết tôi là người báo.

- Ưu tiên: Should · Ước lượng: S · Nguồn: GĐ1 §6 (tránh cảm giác bị giám sát); D-10 (ai cũng tạo được nhóm); Q-63, Q-105 · Liên quan: BR-109, BR-80, NFR-11; đầu vào của US-09.06 (EP-09)

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.13.1 | Bình thường | X là TV hiện tại của nhóm A | Chọn "Báo cáo nhóm", chọn lý do, gửi | Tạo ca báo cáo cho quản trị; X thấy "Đã gửi"; CN không nhận thông báo nào (BR-109) |
| AC-02.13.2 | Bình thường | X và Y cùng nhóm A | X báo cáo tên/avatar của Y | Tạo ca báo cáo hồ sơ; Y và CN không biết người báo (BR-109) |
| AC-02.13.3 | Lỗi | ND không thuộc nhóm A (hoặc đã rời) | Gọi API báo cáo nhóm A | 403 (BR-109, NFR-11) |
| AC-02.13.4 | Biên | Đã có ca báo cáo nhóm A lúc T | Người khác báo cáo nhóm A lúc T + 23 giờ 59 phút / T + 24 giờ | Trước 24 giờ → gộp vào ca cũ; từ 24 giờ → ca mới (`abuse_merge_h = 24`, BR-65, BR-109) **(đề xuất, Q-77)** |
| AC-02.13.5 | Lỗi | CN nhóm A gọi API xem danh sách người báo cáo | Gửi yêu cầu | 403 |

## US-02.14 Nhắc thành viên trước giờ phiên

**Là một** Thành viên, **tôi muốn** được nhắc vài phút trước giờ phiên **để** kịp vào phòng chờ.

- Ưu tiên: Should · Ước lượng: S · Nguồn: GĐ1 §4.1 (khung giờ chung); D-06; Q-80 · Liên quan: BR-04, BR-63, BR-79

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-02.14.1 | Bình thường | TV INVITED ở phiên SCHEDULED lúc 09:00 (`started_at`) | Đến 08:55 giờ server | TV nhận push "Phiên nhóm A bắt đầu lúc 09:00" (`reminder_min = 5`, BR-79) **(đề xuất, Q-80)** |
| AC-02.14.2 | Lỗi | Phiên bị hủy lúc 08:54 | Đến 08:55 | Không gửi nhắc |
| AC-02.14.3 | Biên | Phiên được đặt lúc 08:57 cho 09:00 (dưới 5 phút) | Lưu lịch | Không gửi nhắc trễ; TV chỉ nhận thông báo lịch mới |
| AC-02.14.4 | Lỗi | TV đã rút đồng ý / rời nhóm trước 08:55 | Đến 08:55 | Không gửi nhắc cho người đó |

**Ghi chú / giả định:** Nhắc không chứa dữ liệu của TV khác. Push không tới: theo Q-89 (EP-04).

---

## Truy vết

Cập nhật 2026-10-19 (D-25, Q-141): dòng US-02.01, 02.03, 02.04, 02.08, 02.10. Trước đó 2026-10-07 (D-17, D-20, D-21, review lần 2). US-02.05, US-02.07 hủy (D-14); US-02.12 hủy (D-21). Dòng cần cập nhật ở `ba/03-truy-vet.md`: US-02.01, 02.02, 02.03, 02.04, 02.06, 02.11, 02.12. **Ước lượng Must không đổi** (US-02.03 thêm 1 AC, vẫn S; US-02.10 M theo D-17). Should giảm M do US-02.12 hủy.
Sửa 2026-10-19 theo `review/mockup-tong-hop.md` S4, S5: AC-02.06.6 (không cộng chỉ số nhiều nhóm, đề xuất Q-145), AC-02.06.7 (thứ tự theo tên) mới; US-02.06 vẫn S.

Sửa 2026-10-19 theo `review/lan-4.md`: T-BA-126 (AC-02.06.6 thêm chỉ số riêng từng nhóm và thứ tự theo tên nhóm — BR-117; AC-02.06.7 trùng tên theo `user_id` — BR-115, dòng CN đứng đầu gắn "cần BR mới"); T-BA-125 (US-02.01: BR-25 Hủy → BR-114). Ước lượng không đổi.

| Nguồn | US | MoSCoW | BR/NFR | AC |
| --- | --- | --- | --- | --- |
| GĐ1 §4.1; D-02; D-10, D-21, D-25; A-04, A-06; Q-71, Q-141 | US-02.01 | Must | BR-114, BR-74, BR-75, NFR-P09, NFR-11 | AC-02.01.1–6 |
| GĐ1 §6; D-10, D-13, D-20; A-05, A-14; 04 §2 | US-02.02 | Should | BR-06, BR-71, NFR-P04, NFR-P09, NFR-11 | AC-02.02.1–5 |
| GĐ1 §4.1; D-02, D-21; A-07 | US-02.03 | Must | BR-74, BR-75, BR-76, BR-80, NFR-11 | AC-02.03.1–7 |
| GĐ1 §4.1; D-02, D-13, D-21; A-07 | US-02.04 | Should | BR-65, BR-74, BR-75, BR-76, NFR-11 | AC-02.04.1–8 |
| D-14 | US-02.05 | Hủy → US-01.05 | — | — |
| D-03, D-10, D-21, D-25; A-03; 04 §3; T-BA-106, T-BA-107; Q-145 | US-02.06 | Must | BR-99, BR-115, NFR-P06, NFR-11; D-12 | AC-02.06.1–7 |
| D-14 | US-02.07 | Hủy → US-01.07 | — | — |
| GĐ1 §4.1; D-10; A-07 | US-02.08 | Must | BR-32, BR-59, BR-74, BR-77, NFR-11 | AC-02.08.1–6 |
| D-10, D-13; A-05, A-09; Q-34, Q-44, Q-77 | US-02.09 | Should | BR-29, BR-62, BR-80; §Trạng thái nhóm | AC-02.09.1–7 |
| GĐ1 §4.1; D-06, D-13, D-17; A-10 | US-02.10 | Must | BR-01, BR-02, BR-03, BR-04, BR-74, BR-78, BR-79, BR-80, BR-108, NFR-21 | AC-02.10.1–8 |
| GĐ1 §4.1; D-06, D-13; Q-78 | US-02.10b | Should | BR-02, BR-29, BR-78, BR-79, BR-113 | AC-02.10b.1–5 |
| D-06, D-21; A-10 | US-02.11 | Must | BR-02, BR-04, BR-29, BR-33, BR-65, BR-78, BR-79 | AC-02.11.1–5 |
| D-21 | US-02.12 | Hủy — D-21 | — | — |
| GĐ1 §6; D-10; Q-63, Q-105 | US-02.13 | Should | BR-65, BR-80, BR-109, NFR-11 | AC-02.13.1–5 |
| GĐ1 §4.1; D-06; Q-80 | US-02.14 | Should | BR-04, BR-63, BR-79 | AC-02.14.1–4 |

## Q- liên quan (đã ghi sổ)

Đã cấp số chính thức trong `ba/02-so-quyet-dinh.md`, trạng thái `Chờ` (Q-133 cũng Chờ).

| Mã | Câu hỏi | Phương án đề xuất | Ảnh hưởng |
| --- | --- | --- | --- |
| Q-68 | Sĩ số 4–10 (D-02) có tính CN không? Nhóm < 4 người có được đặt lịch/chạy phiên? Phần “tính CN” thay bằng Q-141 (không gồm CN, D-25); trần 10 TV chặn cứng; sàn 4 chỉ cảnh báo (BR-74) | US-02.01, 02.08, 02.10; US-01.05, 01.07 |
| Q-71 | Một người tạo tối đa bao nhiêu nhóm? | Giới hạn 10, cấu hình được (BR-75 b; D-25 cho phép nhiều nhóm) | US-02.01 |
| Q-72 | Đổi mục đích báo cáo khi phiên đang chạy áp dụng lúc nào? (`notify_mode` đã bỏ — D-20) | Từ phiên có `started_at` sau lúc lưu (BR-71) | US-02.02 |
| Q-73 | Mã mời và lời mời email: hạn dùng, độ dài, ngưỡng thử sai? | Mã 8 ký tự, hiệu lực đến khi CN đổi; lời mời email 7 ngày; 5 lần sai/15 phút thì khóa 15 phút (BR-76) | US-02.03, 02.04 |
| Q-74 | Giới hạn số lời mời đang chờ? | Không giới hạn; trần 10 kiểm tra lúc đồng ý | US-02.04 |
| Q-75 | Người đã rời/bị xóa có tham gia lại được? | Được, phải mời lại và đồng ý lại | US-01.07, US-02.08 |
| Q-76 | CN xóa TV đang trong phiên? | Hiệu lực sau `ends_at` (BR-77) | US-02.08 |
| Q-77 | Giải tán khi có phiên COUNTDOWN/ACTIVE? Gộp báo cáo lạm dụng trùng? | Nhóm → CHỜ GIẢI TÁN, giải tán sau `ends_at` (BR-80); gộp trong 24 giờ (BR-109) | US-02.09, 02.13 |
| Q-78 | Lịch lặp lại có ở MVP? Sửa/hủy chuỗi lặp thế nào? | Should (US-02.10b); "lần này" hoặc "lần này và sau" | US-02.10b |
| Q-79 | Khoảng tối thiểu giữa lúc đặt/sửa lịch và giờ bắt đầu? | Đặt/sửa ≥ 1 phút; hủy được đến trước COUNTDOWN | US-02.10, 02.11 |
| Q-80 | TV có được nhắc trước giờ phiên (push)? | Có, 5 phút trước | US-02.14 |
| Q-81 | Cảnh báo trùng lịch cho CN lộ đến mức nào? | Không còn áp dụng (US-02.12 Hủy — D-21); đề nghị điều phối viên đóng | — |
| Q-82 | TV có được "báo vắng trước" một phiên? | Should; ghi ABSENT có ghi chú, không push | EP-03, EP-08 |
| Q-133 | Xác nhận US-02.10 ước lại L → M | Đã chốt D-17 | US-02.10 |
| Q-135 | CN nhiều nhóm: nhóm tham gia; TV nhóm A được tạo nhóm làm chủ? | Đã chốt → D-25 (CN không tham gia phiên) | — |
| Q-141 | Sĩ số 4–10 có gồm CN không? | Không gồm: 4–10 TV (đề xuất, Chờ) | US-02.01, 02.03, 02.04, 02.08, 02.10; US-01.05, 01.07 |
| Q-145 (đã ghi sổ) | Màn "Nhóm của tôi" của CN nhiều nhóm có hiện chỉ số cộng dồn các nhóm không? | Không; chỉ trạng thái cấp nhóm | US-02.06 |

Sửa 2026-10-19 (khớp BR-115): AC-02.06.7 trùng tên theo thời điểm vào nhóm rồi `user_id`; gỡ "cần BR mới" (ngoại lệ chủ nhóm đứng đầu đã có trong BR-115).
