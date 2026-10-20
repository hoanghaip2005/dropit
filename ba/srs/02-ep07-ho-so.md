# EP-07 Hồ sơ & Nhật ký

Nguồn: GĐ1 §4.4, §4.7, §6, §7; D-03, D-07, D-09, D-10, D-12, D-13, D-14, D-15; Q-06 (đề xuất: nhật ký chỉ riêng tư)  ·  MoSCoW: Must (hồ sơ cơ bản, viết nhật ký, nhật ký riêng tư — D-15); Should (avatar, xem hồ sơ người khác — D-13; xem/sửa, xóa nhật ký — D-15)  ·  Phụ trách: ba-stories (T-BA-14)

Phạm vi theo `01-pham-vi.md`: A-02, A-03, A-26, A-27; ma trận "ai thấy gì" `04-nfr-rieng-tu.md` §3 (dòng Hồ sơ, Điểm danh/chuỗi, Đồ Shop, Nhật ký). Ngoài phạm vi MVP: chia sẻ nhật ký với bạn bè (EP-10, Q-06). Mua/trang bị đồ Shop thuộc EP-06; EP-07 chỉ **hiển thị** đồ đang trang bị. Cấp huy hiệu thuộc EP-05 (BR-52); EP-07 chỉ hiển thị.

Vai trò (D-10): mọi hành động trong epic này là hành động cá nhân của **Người dùng**, không phụ thuộc vai trò chủ nhóm/thành viên. "Người cùng nhóm" = hai người cùng thuộc ít nhất một nhóm (chủ nhóm hoặc thành viên).

Phần công khai của hồ sơ (BR-99, **đề xuất Q-104**): tên hiển thị, avatar, khung đang trang bị, hình nền đang trang bị, huy hiệu/chuỗi người đó chọn hiển thị. Không bao giờ thuộc phần công khai: Coins (BR-53), số lần thoát (NFR-P06), sự kiện phiên, nhật ký (NFR-P05), email (chỉ Quản trị thấy). Chủ nhóm không thấy chuỗi qua bất kỳ kênh nào ngoài phần công khai người dùng tự bật (D-12). Màn bật "hiện chuỗi" nằm ở US-05.06 (EP-05): mặc định tắt, phải hiện câu cảnh báo "Mọi người cùng nhóm, kể cả chủ nhóm, sẽ thấy chuỗi này" trước khi bật được (NFR-P17, T-BA-68) — EP-07 chỉ hiển thị kết quả.

---

## US-07.01 Xem hồ sơ của tôi

**Là một** Người dùng, **tôi muốn** xem hồ sơ của mình với avatar, khung, hình nền và thành tích **để** thấy thành quả tập trung của bản thân.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.7 · Liên quan: BR-51, BR-52, BR-53, NFR-P03, A-02

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-07.01.1 | Bình thường | Người dùng đã đăng nhập, đang trang bị khung K và hình nền H, có huy hiệu "Chuỗi 7 ngày" | Mở tab Hồ sơ | Thấy tên hiển thị, avatar trong khung K, hình nền H, `current_streak`, `longest_streak`, danh sách huy hiệu đã đạt (BR-51, BR-52) và số dư Coins (chỉ mình thấy) |
| AC-07.01.2 | Bình thường | Người dùng chưa trang bị đồ nào, chưa có avatar | Mở tab Hồ sơ | Hiện avatar mặc định (chữ cái đầu tên), khung và hình nền mặc định (BR-95); mục thành tích hiện "Chưa có huy hiệu" |
| AC-07.01.3 | Lỗi | Mất mạng, máy có bản lưu gần nhất | Mở tab Hồ sơ | Hiện bản đã lưu kèm nhãn "Chưa cập nhật" |
| AC-07.01.4 | Lỗi | Mất mạng, máy chưa có bản lưu | Mở tab Hồ sơ | Hiện thông báo lỗi và nút "Thử lại" |
| AC-07.01.5 | Biên | Người dùng có `current_streak = 0`, `longest_streak = 14` (chuỗi vừa bị ngắt) | Mở tab Hồ sơ | Hiện chuỗi hiện tại 0, chuỗi dài nhất 14; huy hiệu "Chuỗi 14 ngày" vẫn còn (BR-52 không thu hồi) |

**Ghi chú / giả định:** Coins và chuỗi hiển thị trên hồ sơ của mình; Coins không bao giờ thuộc phần công khai (BR-53); chuỗi chỉ công khai khi người dùng tự bật (BR-99, D-12).

