# EP-01 Tài khoản & vai trò

Việc: T-BA-07. Nguồn: GĐ1 §5, §6, §7; D-02, D-03, D-05, D-07, D-10, D-11, D-13, D-14; `01-pham-vi.md` §2–§5 (A-01…A-03, A-08, A-09, A-31…A-33); `03-quy-tac.md` (BR-06, BR-114, BR-26, BR-32, BR-37, BR-48, BR-59, BR-70…BR-74); `04-nfr-rieng-tu.md` §2–§5, NFR-10, NFR-11.
MoSCoW epic: Must (Should: US-01.06 theo D-13; US-01.09, US-01.10, US-01.11) · Phụ trách: (chưa giao)
Sửa 2026-10-06 theo review lần 1: T-BA-30 (sĩ số “CN + n TV”), T-BA-38 (AC-01.07.5, Q-131), T-BA-39 (AC-01.05.9), T-BA-42 (AC-01.10.4), T-BA-43 (D-13), T-BA-45 (nguồn GĐ1/D- cho US-01.06, 01.09, 01.10); D-14: US-02.05 gộp vào US-01.05, US-02.07 gộp vào US-01.07 (AC còn thiếu đã chuyển sang).
Sửa 2026-10-19 theo D-25 và review lần 3: sĩ số không gồm CN (AC-01.05.6, .7, AC-01.07.6 — đề xuất Q-141); CN quản lý nhiều nhóm (ghi chú US-01.04, AC-01.10.2); Q-67 không còn áp dụng; T-BA-58 (AC-01.07.2 nhãn PAUSED); T-BA-76 (AC-01.10.1 theo D-21).
Sửa 2026-10-07: D-20 (bỏ `notify_mode`, BR-84 Hủy — AC-01.05.1, .9; AC-01.06.1), D-21 (AC-01.05.10, .11 — thành viên tối đa 1 nhóm), D-22 (AC-01.08.4 có tên người khởi phát), D-23 (AC-01.07.5, .7 bỏ nhãn giả định Q-131).

Vai trò dùng trong story (D-10): **Người dùng** (mọi tài khoản thường), **Chủ nhóm** / **Thành viên** (theo từng nhóm), **Quản trị** (vai trò hệ thống duy nhất có đặc quyền). Không có vai trò “Trưởng phòng”.
Q- chưa chốt: viết theo phương án đề xuất, gắn **(giả định, Q-xx)**.

---

## US-01.01 Đăng ký và đăng nhập

**Là một** Người dùng, **tôi muốn** đăng ký và đăng nhập bằng email **để** dùng app trên iOS hoặc Android với cùng một tài khoản.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §7, §8; D-07; A-01 · Liên quan: NFR-09, NFR-10, NFR-18

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.01.1 | Bình thường | Email chưa đăng ký | Người dùng nhập email, mật khẩu hợp lệ và mã xác minh email đúng | Tài khoản được tạo trong Cognito với vai trò hệ thống Người dùng; vào màn hình chính; chưa thuộc nhóm nào |
| AC-01.01.2 | Bình thường | Tài khoản đã xác minh | Đăng nhập đúng email/mật khẩu trên máy iOS hoặc Android | Nhận token; thấy cùng dữ liệu tài khoản trên cả hai nền tảng |
| AC-01.01.3 | Lỗi | Tài khoản tồn tại | Nhập sai mật khẩu | Báo “Email hoặc mật khẩu không đúng” (không nói rõ trường nào sai); không cấp token |
| AC-01.01.4 | Lỗi | Email đã đăng ký | Đăng ký lại cùng email | Từ chối, gợi ý “Đăng nhập” hoặc “Quên mật khẩu” |
| AC-01.01.5 | Lỗi | Tài khoản bị Quản trị khóa (A-33) | Đăng nhập | Từ chối, báo tài khoản bị khóa, hướng dẫn liên hệ quản trị |
| AC-01.01.6 | Biên | Đã đăng nhập, token truy cập đã quá 60 phút | Gọi API hoặc kết nối socket | Token được làm mới bằng refresh token; nếu không làm mới được → 401 và về màn đăng nhập (NFR-10) |
| AC-01.01.7 | Bình thường | Tài khoản đã xác minh, người dùng quên mật khẩu | Bấm "Quên mật khẩu", nhập email, nhập mã nhận qua email và mật khẩu mới hợp lệ | Mật khẩu đổi trong Cognito; đăng nhập được bằng mật khẩu mới; mật khẩu cũ bị từ chối **(giả định, Q-65)** |
| AC-01.01.8 | Lỗi | Đang ở bước đặt lại mật khẩu | Nhập mã sai hoặc mã đã hết hạn (theo mặc định Cognito) | Báo "Mã không đúng hoặc đã hết hạn" + nút "Gửi lại mã"; mật khẩu không đổi |
| AC-01.01.9 | Lỗi | Email chưa đăng ký | Yêu cầu "Quên mật khẩu" | Màn hiện cùng câu như email có thật ("Nếu email đã đăng ký, bạn sẽ nhận mã") — không lộ email nào đã có tài khoản **(giả định)** |
| AC-01.01.10 | Lỗi | Màn đăng nhập/đăng ký MVP | Rà giao diện | Không có nút Google, Apple, SSO, Passkey (chờ Q-65); phiên đăng nhập được giữ bằng refresh token, không có ô "ghi nhớ đăng nhập" riêng **(giả định, Q-65)** |

