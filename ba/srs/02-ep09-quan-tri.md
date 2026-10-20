# EP-09 Quản trị

Nguồn: GĐ1 §3, §6; D-09, D-10; `01-pham-vi.md` (A-17, A-33, EP-09); `04-nfr-rieng-tu.md` (NFR-P05, NFR-P07, NFR-P14, R-P05, R-P09, NFR-11, Cognito nhóm "admin")  ·  MoSCoW: Should  ·  Phụ trách: Web Admin (+ Backend)

Việc: T-BA-17. Theo D-10, **Quản trị** là vai trò hệ thống đặc quyền duy nhất (nhóm Cognito "admin"); quản trị **không** gán vai trò chủ nhóm và không có quyền chủ nhóm trong bất kỳ nhóm nào. Phạm vi MVP tối thiểu: có thể thay giao diện bằng dữ liệu nạp sẵn khi demo (`01-pham-vi.md` EP-09). Các Q- còn Chờ (Q-22, Q-37, Q-63) dùng phương án đề xuất và ghi rõ.

Nguyên tắc chung cho mọi story dưới đây:
- Mọi API quản trị kiểm tra nhóm Cognito "admin" ở server; token người dùng thường → 403 (NFR-11).
- Quản trị **không bao giờ** đọc được nội dung nhật ký cá nhân (NFR-P05) và không thấy tên app/nội dung máy (BR-34).
- Mọi lần quản trị xem/xuất dữ liệu cá nhân của một người dùng, hoặc thay đổi dữ liệu của họ, đều sinh một bản ghi **nhật ký truy cập** (NFR-P07).

## US-09.01 Đăng nhập Web Admin

**Là một** Quản trị, **tôi muốn** đăng nhập vào Web Admin bằng tài khoản thuộc nhóm "admin" **để** chỉ người được ủy quyền mới thực hiện được thao tác quản trị.

- Ưu tiên: Should · Ước lượng: S · Nguồn: D-10; 04 §Cognito · Liên quan: NFR-11, EP-01

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-09.01.1 | Bình thường | Tài khoản thuộc nhóm Cognito "admin" | Đăng nhập Web Admin | Vào bảng điều khiển quản trị; thấy các mục Tài khoản, Shop, Khiếu nại, Báo cáo nhóm, Coins, Nhật ký truy cập |
| AC-09.01.2 | Lỗi | Tài khoản thường (kể cả là chủ nhóm của nhiều nhóm) | Đăng nhập Web Admin hoặc gọi trực tiếp API `/admin/*` | Bị từ chối (403), thông báo "Không có quyền quản trị"; không lộ dữ liệu nào |
| AC-09.01.3 | Lỗi | Tài khoản quản trị đã bị gỡ khỏi nhóm "admin" khi đang có phiên đăng nhập | Thực hiện thao tác quản trị tiếp theo | Bị từ chối 403 khi token được làm mới (giả định, Q-116) |

**Ghi chú / giả định:** Không có màn hình tạo/gán quản trị trong app; tài khoản quản trị tạo trực tiếp trên Cognito bởi nhóm phát triển (giả định) → Q-116. MFA cho quản trị: đề xuất bật (giả định) → Q-116.

## US-09.02 Khóa / mở tài khoản người dùng

**Là một** Quản trị, **tôi muốn** tìm và khóa hoặc mở khóa tài khoản người dùng kèm lý do **để** ngăn tài khoản vi phạm hoặc bị chiếm quyền tiếp tục sử dụng hệ thống.