## US-07.02 Sửa tên hiển thị (Hủy — gộp vào US-01.03)

Theo D-14, story này đã gộp vào **US-01.03**. Giới hạn tên hiển thị: BR-97. Không phát triển, không ước lượng, không kiểm thử riêng story này; mã AC-07.02.x không còn dùng.

## US-07.03 Đổi ảnh avatar

**Là một** Người dùng, **tôi muốn** tải ảnh avatar từ máy **để** cá nhân hóa hồ sơ.

- Ưu tiên: Should (D-13) · Ước lượng: M · Nguồn: GĐ1 §4.7; `04-nfr` Ánh xạ AWS (S3) · Liên quan: A-02, NFR-09, NFR-12, BR-98

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-07.03.1 | Bình thường | Người dùng chọn ảnh JPG 1 MB từ thư viện/camera | Cắt ảnh vuông và bấm Lưu | App xin URL tải lên ký hạn (presigned) từ server, tải ảnh lên S3 qua HTTPS, server xác nhận và cập nhật avatar; avatar mới hiện kèm khung đang trang bị |
| AC-07.03.2 | Lỗi | — | Chọn tệp không phải JPG/PNG/WebP (vd. GIF, PDF) | Từ chối trước khi tải lên, báo định dạng hợp lệ; avatar cũ giữ nguyên (BR-98) |
| AC-07.03.3 | Biên | `avatar_max_mb = 5` (BR-98) | Tải ảnh đúng 5 MB / 5 MB + 1 byte | 5 MB: chấp nhận; vượt: từ chối, báo giới hạn |
| AC-07.03.4 | Lỗi | Đang tải lên thì mất mạng hoặc URL ký hạn đã hết hạn | Tải lên thất bại | Avatar cũ giữ nguyên; báo lỗi + "Thử lại"; server không lưu tham chiếu tới tệp chưa xác nhận |
| AC-07.03.5 | Bình thường | Người dùng có avatar | Bấm "Xóa ảnh" | Trở về avatar mặc định; tệp cũ trên S3 bị xóa (BR-98) |
| AC-07.03.6 | Bình thường | Ảnh tải lên có EXIF vị trí | Server xử lý ảnh | Ảnh phát hành không còn EXIF, kích thước ≤ 512×512 px (BR-98) |

**Ghi chú / giả định:** Kiểm duyệt ảnh không phù hợp → Q-105, BR-109. Quyền camera/thư viện ảnh chỉ xin khi người dùng bấm đổi ảnh (NFR-P01 rà manifest). Định dạng, dung lượng, kích thước, cách lưu/xóa: BR-98 (Q-126).

## US-07.04 Hiển thị khung và hình nền đang trang bị

**Là một** Người dùng, **tôi muốn** hồ sơ hiện khung avatar và hình nền tôi đã trang bị **để** thấy đồ mua bằng Coins có giá trị.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.6, §4.7 · Liên quan: EP-06 (mua/trang bị), A-02, BR-95, BR-96, ma trận §3 dòng "Đồ Shop đã mua"

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-07.04.1 | Bình thường | Người dùng vừa trang bị khung K2 ở Shop (EP-06) | Mở hồ sơ của mình hoặc người cùng nhóm mở hồ sơ đó | Cả hai thấy khung K2 và hình nền đang trang bị |
| AC-07.04.2 | Bình thường | Người dùng gỡ khung | Mở hồ sơ | Hiện khung mặc định (BR-95) |
| AC-07.04.3 | Lỗi | Ảnh khung/hình nền trên S3 không tải được | Mở hồ sơ | Hiện avatar/hình nền mặc định, không lỗi màn hình; trạng thái trang bị không đổi |
| AC-07.04.4 | Biên | Quản trị chuyển món K sang ĐÃ ẨN trong khi người dùng đang trang bị K | Mở hồ sơ | Vẫn hiển thị K; trạng thái trang bị không đổi (BR-96) |

**Ghi chú / giả định:** Mỗi loại (khung, hình nền) trang bị tối đa 1 món (BR-95). Thành viên khác chỉ thấy đồ **đang trang bị**, không thấy kho đồ đã mua (ma trận §3).

## US-07.05 Chọn thành tích hiển thị công khai (Hủy — gộp vào US-05.06)