**Ghi chú / giả định:** Phương thức đăng nhập MVP chỉ email + mật khẩu qua Cognito User Pool, có “quên mật khẩu” mặc định của Cognito **(giả định)** → Q-65. Quy tắc độ mạnh mật khẩu dùng chính sách Cognito, không định nghĩa BR riêng **(giả định)**. Không đăng nhập bằng mạng xã hội ở MVP **(giả định)**.

---

## US-01.02 Đăng xuất

**Là một** Người dùng, **tôi muốn** đăng xuất **để** người khác dùng máy không vào được tài khoản của tôi.

- Ưu tiên: Must · Ước lượng: S · Nguồn: A-01 · Liên quan: BR-05, BR-26, NFR-10

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.02.1 | Bình thường | Đã đăng nhập, không trong phiên | Bấm “Đăng xuất” | Thu hồi refresh token, xóa token khỏi máy, hủy đăng ký push của máy này; về màn đăng nhập |
| AC-01.02.2 | Lỗi | Mất mạng | Bấm “Đăng xuất” | Vẫn xóa token cục bộ và về màn đăng nhập; thu hồi token phía server khi có mạng lại **(giả định)** |
| AC-01.02.3 | Biên | Đang ở trạng thái FOCUSING trong phiên | Bấm “Đăng xuất” | Hiện cảnh báo “Bạn đang trong phiên”; nút đăng xuất bị khóa đến khi phiên của mình kết thúc (BR-70) **(đề xuất, Q-66)** |

**Ghi chú / giả định:** Xử lý đăng xuất giữa phiên: **BR-70** (chặn đăng xuất trong phiên, để tránh tạo cách thoát không bị ghi). → Q-66.

---

## US-01.03 Sửa hồ sơ cơ bản

**Là một** Người dùng, **tôi muốn** đặt tên hiển thị và ảnh đại diện **để** đồng nghiệp trong nhóm nhận ra tôi.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.7; A-02, A-03 · Liên quan: NFR-P11; EP-07 (trang trí khung/hình nền)

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.03.1 | Bình thường | Đã đăng nhập | Đổi tên hiển thị và tải ảnh đại diện hợp lệ rồi lưu | Hồ sơ cập nhật; người cùng nhóm thấy tên/ảnh mới ở phần hồ sơ công khai |
| AC-01.03.2 | Lỗi | Đã đăng nhập | Lưu tên hiển thị rỗng hoặc ảnh sai định dạng/quá dung lượng | Từ chối, báo lỗi tại trường, giữ dữ liệu cũ |
| AC-01.03.3 | Lỗi | Người dùng A và B không cùng nhóm nào | A gọi API xem hồ sơ B | 403 (A-03, NFR-11) |
| AC-01.03.4 | Biên | Tên hiển thị dài đúng giới hạn tối đa | Lưu | Chấp nhận; dài hơn 1 ký tự → từ chối |

**Ghi chú / giả định:** Giới hạn độ dài tên, định dạng và dung lượng ảnh: **BR-97, BR-98** (thống nhất với EP-07: tên 2–30 ký tự; ảnh JPG/PNG/WebP ≤ 5 MB, lưu S3; đề xuất cũ ở đây là tên 1–40, ảnh ≤ 2 MB → Q-126). Email không hiển thị cho người cùng nhóm; chỉ Quản trị thấy email (04 §3).

---

## US-01.04 Vai trò theo từng nhóm

**Là một** Người dùng, **tôi muốn** trở thành chủ nhóm khi tôi tạo nhóm và là thành viên khi tôi tham gia nhóm người khác **để** không cần ai cấp quyền mà vẫn được bảo vệ khỏi truy cập chéo nhóm.