- Ưu tiên: Should · Ước lượng: M · Nguồn: GĐ1 §3; A-33 · Liên quan: BR-09, BR-114, BR-45, NFR-P07

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-09.02.1 | Bình thường | Người dùng đang hoạt động, không trong phiên | Quản trị tìm theo email, chọn "Khóa", nhập lý do | Tài khoản bị khóa: không đăng nhập được, token hiện có bị thu hồi; ghi nhật ký truy cập (quản trị, người bị khóa, thời điểm, lý do) |
| AC-09.02.2 | Bình thường | Tài khoản đang bị khóa | Quản trị chọn "Mở khóa", nhập lý do | Người dùng đăng nhập lại được; dữ liệu cũ (nhóm, Coins, chuỗi) giữ nguyên; ghi nhật ký truy cập |
| AC-09.02.3 | Lỗi | Không nhập lý do | Bấm "Khóa"/"Mở khóa" | Không thực hiện; báo "Bắt buộc nhập lý do" |
| AC-09.02.4 | Lỗi | Quản trị chọn khóa chính tài khoản của mình | Bấm "Khóa" | Từ chối: "Không thể tự khóa tài khoản quản trị" |
| AC-09.02.5 | Biên | Người dùng đang trong phiên (FOCUSING) | Bị khóa | Kết nối socket bị cắt; theo **BR-108**: không coi là thoát, không kích hoạt D-05, ghi WITHDRAWN (`ACCOUNT_LOCKED`), không rời nhóm → Q-117 |
| AC-09.02.6 | Biên | Người bị khóa là chủ nhóm của nhóm HOẠT ĐỘNG có 2 phiên SCHEDULED | Bị khóa | Nhóm chuyển TẠM NGƯNG LỊCH; 2 phiên SCHEDULED → CANCELLED; thành viên được báo; không đặt lịch mới; khiếu nại đang mở của nhóm → CHUYỂN QUẢN TRỊ (BR-108, máy trạng thái nhóm/khiếu nại, đề xuất Q-118) |
| AC-09.02.7 | Biên | Chủ nhóm bị khóa đúng `lock_dissolve_days = 30` ngày / 30 ngày + 1 phút | Hệ thống kiểm tra | 30 ngày: nhóm vẫn TẠM NGƯNG LỊCH; quá 30 ngày: nhóm → ĐÃ GIẢI TÁN (BR-80, BR-108) |
| AC-09.02.8 | Bình thường | Chủ nhóm của nhóm TẠM NGƯNG LỊCH được mở khóa | Quản trị "Mở khóa" | Nhóm về HOẠT ĐỘNG, chủ nhóm đặt lịch lại được; phiên đã CANCELLED không tự khôi phục |

**Ghi chú / giả định:** Danh sách tài khoản chỉ hiện email, tên hiển thị, trạng thái, ngày tạo, số nhóm; **không** hiện Coins, sự kiện phiên hay nhật ký. Không có xóa cứng tài khoản ở đây (xóa theo quyền dữ liệu cá nhân thuộc EP-01). Hệ quả khóa tài khoản lên nhóm/phiên/Coins: BR-108.

## US-09.03 Quản lý danh mục Shop

**Là một** Quản trị, **tôi muốn** thêm, sửa, ẩn vật phẩm trong Shop (tên, mô tả, ảnh, giá Coins, loại) **để** người dùng có vật phẩm để đổi Coins.

- Ưu tiên: Should · Ước lượng: M · Nguồn: D-09; EP-06 · Liên quan: BR-44, BR-45, BR-52 (Q-38)

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-09.03.1 | Bình thường | Quản trị ở trang Shop | Tạo món hợp lệ với trạng thái ĐANG BÁN và lưu | Món xuất hiện trong Shop của mọi người dùng trong ≤1 phút; ghi nhật ký quản trị (BR-106) |
| AC-09.03.2 | Bình thường | Món ĐANG BÁN đã có người mua | Quản trị chuyển sang ĐÃ ẨN | Món không còn hiện/mua được; người đã mua vẫn sở hữu, trang bị và hiển thị trên hồ sơ; dòng sổ cái SHOP_PURCHASE cũ không đổi (BR-44, BR-96) |
| AC-09.03.3 | Lỗi | Giá không phải số nguyên dương, thiếu tên, ảnh hoặc loại | Lưu | Không lưu; báo lỗi theo trường (BR-93) |
| AC-09.03.4 | Lỗi | Món đã có người mua | Quản trị chọn "Xóa" | Không cho xóa; gợi ý chuyển ĐÃ ẨN (BR-93) |
| AC-09.03.5 | Biên | `shop_price_min = 10`, `shop_price_max = 1000` (BR-93) | Lưu giá 9 / 10 / 1000 / 1001 | 10 và 1000: lưu được; 9 và 1001: từ chối kèm miền |
| AC-09.03.6 | Biên | Người dùng đang mở trang mua với giá cũ | Quản trị đổi giá rồi người dùng bấm mua | Giao dịch dùng giá server lúc xác nhận; khác giá đã hiển thị → báo "Giá đã thay đổi", yêu cầu xác nhận lại (BR-94, BR-96, đề xuất Q-119) |
| AC-09.03.7 | Bình thường | Món ĐÃ ẨN chưa ai mua | Quản trị chuyển sang ĐANG BÁN hoặc xóa | Chuyển được / xóa được (BR-93) |