> **Trạng thái: Hủy (D-16).** Nội dung đã gộp vào US-05.06 (EP-05, Should). Không ước lượng, không kiểm thử theo mã AC-07.05.x. Bảng AC dưới giữ lại chỉ để lưu vết.

**Ánh xạ AC (D-16)**

| AC cũ | AC mới | Cách chuyển |
| --- | --- | --- |
| AC-07.05.1 | AC-05.06.5 | Chuyển nguyên (bao trùm AC-05.06.2, thêm chuỗi) |
| AC-07.05.2 | AC-05.06.6 | Chuyển nguyên |
| AC-07.05.3 | AC-05.06.7 | Chuyển nguyên |
| AC-07.05.4 | AC-05.06.8 | Chuyển nguyên |
| AC-07.05.5 | AC-05.06.9 | Chuyển nguyên |

**Là một** Người dùng, **tôi muốn** chọn huy hiệu và chuỗi nào hiện cho người cùng nhóm **để** tự quyết điều mình chia sẻ.

- Ưu tiên: — (Hủy, D-16; trước đó Should) · Ước lượng: — · Nguồn: GĐ1 §4.4, §6; D-12; D-16 · Liên quan: BR-51, BR-52, BR-99, NFR-P06

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-07.05.1 | Bình thường | Người dùng có 4 huy hiệu, mặc định không hiện huy hiệu/chuỗi công khai (BR-99, đề xuất Q-94) | Chọn hiện 2 huy hiệu và bật "hiện chuỗi hiện tại" | Người cùng nhóm (kể cả chủ nhóm) thấy đúng 2 huy hiệu và chuỗi hiện tại; không thấy 2 huy hiệu còn lại |
| AC-07.05.2 | Lỗi | — | Gọi API chọn hiển thị một huy hiệu chưa đạt | Từ chối (400); danh sách hiển thị không đổi |
| AC-07.05.3 | Biên | `showcase_max_badges = 3` (BR-99) | Chọn huy hiệu thứ 3 / thứ 4 | Thứ 3: chấp nhận; thứ 4: từ chối, báo "Tối đa 3" |
| AC-07.05.4 | Bình thường | Chuỗi hiện tại đang bật công khai, sau đó bị ngắt (BR-47) | Người cùng nhóm mở hồ sơ | Thấy chuỗi = 0; không thấy lý do ngắt (không lộ phiên `forfeited`/thoát — NFR-P06, Q-50) |
| AC-07.05.5 | Bình thường | Người dùng tắt "hiện chuỗi hiện tại" | Chủ nhóm gọi API hồ sơ của người đó | Phản hồi không có trường chuỗi (D-12) |

**Ghi chú / giả định:** Không có mục "số lần thoát", Coins hay xếp hạng trên hồ sơ (D-03, NFR-P06, BR-53). Đã gộp vào US-05.06 theo D-16.

## US-07.06 Xem hồ sơ công khai của người cùng nhóm

**Là một** Người dùng, **tôi muốn** mở hồ sơ của người cùng nhóm **để** biết họ là ai và xem thành tích họ chọn chia sẻ.

- Ưu tiên: Should (D-13) · Ước lượng: S · Nguồn: GĐ1 §4.7, §6; D-10, D-12; `04-nfr` §3 · Liên quan: A-03, BR-53, BR-99, NFR-P05, NFR-P06, NFR-11

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-07.06.1 | Bình thường | A và B cùng ở nhóm N (vai trò bất kỳ) | A bấm vào B trong danh sách thành viên | A thấy phần công khai của B: tên, avatar, khung, hình nền, huy hiệu/chuỗi B chọn hiện; **không** có Coins, số lần thoát, sự kiện phiên, nhật ký, email |
| AC-07.06.2 | Lỗi | A và C không cùng nhóm nào | A gọi API hồ sơ của C | 403 (A-03 "✖ ngoài nhóm") |
| AC-07.06.3 | Bình thường | Quản trị | Mở hồ sơ người dùng bất kỳ | Thấy phần công khai + email tài khoản; không thấy nhật ký (NFR-P05) |
| AC-07.06.4 | Biên | B vừa rời nhóm N (rút đồng ý, BR-26) và không còn nhóm chung với A | A mở lại hồ sơ B từ danh sách cũ | API trả 403; app hiện "Người dùng không còn trong nhóm" |
| AC-07.06.5 | Bình thường | Chủ nhóm N mở hồ sơ thành viên X | Mở hồ sơ | Chỉ thấy phần công khai như mọi người cùng nhóm; không có điểm danh, kết quả phiên hay chuỗi (trừ chuỗi X tự bật). Điểm danh/kết quả phiên trong nhóm N xem ở màn "Thành viên nhóm" của chủ nhóm và báo cáo EP-08 (D-12) |