- Ưu tiên: Must · Ước lượng: M · Nguồn: D-10; 01 §2–§3; 04 §3 · Liên quan: BR-114, NFR-11, A-04, A-05

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.04.1 | Bình thường | Người dùng U chưa có nhóm | U tạo nhóm G (luồng EP-02) | Server ghi U là chủ nhóm G trong bảng thành viên nhóm (RDS); không thay đổi Cognito group |
| AC-01.04.2 | Bình thường | U là chủ nhóm G và thành viên nhóm H | U mở danh sách nhóm | Thấy G với nhãn “Chủ nhóm”, H với nhãn “Thành viên”; chức năng quản lý chỉ hiện ở G |
| AC-01.04.3 | Lỗi | U là thành viên (không phải chủ) của H | U gọi API sửa nhóm H / xem báo cáo nhóm H / xem sự kiện thoát của thành viên khác trong H | 403; không lộ dữ liệu (NFR-11) |
| AC-01.04.4 | Lỗi | Người dùng thường | Gọi API quản trị | 403; chỉ tài khoản thuộc Cognito group “admin” được phép |
| AC-01.04.5 | Biên | Mỗi nhóm đúng 1 chủ nhóm (D-10) | Có yêu cầu thêm chủ nhóm thứ hai cho G | Từ chối; không có API gán vai trò |

**Ghi chú / giả định:** Không có hành động gán vai trò (01 §3). Việc gán vai trò Quản trị làm thủ công qua Cognito console khi triển khai **(giả định)**. Số nhóm: thành viên của tối đa 1 nhóm (D-21); làm chủ nhiều nhóm (tối đa `max_groups_owned`) và TV một nhóm vẫn được tạo nhóm làm chủ (BR-75 b, c; D-25). Chủ nhóm không tham gia phiên của nhóm mình làm chủ (D-25).

---

## US-01.05 Đồng ý minh bạch khi vào nhóm

**Là một** Thành viên được mời, **tôi muốn** đọc rõ dữ liệu nào được ghi, ai thấy, và luật mất thưởng tập thể trước khi vào nhóm **để** tự quyết định có tham gia hay không.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §6; D-02, D-05, D-08, D-14, D-20, D-21, D-22; 04 §2 · Liên quan: BR-06, BR-27, BR-38, BR-74, BR-75, BR-76, NFR-P04, NFR-P09, NFR-P18, A-08
- Gộp (D-14): story này thay US-02.05 “Tham gia nhóm kèm đồng ý minh bạch”; AC-02.05.6, AC-02.05.7 chuyển thành AC-01.05.7, AC-01.05.8.

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.05.1 | Bình thường | Người dùng nhận lời mời hợp lệ vào nhóm G | Mở lời mời | Thấy một màn có đủ 8 mục của 04 §2 (tên nhóm, chủ nhóm, khung giờ; ghi gì; không ghi gì kèm “khóa màn hình không tính thoát”; luật tập thể D-05; ai thấy; khi bạn thoát, **cả nhóm và mọi người trong phiên nhận ngay thông báo có tên bạn** (D-20, D-22, BR-27); mục đích báo cáo + thời hạn lưu; quyền của bạn) |
| AC-01.05.2 | Bình thường | Đang ở màn đồng ý | Bấm “Đồng ý và vào nhóm” | Trở thành thành viên G; server lưu bản ghi đồng ý (người dùng, nhóm, phiên bản nội dung, thời điểm server); chủ nhóm thấy thành viên mới trong danh sách |
| AC-01.05.3 | Lỗi | Đang ở màn đồng ý | Bấm “Không đồng ý” hoặc đóng màn | Không vào nhóm; không lưu bản ghi đồng ý; chủ nhóm chỉ thấy lời mời “chưa chấp nhận” **(giả định)** |
| AC-01.05.4 | Lỗi | Chưa có bản ghi đồng ý cho G | Gọi trực tiếp API tham gia nhóm hoặc vào phòng chờ phiên của G | 403 (NFR-P04, BR-06) |
| AC-01.05.5 | Biên | Màn đồng ý vừa mở | Kiểm tra giao diện | Không có ô đánh dấu sẵn; nút “Đồng ý” chỉ bật sau khi cuộn đến cuối nội dung **(giả định)** |
| AC-01.05.6 | Biên | Nhóm G có CN + 10 TV (đầy theo BR-74, sĩ số không gồm CN — đề xuất Q-141) | Người được mời bấm “Đồng ý và vào nhóm” | Từ chối “Nhóm đã đủ 10 thành viên”; không lưu bản ghi đồng ý. Với CN + 9 TV → được vào, sĩ số thành 10 |
| AC-01.05.7 | Biên | Nhóm G có CN + 9 TV (còn đúng 1 chỗ, Q-141) | Hai người được mời bấm “Đồng ý” gần như cùng lúc | Yêu cầu server nhận trước được vào (BR-33); người sau bị từ chối “Nhóm đã đủ 10 thành viên”, không lưu bản ghi đồng ý (BR-74) |
| AC-01.05.8 | Lỗi | Người dùng là CN của G | Nhập mã mời / mở liên kết mời của G | Báo “Bạn là chủ nhóm”; không mở màn đồng ý, không tạo tư cách thành viên thứ hai (D-10) |
| AC-01.05.9 | Bình thường | Danh sách trường chủ nhóm thấy ở `03-quy-tac.md` §Báo cáo §2 và nội dung `MEMBER_EXITED`/`SESSION_FORFEITED` (BR-27, BR-38) | So với mục “ghi gì / ai thấy” trên màn đồng ý | Mọi trường đó (kể cả vắng, vào muộn, mất kết nối, số lần gây mất thưởng tập thể, tên + giờ người thoát gửi cho cả nhóm) đều có trên màn đồng ý; thiếu một trường → không đạt (NFR-P04) |
| AC-01.05.10 | Lỗi | Người dùng đang là thành viên nhóm A (chưa giải tán) | Mở lời mời nhóm G, bấm “Đồng ý và vào nhóm” | Từ chối “Bạn đang ở nhóm A. Rời nhóm A trước khi tham gia nhóm khác.”; không lưu bản ghi đồng ý; vẫn là thành viên A (BR-75 a, D-21) |
| AC-01.05.11 | Biên | Người dùng vừa rời nhóm A (US-01.07) / nhóm A vừa ĐÃ GIẢI TÁN | Bấm “Đồng ý và vào nhóm” G | Được vào G (không còn là thành viên nhóm chưa giải tán nào). Nếu nhóm A đang CHỜ GIẢI TÁN → vẫn bị từ chối như AC-01.05.10 (BR-75 a) |