**Ghi chú / giả định:** Loại món MVP: khung avatar, hình nền, danh hiệu (BR-93); huy hiệu bán trong Shop là Could (Q-38). Tên trạng thái chuẩn: ĐANG BÁN / ĐÃ ẨN. Quy tắc danh mục Shop (giá tối thiểu/tối đa, đổi giá, ẩn vs xóa, giới hạn mua 1 lần/vật phẩm): **BR-93, BR-94, BR-96, BR-106**. Có thể thay bằng seed dữ liệu khi demo.

## US-09.04 Điều chỉnh Coins có kiểm toán

**Là một** Quản trị, **tôi muốn** cộng/trừ Coins của một người dùng kèm lý do bắt buộc **để** sửa sai do lỗi hệ thống hoặc kết quả khiếu nại mà vẫn giữ sổ cái minh bạch.

- Ưu tiên: Should · Ước lượng: M · Nguồn: D-09 · Liên quan: BR-44, BR-45, NFR-P07, BR-53

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-09.04.1 | Bình thường | Người dùng có số dư 40 | Quản trị nhập +25, lý do, mã tham chiếu (khiếu nại/phiên) và xác nhận | Thêm một dòng sổ cái `type = ADMIN_ADJUST`, `amount = +25`, `reason`, `ref_id`; số dư = 65; ghi nhật ký truy cập; người dùng nhận thông báo "Coins được điều chỉnh: +25, lý do: …" |
| AC-09.04.2 | Lỗi | Bất kỳ | Bỏ trống lý do | Từ chối (BR-45) |
| AC-09.04.3 | Lỗi | Bất kỳ | Cố sửa hoặc xóa một dòng sổ cái đã có (qua UI hoặc API) | Không có chức năng; API trả 405/403; chỉ được thêm dòng bù trừ (BR-44) |
| AC-09.04.4 | Biên | Số dư 40 | Nhập −40 | Thành công, số dư = 0 |
| AC-09.04.5 | Biên | Số dư 40 | Nhập −41 | Từ chối: số dư không được âm (BR-45) |
| AC-09.04.6 | Biên | Người dùng đã nhận đủ `coins_daily_cap` = 100 trong ngày | Quản trị cộng +25 | ADMIN_ADJUST **không** tính vào trần ngày (đề xuất) → **BR-107**, Q-120 |
| AC-09.04.7 | Lỗi | Bất kỳ | Nhập 0 | Từ chối: "Số điều chỉnh phải khác 0" |
| AC-09.04.8 | Biên | `admin_adjust_confirm = 500` (BR-107) | Nhập +500 / +501 | +500: thực hiện sau một lần xác nhận; +501: hiện hộp xác nhận lần hai, chỉ ghi sổ cái khi xác nhận (đề xuất Q-120) |

**Ghi chú / giả định:** Quản trị chỉ thấy số dư và sổ cái của người đang được xử lý (mở xem = một bản ghi nhật ký truy cập). Coins không hiển thị cho chủ nhóm (BR-53) — điều chỉnh không gửi thông báo cho chủ nhóm. ADMIN_ADJUST có tính trần ngày không; ngưỡng xác nhận mỗi lần: BR-107.

## US-09.05 Xử lý khiếu nại / lỗi chuyển lên quản trị

**Là một** Quản trị, **tôi muốn** nhận và xử lý các khiếu nại không thể giải quyết trong nhóm (lỗi hệ thống, hoặc khiếu nại liên quan chính chủ nhóm) **để** người dùng có kênh sửa sai công bằng.