**Ghi chú / giả định:** Xem hồ sơ công khai **không** ghi nhật ký truy cập (BR-73, BR-99, đề xuất Q-106). Chuỗi chỉ hiện khi chủ hồ sơ đã bật qua màn có cảnh báo NFR-P17 (US-05.06; mặc định tắt). Tên người thoát được biết trong nhóm/phiên (D-22) nhưng hồ sơ vẫn không có số lần thoát tích lũy (NFR-P06; đề xuất Q-137).

## US-07.07 Viết nhật ký hằng ngày

**Là một** Người dùng, **tôi muốn** viết vài dòng nhật ký mỗi ngày **để** tự nhìn lại việc tập trung của mình mà chủ nhóm và quản trị không xem được.

- Ưu tiên: Must (D-15) · Ước lượng: M · Nguồn: GĐ1 §4.7, §6, §7; D-15; Q-06 · Liên quan: A-26, NFR-P05, NFR-12, NFR-21, BR-100

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-07.07.1 | Bình thường | Hôm nay (giờ VN) chưa có mục nhật ký | Viết nội dung và bấm Lưu | Lưu thành một mục gắn ngày hôm nay; nội dung mã hóa khi lưu (NFR-12); màn viết hiện nhãn "Chủ nhóm và quản trị không xem được trong app" (BR-100) |
| AC-07.07.2 | Lỗi | — | Lưu nội dung rỗng | Từ chối, báo "Nhật ký trống"; không tạo mục |
| AC-07.07.3 | Biên | `journal_max_chars = 5000` (BR-100) | Lưu 5.000 / 5.001 ký tự | 5.000: chấp nhận; 5.001: từ chối, hiện bộ đếm ký tự |
| AC-07.07.4 | Biên | Đồng hồ VN 23:59:59 khi bấm Lưu, server nhận lúc 00:00:01 | Lưu | Mục thuộc ngày mới theo thời điểm **server nhận** quy ra Asia/Ho_Chi_Minh (BR-100, NFR-21) |
| AC-07.07.5 | Bình thường | Hôm nay đã có mục | Mở "Viết nhật ký" | Mở mục hôm nay để viết tiếp (1 mục/ngày, BR-100, đề xuất Q-107) |
| AC-07.07.6 | Lỗi | Mất mạng khi bấm Lưu | Lưu | Giữ bản nháp trên máy, báo "Chưa lưu lên máy chủ" + "Thử lại"; không mất nội dung đã gõ |

**Ghi chú / giả định:** Nhật ký **không** liên quan phiên: viết lúc nào cũng được, không ghi sự kiện phiên, không ảnh hưởng Coins/chuỗi/báo cáo (BR-100; `04-nfr` §2 mục 3). Bản nháp cục bộ lưu trong vùng lưu trữ an toàn của app **(giả định)**. Ở MVP tối thiểu (D-15) chỉ cần viết/xem mục hôm nay; xem danh sách và sửa mục cũ là US-07.08 (Should).

## US-07.08 Xem lại và sửa nhật ký

**Là một** Người dùng, **tôi muốn** xem danh sách nhật ký theo ngày và sửa mục cũ **để** bổ sung suy nghĩ của mình.