**Ghi chú / giả định:** Nội dung mục đích báo cáo do chủ nhóm điền ở EP-02 (NFR-P09, Q-12). Sĩ số = số thành viên đang hoạt động, không gồm CN (D-25, đề xuất Q-141); trần kiểm tra lúc bấm đồng ý (BR-74). Nhập mã chỉ mở màn này, chưa tạo tư cách thành viên (BR-76). Nội dung màn đồng ý trong 04 §2 mục 2 phải được bổ sung đủ trường (T-BA-39, ngoài tệp này). Không còn chế độ báo để chọn — chỉ báo ngay (D-20, BR-83 Hủy). Màn đồng ý cũng phải nêu “bạn chỉ thuộc được 1 nhóm” (D-21) **(giả định)**. Chủ nhóm không cần đồng ý với nhóm mình tạo vì không tham gia phiên (D-25); Q-67 không còn áp dụng.

---

## US-01.06 Đồng ý lại khi điều khoản nhóm thay đổi

**Là một** Thành viên, **tôi muốn** được hỏi lại khi nội dung đồng ý của nhóm thay đổi **để** không bị ghi dữ liệu theo điều kiện tôi chưa chấp nhận.

- Ưu tiên: Should (D-13) · Ước lượng: S · Nguồn: GĐ1 §6 (đồng ý minh bạch trước khi bị ghi); D-13; 04 §2 “Khi nội dung đồng ý thay đổi” · Liên quan: BR-06, BR-26, BR-71, NFR-P04

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.06.1 | Bình thường | Chủ nhóm đổi mục đích báo cáo → phiên bản nội dung tăng | Thành viên mở app | Hiện màn đồng ý mới, đánh dấu phần thay đổi; đồng ý → lưu bản ghi phiên bản mới |
| AC-01.06.2 | Lỗi | Thành viên chưa đồng ý phiên bản mới | Vào phòng chờ phiên kế tiếp | Bị chặn, mở màn đồng ý (BR-06) |
| AC-01.06.3 | Lỗi | Thành viên chọn “Không đồng ý” với phiên bản mới | Xác nhận | Xử lý như rút đồng ý (US-01.07) |
| AC-01.06.4 | Biên | Nội dung thay đổi khi thành viên đang FOCUSING | Phiên đang chạy | Phiên hiện tại tiếp tục theo phiên bản cũ; yêu cầu đồng ý lại áp dụng cho phiên có `started_at` sau lúc lưu (BR-71) **(đề xuất, Q-72)** |