- Ưu tiên: Should · Ước lượng: L · Nguồn: GĐ1 §3 (vai trò quản trị), §6, §10 #3 (rủi ro phạt oan); NFR-P14; A-17, A-20; Q-22, Q-37 · Liên quan: BR-34, BR-35, BR-37, BR-44, BR-45, BR-54, BR-86, BR-87, BR-88, BR-110, máy trạng thái KHIẾU NẠI; NFR-P05, NFR-P07

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-09.05.1 | Bình thường | Có ca khiếu nại trạng thái CHUYỂN QUẢN TRỊ, chưa gán | Quản trị mở ca | Ca gán cho quản trị đó, trạng thái giữ CHUYỂN QUẢN TRỊ; **chỉ khi đó** quản trị thấy sự kiện thoát chi tiết (thời điểm, GRACE/EXITED, lý do tạm dừng) **của người trong ca**; mỗi lần mở ghi nhật ký truy cập (BR-110, BR-73, đề xuất Q-22) |
| AC-09.05.2 | Bình thường | Ca CHUYỂN QUẢN TRỊ gán cho quản trị; xác định phát hiện thoát là lỗi hệ thống | Chấp nhận kèm lý do | Ca → MIỄN TRỪ; EXITED gắn `exempted`, cờ phiên tính lại (BR-87); Coins bù bằng `SESSION_REWARD` mới theo ngày của phiên, chuỗi khôi phục (BR-88), không dùng ADMIN_ADJUST (BR-110); người khiếu nại nhận kết quả |
| AC-09.05.3 | Bình thường | Ca CHUYỂN QUẢN TRỊ gán cho quản trị; khiếu nại không có cơ sở | Bác kèm lý do | Ca → BÁC; người khiếu nại nhận lý do; không đổi Coins/chuỗi |
| AC-09.05.4 | Lỗi | Bấm Chấp nhận/Bác không nhập lý do | Lưu | Không đổi trạng thái; báo "Bắt buộc nhập lý do" |
| AC-09.05.5 | Lỗi | Ca đang CHỜ XỬ LÝ / ĐANG XỬ LÝ (chủ nhóm xử lý), hoặc quản trị không được gán ca | Quản trị cố xem sự kiện thoát chi tiết qua UI hoặc API | 403 (BR-110) |
| AC-09.05.6 | Lỗi | Bất kỳ | Quản trị cố xem nội dung nhật ký cá nhân hoặc tên app | Không có chức năng; API trả 403 (NFR-P05, BR-34) |
| AC-09.05.7 | Biên | Ca ở MIỄN TRỪ hoặc BÁC | Quản trị "mở lại để xem" kèm lý do | Xem được; trạng thái giữ nguyên, không đổi kết quả; ghi nhật ký truy cập mới (BR-86) |
| AC-09.05.8 | Lỗi | Ca CHUYỂN QUẢN TRỊ | Chủ nhóm gọi API quyết định ca | 403 — chủ nhóm mất quyền xử lý (BR-110) |

**Ghi chú / giả định:** Điều kiện vào CHUYỂN QUẢN TRỊ (người khiếu nại là chủ nhóm, quá `appeal_escalate_h = 72` giờ, "nghi lỗi hệ thống", nhóm ĐÃ GIẢI TÁN, chủ nhóm bị khóa): BR-86 và máy trạng thái KHIẾU NẠI (đề xuất Q-91). BR-54 nói giải trình không hoàn Coins — khiếu nại được chấp nhận là trường hợp khác; điều kiện chuyển ca lên quản trị và thời hạn xử lý: **BR-86**; hiệu lực miễn trừ của quản trị so với chủ nhóm: **BR-110**; thứ tự khôi phục Coins/chuỗi: **BR-87, BR-88** (thống nhất với Q-37, Q-16).

## US-09.06 Xử lý báo cáo lạm dụng nhóm

**Là một** Quản trị, **tôi muốn** xem các báo cáo "nhóm lạm dụng" (dùng nhóm để giám sát không mong muốn) và ra quyết định cảnh báo, giải tán nhóm hoặc khóa chủ nhóm **để** giảm rủi ro R-P09 khi ai cũng tạo được nhóm (D-10).