- Ưu tiên: Should (D-15) · Ước lượng: S · Nguồn: GĐ1 §4.7; D-15 · Liên quan: A-26, BR-100, NFR-P05, NFR-P11, NFR-P12

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-07.08.1 | Bình thường | Có 20 mục nhật ký | Mở danh sách nhật ký | Thấy mục mới nhất trước, mỗi mục có ngày + đoạn đầu; tải thêm khi cuộn |
| AC-07.08.2 | Bình thường | Mục ngày 01/10 | Sửa nội dung và Lưu | Nội dung cập nhật, ghi `updated_at`; ngày của mục giữ nguyên 01/10; không lưu phiên bản cũ (BR-100) |
| AC-07.08.3 | Lỗi | Sửa thành nội dung rỗng | Lưu | Từ chối; gợi ý dùng "Xóa" nếu muốn bỏ mục (US-07.09) |
| AC-07.08.4 | Biên | `journal_max_chars = 5000` | Sửa thành 5.001 ký tự | Từ chối; nội dung đã lưu giữ nguyên |
| AC-07.08.5 | Lỗi | Sửa cùng mục trên 2 máy | Máy thứ hai lưu bản dựa trên phiên bản cũ | Server trả xung đột (409), hiện bản mới nhất để người dùng chọn giữ bản nào **(giả định — ngoài nguồn GĐ1, lan-1 #20, nguồn cũ đã xóa)** |

**Ghi chú / giả định:** Sửa mục cũ không giới hạn thời gian (BR-100). Nhật ký có trong "Dữ liệu của tôi" và tệp xuất (NFR-P11, NFR-P12).

## US-07.09 Xóa mục nhật ký

**Là một** Người dùng, **tôi muốn** xóa một mục nhật ký **để** không còn lưu điều tôi không muốn giữ.

- Ưu tiên: Should (D-15) · Ước lượng: S · Nguồn: GĐ1 §6; D-15 · Liên quan: A-26, BR-100, NFR-P13, `04-nfr` §4 dòng "Nhật ký"

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-07.09.1 | Bình thường | Có mục ngày 01/10 | Bấm Xóa và xác nhận | Mục biến mất khỏi danh sách và API ngay; bản ghi bị xóa thẳng khỏi kho lưu, không có thùng rác (BR-100, NFR-P13) |
| AC-07.09.2 | Lỗi | — | Bấm Xóa rồi bấm Hủy ở hộp xác nhận | Không xóa gì |
| AC-07.09.3 | Lỗi | Mục đã bị xóa trên máy khác | Xóa lại mục đó | Trả "Không tìm thấy" (404), không lỗi màn hình |
| AC-07.09.4 | Biên | Mục đã xóa | Sau 35 ngày | Không còn trong bản sao lưu (`04-nfr` §4: sao lưu ≤ 35 ngày) |
| AC-07.09.5 | Bình thường | Người dùng xóa tài khoản | Hoàn tất xóa tài khoản | Mọi mục nhật ký bị xóa (BR-72, `04-nfr` §4) |

**Ghi chú / giả định:** Xóa thẳng theo BR-100 (đề xuất Q-108).

## US-07.10 Chủ nhóm và quản trị không xem được nhật ký trong app

**Là một** Người dùng, **tôi muốn** chắc chắn chủ nhóm và quản trị không có cách nào xem nhật ký của tôi trong app **để** viết thật lòng mà không lo bị đánh giá.

- Ưu tiên: Must (D-15) · Ước lượng: M · Nguồn: GĐ1 §6, §7; D-15; Q-06 · Liên quan: A-27, BR-100, NFR-P05, NFR-11, NFR-12, R-P04, R-P10

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-07.10.1 | Bình thường | Chủ sở hữu nhật ký | Gọi API nhật ký của chính mình | 200, đọc được nội dung đã giải mã |
| AC-07.10.2 | Lỗi | Token của chủ nhóm của người viết | Gọi API đọc nhật ký người đó | 403; không trả nội dung, số mục hay ngày viết |
| AC-07.10.3 | Lỗi | Token Quản trị (nhóm Cognito "admin") | Gọi API đọc nhật ký bất kỳ người dùng | 403; Web Admin (EP-09) không có màn/endpoint nhật ký |
| AC-07.10.4 | Lỗi | Token người cùng nhóm | Đoán `entry_id` và gọi API | 404 (test IDOR, NFR-11; không xác nhận mục có tồn tại) |
| AC-07.10.5 | Bình thường | Rà kho lưu (DynamoDB) | Đọc bản ghi nhật ký trực tiếp | Trường nội dung là bản mã hóa, không đọc được văn bản gốc (NFR-12) |
| AC-07.10.6 | Bình thường | Rà log ứng dụng CloudWatch | Sau khi lưu/sửa nhật ký | Log không chứa nội dung nhật ký |
| AC-07.10.7 | Bình thường | Rà mọi chuỗi giao diện và màn đồng ý | Tìm câu mô tả quyền đọc nhật ký | Chỉ dùng câu "Chủ nhóm và quản trị không xem được trong app" (BR-100, `04-nfr` §2 mục 3); không có câu "Chỉ mình bạn đọc được" hay "Không ai khác đọc được" |

**Ghi chú / giả định:** Mã hóa phía server (BR-100, đề xuất Q-109): người vận hành có quyền hạ tầng về kỹ thuật vẫn giải mã được (R-P10), nên nhãn chỉ hứa điều kiểm tra được là không có màn/API trong app (lan-1 #17, nguồn cũ đã xóa). Câu chữ cần chuyên gia pháp lý duyệt (Q-134). Hồ sơ không hiển thị số mục nhật ký cho người khác (ma trận §3: ✖).

---

## Truy vết

| Story | Hành động (01-pham-vi) | BR | NFR / ma trận | Nguồn | MoSCoW |
| --- | --- | --- | --- | --- | --- |
| US-07.01 | A-02 | BR-51, BR-52, BR-53, BR-95 | NFR-P03; §3 Hồ sơ | GĐ1 §4.7 | Must |
| US-07.02 | — | BR-97 | — | D-14 (Hủy — gộp vào US-01.03) | — |
| US-07.03 | A-02 | BR-98 | NFR-P01, NFR-09, NFR-12; S3 | GĐ1 §4.7; D-13 | Should |
| US-07.04 | A-02 | BR-95, BR-96 | §3 Đồ Shop | GĐ1 §4.6, §4.7 | Must |
| US-07.05 | A-02 | (Hủy — gộp vào US-05.06) BR-47, BR-51, BR-52, BR-99 | NFR-P06; §3 Điểm danh/chuỗi | GĐ1 §4.4, §6; D-12; D-16; Q-50 | — (Hủy, D-16; AC → AC-05.06.5–9) |
| US-07.06 | A-03 | BR-26, BR-53, BR-73, BR-99 | NFR-P05, NFR-P06, NFR-P17 (màn bật ở US-05.06), NFR-11; §3 Hồ sơ | GĐ1 §4.7, §6; D-10, D-12, D-13, D-22; Q-137 | Should |
| US-07.07 | A-26 | BR-100 | NFR-P05, NFR-12, NFR-21 | GĐ1 §4.7, §6, §7; D-15; Q-06 | Must |
| US-07.08 | A-26 | BR-100 | NFR-P05, NFR-P11, NFR-P12 | GĐ1 §4.7; D-15 | Should |
| US-07.09 | A-26 | BR-72, BR-100 | NFR-P13; §4 Nhật ký | GĐ1 §6; D-15 | Should |
| US-07.10 | A-27 | BR-100 | NFR-P05, NFR-11, NFR-12; R-P04, R-P10 | GĐ1 §6, §7; D-15; Q-06 | Must |

## Q- liên quan (đã ghi sổ)

Đã cấp số chính thức trong `ba/02-so-quyet-dinh.md`, trạng thái `Chờ`.

| Mã | Câu hỏi | Đề xuất | Ảnh hưởng |
| --- | --- | --- | --- |
| Q-104 | Phần công khai của hồ sơ gồm những trường nào? | Tên, avatar, khung, hình nền đang trang bị, huy hiệu/chuỗi tự chọn; không Coins, không số lần thoát | EP-07, `04-nfr` §3 |
| Q-105 | Có kiểm duyệt tên/avatar không phù hợp không? | MVP: không lọc tự động; người cùng nhóm báo cáo, quản trị đặt lại về mặc định (BR-109) | EP-07, EP-09 |
| Q-94 | Huy hiệu/chuỗi mặc định hiện công khai hay ẩn? | Mặc định ẩn, người dùng tự bật | EP-07, `04-nfr` §3 |
| Q-106 | Xem hồ sơ công khai có ghi nhật ký truy cập (NFR-P07)? | Không | EP-07, EP-01 |
| Q-107 | Nhật ký 1 mục/ngày hay nhiều mục/ngày? | 1 mục/ngày | EP-07 |
| Q-108 | Xóa nhật ký: xóa thẳng hay thùng rác 30 ngày? | Xóa thẳng ở MVP | EP-07, `04-nfr` §4 |
| Q-109 | Mã hóa nhật ký phía server (KMS) hay đầu-cuối? | MVP phía server; E2E làm sau | EP-07, NFR-12 |
| Q-126 | Giới hạn tên/avatar giữa EP-01 và EP-07 | Theo BR-97, BR-98 | EP-01, EP-07 |
| Q-134 | Câu chữ về quyền truy cập của người vận hành hạ tầng cần pháp lý duyệt? | Có duyệt | US-07.10 |

**BR đã dùng (`03-quy-tac.md`):** BR-97 (tên), BR-98 (avatar), BR-99 (trưng bày), BR-100 (nhật ký, nhãn giao diện), BR-95/BR-96 (trang bị, món ĐÃ ẨN).