**Ghi chú / giả định:** Danh sách thay đổi nào làm tăng phiên bản đồng ý: **BR-71** (mục đích báo cáo, thời hạn lưu, điều khoản/quy tắc D-05; MVP không có chuyển chủ nhóm). `notify_mode` đã bỏ (D-20) — nếu BR-71 còn liệt kê thì **cần sửa BR-71** (ba-rules).

---

## US-01.07 Rút đồng ý và rời nhóm

**Là một** Thành viên, **tôi muốn** rút lại đồng ý bất cứ lúc nào **để** dừng việc ghi dữ liệu mà không bị phạt.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §6; D-05, D-14, D-23; 04 §2 · Liên quan: BR-26, BR-32, BR-37, BR-48, BR-59, BR-74, A-09 **(giả định, Q-20, Q-60)**
- Gộp (D-14): story này thay US-02.07 “Thành viên rời nhóm” (rời nhóm = rút đồng ý với nhóm đó); ý “lời mời phiên sắp tới bị bỏ” của AC-02.07.1 chuyển vào AC-01.07.1.

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.07.1 | Bình thường | Thành viên nhóm G, không trong phiên | Vào cài đặt nhóm → “Rời nhóm / Rút đồng ý” → xác nhận bước 2 | Rời G ngay; ngừng ghi mới; trạng thái INVITED của X ở các phiên SCHEDULED của G bị bỏ; chủ nhóm chỉ nhận “X đã rời nhóm”, không kèm lý do; Coins, đồ Shop, chuỗi, hồ sơ, nhật ký giữ nguyên; số liệu G đến ngày rời giữ theo BR-59 |
| AC-01.07.2 | Bình thường | Thành viên đang FOCUSING/GRACE/DISCONNECTED trong phiên của G *(PAUSED: chỉ kiểm khi US-03.06 trong phạm vi — T-BA-58)* | Rút đồng ý | Trạng thái → WITHDRAWN ngay (ưu tiên hơn mọi hạn đang chạy); dừng ghi; không tính thoát, **không** gửi `MEMBER_EXITED` cho ai, không Coins, **không** đặt `forfeited` (BR-26, BR-36) |
| AC-01.07.3 | Lỗi | Người dùng là chủ nhóm G | Tìm “Rút đồng ý” ở G | Không có nút; chỉ có “Giải tán nhóm” (EP-02, Q-34) |
| AC-01.07.4 | Lỗi | Thành viên bấm “Rút đồng ý” | Hủy ở bước xác nhận thứ 2 | Không thay đổi gì |
| AC-01.07.5 | Biên | Phiên G có `forfeited = true`, X đang trong phiên từ trước `forfeited_at` | X rút đồng ý sau `forfeited_at`, trước `ends_at` | X → WITHDRAWN, rời G; 0 Coins; **vẫn bị ngắt chuỗi** tại `ends_at` (BR-26, BR-37, BR-48, §3 #26; D-23) |
| AC-01.07.6 | Biên | Nhóm G có CN + 4 TV (sĩ số 4, không gồm CN — đề xuất Q-141) | Một thành viên rút đồng ý | Vẫn cho rút; sĩ số còn 3; chủ nhóm thấy cảnh báo “Nhóm dưới 4 người — mời thêm”; nhóm vẫn đặt lịch và chạy phiên (BR-74) **(đề xuất, Q-68)** |
| AC-01.07.7 | Biên | Phiên G `forfeited = false`, X đang FOCUSING | X rút đồng ý, sau đó người khác EXITED | X giữ WITHDRAWN, không bị ngắt chuỗi, không nằm trong phạm vi BR-37 (§3 #26b; D-23: rút trước `forfeited_at` không kích hoạt D-05) |

**Ghi chú / giả định:** Số liệu phiên cũ giữ đến ngày rời theo BR-59 và thời hạn lưu 04 §4 (Q-25). Muốn vào lại nhóm phải được mời lại và đồng ý lại (BR-76) **(đề xuất, Q-75)**. WITHDRAWN do quản trị khóa tài khoản không bị ngắt chuỗi (BR-37, BR-108) — thuộc EP-09.

---

## US-01.08 Xem “Dữ liệu của tôi”

**Là một** Người dùng, **tôi muốn** xem mọi dữ liệu hệ thống lưu về tôi, với đúng độ chi tiết chủ nhóm thấy **để** biết mình bị ghi những gì.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §5, §6; A-31 · Liên quan: NFR-P03, NFR-P11, NFR-P18, BR-53

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.08.1 | Bình thường | Người dùng có dữ liệu ở ≥1 nhóm | Mở “Dữ liệu của tôi” | Thấy mọi loại ở cột “Thành viên (của mình)” ma trận 04 §3: sự kiện thoát + thời điểm, kết quả phiên, lý do tạm dừng, giải trình, điểm danh/chuỗi, Coins, đồ Shop, hồ sơ, nhật ký, báo cáo tháng phần mình, bản ghi đồng ý; lọc được theo nhóm |
| AC-01.08.2 | Bình thường | Chủ nhóm G xem dữ liệu thành viên X trong G | So với màn “Dữ liệu của tôi” của X lọc theo G | Mọi trường chủ nhóm thấy đều có ở màn của X, cùng độ chi tiết (NFR-P03) |
| AC-01.08.3 | Lỗi | Người dùng A | Gọi API “dữ liệu của tôi” với `user_id` của B | 403 (NFR-11) |
| AC-01.08.4 | Biên | X ở phiên `forfeited` nhưng không phải người khởi phát | Xem kết quả phiên đó | Thấy “Phiên đã mất thưởng tập thể do ‹Tên người khởi phát› rời phiên” (BR-38, D-22, NFR-P18); **không** thấy lý do tạm dừng, giải trình, Coins hay số lần thoát tích lũy của người đó (NFR-P06) |
| AC-01.08.5 | Biên | Người dùng chưa vào nhóm nào | Mở màn | Hiện các mục cá nhân (hồ sơ, Coins, nhật ký); mục dữ liệu nhóm hiện “Chưa có dữ liệu” |

**Ghi chú / giả định:** Màn này chỉ đọc; sửa sai qua giải trình/khiếu nại (EP-04, NFR-P13, NFR-P14).

---

## US-01.09 Xuất dữ liệu của tôi

**Là một** Người dùng, **tôi muốn** tải dữ liệu của mình dạng JSON/CSV **để** lưu giữ hoặc đối chiếu độc lập.

- Ưu tiên: Should · Ước lượng: M · Nguồn: GĐ1 §5, §6 (minh bạch dữ liệu, quyền của người bị ghi); A-31; 04 §5 · Liên quan: NFR-P12 **(đề xuất)**, NFR-P11

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.09.1 | Bình thường | Đã đăng nhập | Chọn “Xuất dữ liệu” + định dạng JSON hoặc CSV | Yêu cầu được ghi nhận; trong ≤ 24h có thông báo kèm link tải (S3 presigned) chứa đủ các loại dữ liệu của US-01.08 |
| AC-01.09.2 | Lỗi | Link đã tạo hơn 7 ngày | Mở link | Hết hạn; app cho tạo yêu cầu mới |
| AC-01.09.3 | Lỗi | Người khác có link | Mở link sau khi hết hạn hoặc sửa tham số | Bị từ chối (chữ ký không hợp lệ) |
| AC-01.09.4 | Biên | Đã có yêu cầu xuất đang xử lý | Gửi yêu cầu thứ hai | Từ chối, báo “Đang xử lý yêu cầu trước” **(giả định)** |

**Ghi chú / giả định:** Tệp xuất không chứa dữ liệu của người khác, ngoài tên người khởi phát đã hiện trên kết quả phiên của chính mình (D-22) **(giả định)**. Tệp xuất trên S3 tự xóa sau 7 ngày **(giả định)**.

---

## US-01.10 Xóa tài khoản

**Là một** Người dùng, **tôi muốn** xóa tài khoản **để** dữ liệu cá nhân của tôi không còn được lưu.

- Ưu tiên: Should · Ước lượng: L · Nguồn: GĐ1 §6 (xử lý dữ liệu khi không còn đồng ý); D-10 (CN xóa tài khoản → nhóm giải tán); A-31; 04 §4, §5 · Liên quan: NFR-P13, BR-26, BR-62, BR-70, BR-72, BR-80 **(đề xuất, Q-25, Q-34, Q-69)**

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.10.1 | Bình thường | Thành viên của nhóm G (tối đa 1 nhóm, D-21), không trong phiên | Chọn “Xóa tài khoản”, nhập lại mật khẩu, xác nhận | Rời G như rút đồng ý (không kèm lý do); đăng nhập bị chặn ngay; dữ liệu xóa theo 04 §4 và hoàn tất ≤ 30 ngày; số liệu trong báo cáo tổng nhóm đã phát hành giữ dạng ẩn danh **(giả định)** |
| AC-01.10.2 | Bình thường | Người dùng là chủ nhóm G và H (D-25: quản lý nhiều nhóm) | Xác nhận xóa tài khoản | Cảnh báo trước liệt kê đủ “Nhóm G, H sẽ bị giải tán”; xác nhận → cả G và H chuyển ĐÃ GIẢI TÁN (BR-80), báo cáo phần tháng theo BR-62 |
| AC-01.10.3 | Lỗi | Nhập sai mật khẩu xác nhận | Xác nhận | Không xóa; báo lỗi |
| AC-01.10.4 | Lỗi | Người dùng có trạng thái chưa kết thúc (WAITING/FOCUSING/GRACE/PAUSED/DISCONNECTED) trong một phiên | Chọn “Xóa tài khoản” | Từ chối, báo “Đang trong phiên — thử lại sau khi phiên kết thúc”; không thay đổi dữ liệu (BR-72, BR-70) |
| AC-01.10.5 | Biên | Đã xóa được 30 ngày | Kiểm tra RDS, DynamoDB, S3, Cognito | Không còn bản ghi gắn định danh người này (trừ bản sao lưu ≤ 35 ngày, nhật ký đồng ý/truy cập theo hạn 04 §4) |

**Ghi chú / giả định:** Không có thời gian chờ hủy (BR-72) **(đề xuất, Q-69)**. Quy tắc xóa tài khoản (thứ tự rời nhóm, giải tán, ẩn danh, xử lý sổ cái Coins bất biến BR-44) → **BR-72**.

---

## US-01.11 Xem ai đã xem dữ liệu của tôi

**Là một** Thành viên, **tôi muốn** xem nhật ký mỗi lần chủ nhóm hoặc quản trị xem/xuất dữ liệu của tôi **để** biết dữ liệu được dùng ra sao.

- Ưu tiên: Should · Ước lượng: M · Nguồn: GĐ1 §5; A-32 · Liên quan: NFR-P07 **(đề xuất, Q-21)**, Q-22

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước | Khi | Thì |
| --- | --- | --- | --- | --- |
| AC-01.11.1 | Bình thường | Chủ nhóm G mở báo cáo tháng có dòng của X | X mở “Ai đã xem dữ liệu của tôi” | Thấy bản ghi: người xem, vai trò (Chủ nhóm G / Quản trị), loại dữ liệu, hành động (xem/xuất), thời điểm |
| AC-01.11.2 | Bình thường | Quản trị xem sự kiện thoát của X khi xử lý khiếu nại | X mở nhật ký truy cập | Có bản ghi kèm mã ca xử lý **(giả định, Q-22)** |
| AC-01.11.3 | Lỗi | Người dùng A | Gọi API nhật ký truy cập của B | 403 |
| AC-01.11.4 | Biên | X tự xem dữ liệu của mình | Mở nhật ký truy cập | Không tạo bản ghi cho chính mình **(giả định)** |

**Ghi chú / giả định:** Nhật ký truy cập lưu DynamoDB, thời hạn theo 04 §4. Xem nhiều lần liên tiếp có gộp không → **BR-73** (gộp cùng người xem + cùng dữ liệu trong 10 phút).

---

## Truy vết

Cập nhật 2026-10-19 (D-25, Q-141, T-BA-58, T-BA-76): dòng US-01.04, 01.05, 01.07, 01.10; ước lượng không đổi. Trước đó 2026-10-07 (D-20…D-23). Dòng cần cập nhật ở `ba/03-truy-vet.md`: US-01.04, 01.05, 01.06, 01.07, 01.08. **Ước lượng Must không đổi** (US-01.05 thêm 2 AC, vẫn M).
Sửa 2026-10-19 theo `review/mockup-tong-hop.md` S9: AC-01.01.7–10 (quên mật khẩu, không đăng nhập mạng xã hội — T-BA-93); dùng luồng mặc định Cognito, US-01.01 vẫn M.

| Nguồn | US | MoSCoW | BR/NFR | AC |
| --- | --- | --- | --- | --- |
| GĐ1 §7, §8; D-07; A-01; Q-65; T-BA-93 | US-01.01 | Must | NFR-09, NFR-10, NFR-18 | AC-01.01.1–10 |
| A-01 (GĐ1 §7) | US-01.02 | Must | BR-05, BR-26, BR-70, NFR-10 | AC-01.02.1–3 |
| GĐ1 §4.7; A-02, A-03 | US-01.03 | Must | BR-97, BR-98, NFR-11, NFR-P11 | AC-01.03.1–4 |
| D-10, D-21, D-25; A-04, A-05; 04 §3 | US-01.04 | Must | BR-114, BR-75, NFR-11 | AC-01.04.1–5 |

Sửa 2026-10-19 theo `review/lan-4.md` T-BA-125: BR-25 (Hủy, D-25) → BR-114 ở đầu tệp, US-01.04 và dòng truy vết.
| GĐ1 §6; D-02, D-05, D-08, D-14 (thay US-02.05), D-20, D-21, D-22, D-25; A-08; 04 §2; Q-141 | US-01.05 | Must | BR-06, BR-27, BR-33, BR-38, BR-74, BR-75, BR-76, NFR-P04, NFR-P09, NFR-P18 | AC-01.05.1–11 |
| GĐ1 §6; D-13, D-20; 04 §2 | US-01.06 | Should | BR-06, BR-26, BR-71, NFR-P04 | AC-01.06.1–4 |
| GĐ1 §6; D-05, D-14 (thay US-02.07), D-23; A-09; 04 §2; Q-20, Q-60, Q-141 | US-01.07 | Must | BR-26, BR-32, BR-36, BR-37, BR-48, BR-59, BR-74, BR-76 | AC-01.07.1–7 |
| GĐ1 §5, §6; D-22; A-31; 04 §3, §5 | US-01.08 | Must | BR-38, NFR-P03, NFR-P06, NFR-P11, NFR-P18, NFR-11 | AC-01.08.1–5 |
| GĐ1 §5, §6; D-22; A-31; 04 §5 | US-01.09 | Should | NFR-P12, NFR-P18 | AC-01.09.1–4 |
| GĐ1 §6; D-10, D-21, D-25; A-31; 04 §4, §5; Q-25, Q-34, Q-69 | US-01.10 | Should | NFR-P13, BR-26, BR-44, BR-62, BR-70, BR-72, BR-80 | AC-01.10.1–5 |
| GĐ1 §5; A-32; Q-21, Q-22 | US-01.11 | Should | NFR-P07, BR-73 | AC-01.11.1–4 |

## Q- liên quan (đã ghi sổ)

1. **Q-65** Phương thức đăng nhập MVP: chỉ email + mật khẩu (Cognito), hay thêm Google/Apple? (Apple bắt buộc “Sign in with Apple” nếu có đăng nhập mạng xã hội trên iOS.) Đề xuất: chỉ email + mật khẩu. Ảnh hưởng: EP-01, D-07.
2. **Q-66** Đăng xuất hoặc đăng nhập trên máy khác khi đang trong phiên thì xử lý thế nào? Đề xuất: chặn đăng xuất trong phiên; đăng nhập máy thứ hai không chiếm phiên đang chạy, socket chỉ chấp nhận một thiết bị/phiên. Ảnh hưởng: EP-01, EP-03, BR phiên.
3. **Q-67** (Q-19 × A-08) Chủ nhóm tham gia phiên của nhóm mình có cần màn đồng ý riêng (luật D-05 áp cho chính mình) không? Đề xuất: hiện xác nhận ngắn lần đầu bật “tham gia phiên”. Ảnh hưởng: EP-01, EP-03. **Không còn áp dụng — D-25** (chủ nhóm không tham gia phiên); đề nghị điều phối viên đóng.
4. **Q-68** (gộp với câu EP-02 về sĩ số) (D-02) Thành viên rút đồng ý/xóa tài khoản làm nhóm còn dưới 4 người: nhóm vẫn chạy phiên, bị tạm khóa lịch, hay chỉ cảnh báo chủ nhóm? Đề xuất: vẫn chạy, cảnh báo chủ nhóm mời thêm (không được chặn quyền rút đồng ý). Ảnh hưởng: EP-01, EP-02.
5. **Q-69** Xóa tài khoản có thời gian chờ để hủy (vd. 7 ngày) không? Đề xuất: không ở MVP, xóa ngay sau xác nhận mật khẩu. Ảnh hưởng: EP-01, NFR riêng tư.
6. **Q-70** Sổ cái Coins bất biến (BR-44) khi xóa tài khoản: xóa hẳn các dòng hay ẩn danh `user_id`? Đề xuất: ẩn danh để giữ tính toàn vẹn sổ cái. Ảnh hưởng: EP-01, EP-06.