- Ưu tiên: Should · Ước lượng: M · Nguồn: GĐ1 §6; D-10; R-P09; Q-63 · Liên quan: BR-62, BR-80, BR-109, máy trạng thái NHÓM, US-09.02, NFR-P07

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-09.06.1 | Bình thường | Có ca báo cáo lạm dụng nhóm (đầu vào: US-02.13 phía thành viên, BR-109) | Quản trị mở danh sách báo cáo | Thấy: tên nhóm, mục đích nhóm đã khai, số thành viên, ngày tạo, lý do báo cáo, số báo cáo đã gộp; **không** thấy dữ liệu phiên của từng thành viên; danh tính người báo cáo không bao giờ hiển thị cho chủ nhóm (BR-109) |
| AC-09.06.2 | Bình thường | Nhóm HOẠT ĐỘNG hoặc TẠM NGƯNG LỊCH (chủ nhóm bị khóa), không có phiên COUNTDOWN/ACTIVE; quản trị kết luận vi phạm | Chọn "Giải tán nhóm" kèm lý do | Nhóm → ĐÃ GIẢI TÁN (máy trạng thái NHÓM: HOẠT ĐỘNG → ĐÃ GIẢI TÁN hoặc TẠM NGƯNG LỊCH → ĐÃ GIẢI TÁN, T-BA-66); nếu từ HOẠT ĐỘNG thì phiên SCHEDULED → CANCELLED (TẠM NGƯNG LỊCH không còn phiên SCHEDULED); báo cáo theo BR-62; mọi thành viên và chủ nhóm nhận thông báo kèm lý do chung; ghi nhật ký quản trị (BR-80, BR-109) |
| AC-09.06.3 | Bình thường | Quản trị kết luận không vi phạm | Chọn "Bác" kèm lý do | Ca đóng; người báo cáo nhận kết quả; nhóm không bị ảnh hưởng, chủ nhóm không được báo (BR-109) |
| AC-09.06.4 | Lỗi | Nhóm ĐÃ GIẢI TÁN | Quản trị chọn "Giải tán nhóm" | Từ chối: "Nhóm đã giải tán" |
| AC-09.06.5 | Biên | Nhóm có phiên ACTIVE | Quản trị chọn "Giải tán nhóm" | Nhóm → CHỜ GIẢI TÁN; phiên chạy đến `ends_at`, không ai bị tính thoát/WITHDRAWN; ngay sau `ends_at` → ĐÃ GIẢI TÁN (BR-80, đề xuất Q-77) |
| AC-09.06.6 | Biên | `abuse_merge_h = 24` (BR-109); báo cáo đầu lúc T; hạn = T + 24 giờ (nửa mở, BR-65) | Báo cáo trùng cùng nhóm lúc `t = T + 24 giờ − 1 ms` / `t = T + 24 giờ` | `t = hạn − 1 ms`: gộp vào ca cũ; `t = hạn`: tạo ca mới (T-BA-67) |

**Ghi chú / giả định:** Đầu vào phía thành viên (gửi "Báo cáo nhóm"/báo cáo tên-avatar) là **US-02.13** (Should, T-BA-62). Hành động "cảnh báo chủ nhóm" là Could; "đặt lại tên-avatar mặc định" theo BR-109. Luồng báo cáo lạm dụng nhóm (ai được báo cáo, gộp, ẩn danh người báo cáo, các quyết định khả dĩ): **BR-109**; giải tán khi đang có phiên: **BR-80**.

## US-09.07 Xem nhật ký truy cập

**Là một** Quản trị, **tôi muốn** xem và lọc nhật ký truy cập (ai xem/xuất/thay đổi dữ liệu cá nhân của ai, khi nào, vì ca nào) **để** kiểm tra việc dùng quyền của chủ nhóm và quản trị đúng mục đích.

- Ưu tiên: Should · Ước lượng: M · Nguồn: GĐ1 §5 (minh bạch hai chiều), §6; NFR-P07; R-P05; Q-21, Q-22 · Liên quan: BR-73, NFR-11

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-09.07.1 | Bình thường | Có bản ghi truy cập | Quản trị lọc theo người truy cập / người bị truy cập / khoảng thời gian / loại hành động | Hiện danh sách: thời điểm, người truy cập (vai trò: chủ nhóm của nhóm X hoặc quản trị), người bị truy cập, hành động (xem/xuất/khóa/điều chỉnh Coins/mở ca), mã ca/lý do. Không hiện nội dung dữ liệu đã xem |
| AC-09.07.2 | Bình thường | Quản trị A vừa xem nhật ký truy cập | Bất kỳ | Bản thân hành động xem nhật ký truy cập cũng được ghi (đề xuất) |
| AC-09.07.3 | Lỗi | Bất kỳ | Gọi API sửa/xóa bản ghi truy cập | Không có chức năng; 403/405 — nhật ký truy cập chỉ-thêm (đề xuất) → **BR-73** |
| AC-09.07.4 | Lỗi | Token người dùng thường | Gọi API nhật ký truy cập toàn hệ thống | 403; người dùng chỉ xem bản ghi về chính mình qua "Dữ liệu của tôi" (EP-01, Q-21) |
| AC-09.07.5 | Biên | Khoảng lọc trả > 1.000 bản ghi | Tìm kiếm | Phân trang 50 bản ghi/trang; xuất CSV cũng sinh bản ghi truy cập (giả định) |

**Ghi chú / giả định:** Thời hạn lưu `access_log_retention_months = 12`, gộp lượt xem trong `access_log_merge_min = 10` phút: **BR-73** (đề xuất Q-121).

## US-09.08 Cấu hình thông số hệ thống

**Là một** Quản trị, **tôi muốn** xem và sửa các thông số có cột "Admin" trong `03-quy-tac.md` (ví dụ `coins_25`, `coins_50`, `coins_daily_cap`, `grace_s`, `countdown_s`) **để** tinh chỉnh luật chơi mà không cần phát hành lại.

- Ưu tiên: Could · Ước lượng: M · Nguồn: D-09 ("các số cấu hình được"); `01-pham-vi.md` EP-09 (cấu hình Coins); 03 bảng thông số · Liên quan: BR-02, BR-04, BR-11, BR-19, BR-74, BR-111, BR-112

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-09.08.1 | Bình thường | `coins_daily_cap = 100`; phiên P đang ACTIVE, `ends_at` sau lúc đổi | Quản trị đổi thành 120, nhập lý do, lưu | Tham số Coins áp cho mọi phiên có `ends_at` sau lúc đổi, kể cả P; trần ngày theo giá trị hiện hành 120 (BR-111); ghi nhật ký quản trị (ai, cũ, mới, lý do) |
| AC-09.08.2 | Bình thường | `grace_s = 3`; phiên Q đang ACTIVE | Quản trị đổi `grace_s` = 5 | Q giữ 3; phiên vào COUNTDOWN sau lúc đổi dùng 5 (BR-111) |
| AC-09.08.3 | Lỗi | Bất kỳ | Nhập giá trị sai kiểu hoặc ngoài miền (vd. `grace_s = -1`, `coins_daily_cap` < `coins_50`) | Không lưu; báo lỗi kèm miền hợp lệ (BR-111, BR-112) |
| AC-09.08.4 | Biên | Miền BR-112: `grace_s` 2–10, `countdown_s` 3–10 (gồm hai biên) | Lưu `grace_s` = 1 / 2 / 10 / 11 | 2 và 10: lưu được; 1 và 11: từ chối |
| AC-09.08.5 | Lỗi | Bất kỳ | Mở màn cấu hình hoặc gọi API sửa `duration`, `group_min_members`, `group_max_members`, `day_timezone`, `report_timezone`, `invite_code_len`, `notify_latency_s` | Không có trường sửa trên màn; API từ chối (400) — các tham số này cố định ở MVP theo BR-112 (BR-02, BR-74, BR-76, D-02) |
| AC-09.08.6 | Biên | Miền BR-112: `coins_daily_cap` 25–500 và ≥ `coins_50`; `coins_50 = 50` | Lưu `coins_daily_cap` = 24 / 25 / 49 / 50 / 500 / 501 | 50 và 500: lưu được; 24, 25, 49 (nhỏ hơn `coins_50`) và 501: từ chối kèm miền và ràng buộc (BR-112) |
| AC-09.08.7 | Lỗi | Tham số không có dòng trong bảng BR-112 (vd. `report_link_email_days` đã Hủy, D-24) | Gọi API sửa | 400 "Tham số không cấu hình được" (BR-112, T-BA-64) |
| AC-09.08.8 | Biên | Miền BR-112: `lock_dissolve_days` 7–90, `abuse_merge_h` 1–72 | Lưu 6 / 7 / 90 / 91 và 0 / 1 / 72 / 73 | 7, 90, 1, 72: lưu được; 6, 91, 0, 73: từ chối |

**Ghi chú / giả định:** MVP có thể chỉ seed thông số (Could). Miền giá trị và danh sách tham số cấu hình được: bảng BR-112 (đề xuất Q-122) — màn cấu hình chỉ hiện tham số có dòng trong bảng và không ghi "Cố định"/"Không cấu hình".

## Truy vết

| Story | Epic | Nguồn | BR / NFR | Q- | MoSCoW |
| --- | --- | --- | --- | --- | --- |
| US-09.01 | EP-09 | D-10; 04 §Cognito | NFR-11 | Q-116 | Should |
| US-09.02 | EP-09 | GĐ1 §3; A-33 | BR-09, BR-19, BR-114, BR-80, BR-108; máy trạng thái NHÓM; NFR-P07 | Q-117, Q-118 | Should |
| US-09.03 | EP-09 | GĐ1 §4.6; D-09 | BR-44, BR-93, BR-94, BR-96, BR-106 | Q-38, Q-98, Q-119 | Should |
| US-09.04 | EP-09 | D-09 | BR-44, BR-45, BR-53, BR-107; NFR-P07 | Q-120 | Should |
| US-09.05 | EP-09 | GĐ1 §3, §6, §10 #3; NFR-P14; A-17, A-20 | BR-34, BR-35, BR-37, BR-44, BR-54, BR-73, BR-86, BR-87, BR-88, BR-110; máy trạng thái KHIẾU NẠI; NFR-P05, NFR-P07 | Q-16, Q-22, Q-37, Q-91 | Should |
| US-09.06 | EP-09 | GĐ1 §6; D-10; R-P09 | BR-62, BR-65, BR-80, BR-109; máy trạng thái NHÓM (gồm TẠM NGƯNG LỊCH → ĐÃ GIẢI TÁN); NFR-P07; đầu vào US-02.13 | Q-63, Q-77 | Should |
| US-09.07 | EP-09 | GĐ1 §5, §6; NFR-P07; R-P05 | BR-73; NFR-11 | Q-21, Q-22, Q-121 | Should |
| US-09.08 | EP-09 | D-09; 01 EP-09; 03 bảng thông số | BR-02, BR-04, BR-11, BR-19, BR-74, BR-76, BR-111, BR-112; D-24 | Q-102, Q-122 | Could |

Sửa 2026-10-19 theo `review/lan-4.md` T-BA-125: US-09.02 BR-25 (Hủy, D-25) → BR-114.

## Q- liên quan (đã ghi sổ)

Đã cấp số chính thức trong `ba/02-so-quyet-dinh.md`, trạng thái `Chờ`. Q-91 gộp với câu EP-04 (hạn khiếu nại, người xử lý); Q-77 gộp với câu EP-02 (giải tán khi có phiên).

| Mã | Câu hỏi | Đề xuất | Epic |
| --- | --- | --- | --- |
| Q-116 | Tạo/thu hồi tài khoản quản trị thế nào? Có bắt buộc MFA? | Nhóm phát triển tạo trực tiếp trên Cognito; bật MFA cho nhóm "admin" | EP-09, EP-01 |
| Q-117 | Người bị khóa tài khoản giữa phiên: tính EXITED (kích hoạt D-05) hay không? | Không; coi như WITHDRAWN, người khác giữ thưởng (thống nhất Q-60) | EP-09, EP-03 |
| Q-118 | Khóa tài khoản chủ nhóm thì nhóm xử lý thế nào? | Nhóm tạm dừng lịch; báo thành viên; giải tán nếu khóa > 30 ngày | EP-09, EP-02 |
| Q-119 | Đổi giá vật phẩm khi người dùng đang mua? Mỗi vật phẩm mua 1 lần hay nhiều lần? | Dùng giá server, xác nhận lại nếu khác; vật phẩm trang trí mua 1 lần | EP-09, EP-06 |
| Q-120 | ADMIN_ADJUST có tính vào `coins_daily_cap` không? Ngưỡng tối đa mỗi lần? | Không tính trần; > 500 Coins cần xác nhận lần hai | EP-09, EP-06 |
| Q-91 | Khi nào khiếu nại chuyển lên quản trị? Thời hạn chủ nhóm phản hồi? Mở lại ca đã đóng? | Khi liên quan chủ nhóm, quá 72 giờ không phản hồi, hoặc nghi lỗi hệ thống; mở lại cần lý do + nhật ký | EP-09, EP-04 |
| Q-77 | Giải tán nhóm khi đang có phiên? Gộp báo cáo trùng? Ẩn danh người báo cáo? | Hiệu lực sau phiên hiện tại; gộp trong 24 giờ; luôn ẩn danh với chủ nhóm | EP-09, EP-02 |
| Q-121 | Thời hạn lưu nhật ký truy cập? | 12 tháng, sau đó xóa | EP-09, NFR riêng tư |
| Q-122 | Miền giá trị hợp lệ của từng thông số Admin? | BR-rules định nghĩa min/max cho mỗi thông số | EP-09 |
