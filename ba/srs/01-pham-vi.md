# SRS 01 — Phạm vi

Việc: T-BA-04 (L2). Nguồn: GĐ1 §0–§9, §11; D-01…D-29; `04-nfr-rieng-tu.md` §3; `ba/backlog.md`. Cập nhật sau review lần 1 (T-BA-26, T-BA-28, T-BA-31, T-BA-35, T-BA-43, T-BA-44, T-BA-49) và lần 2 (T-BA-59, T-BA-65; áp D-17…D-24), lần 3 (T-BA-76, T-BA-80; áp D-25, D-26), review mockup 2026-10-19 (`review/mockup-tong-hop.md` §3 S7, S8; T-BA-86, T-BA-105, T-BA-117; US-08.10 Must, US-03.14 Should; BR-115…BR-117; Q-143…Q-146). Các câu hỏi chưa chốt vẫn ghi **(giả định, Q-xx)** theo phương án đề xuất; chỗ đã chốt ghi mã D-.

## 1. Mục tiêu sản phẩm

DropIt! giúp văn phòng có **khung giờ tập trung chung**: bất kỳ người dùng nào cũng có thể tạo nhóm 4–10 thành viên (không gồm chủ nhóm, **giả định, Q-141**) và trở thành **chủ nhóm** (trong văn phòng, chủ nhóm thường là trưởng phòng), đặt lịch phiên; chủ nhóm chỉ quản lý, không tham gia phiên (D-25); trong phiên thành viên úp máy, ai rời app thì cả nhóm và mọi người trong phiên được báo ngay, kèm tên người thoát (D-20, D-22), và **cả phiên mất thưởng tập thể** (D-05). Thay áp lực “mất điểm cá nhân” bằng **trách nhiệm đồng đội, minh bạch hai chiều, thành tích và phần thưởng thẩm mỹ** (GĐ1 §1).

| Mã | Mục tiêu | Đo bằng (GĐ1 §11) |
| --- | --- | --- |
| G-01 | Giảm xao nhãng điện thoại trong giờ làm | Tỉ lệ phiên hoàn thành (cá nhân, D-11) và tỉ lệ phiên hoàn thành có thưởng (§8); số phiên/người/tuần |
| G-02 | Chủ nhóm có số liệu khách quan, ít phải nhắc | Thông báo thoát đến trong vài giây; báo cáo tháng tự động gửi email |
| G-03 | Ghi nhận tích cực, áp lực đồng đội vừa phải | Điểm danh, chuỗi, Coins, Shop hoạt động; khảo sát hài lòng |
| G-04 | Thành viên không thấy bị giám sát quá mức | Đồng ý rõ ràng, thành viên thấy đúng dữ liệu chủ nhóm thấy (NFR-P03) |
| G-05 | Đạt yêu cầu đồ án | Demo 1 chủ nhóm quản lý ≥2 nhóm (chủ nhóm không tham gia phiên nên không xung đột, D-25; mỗi thành viên ở 1 nhóm, D-21), chạy trên cả iOS và Android (D-07; iOS build qua CI, D-26); ≥3 dịch vụ AWS có vai trò thật |

## 2. Vai trò

Theo D-10, chỉ có **một vai trò hệ thống đặc quyền** là Quản trị. Vai trò Chủ nhóm / Thành viên **tính theo từng nhóm**, không do ai gán.

| Loại | Vai trò | Mô tả | Ghi chú |
| --- | --- | --- | --- |
| Hệ thống | **Người dùng** (ND) | Mọi tài khoản thường; có thể tạo nhóm hoặc tham gia nhóm | Là thành viên của tối đa 1 nhóm (D-21). Được tạo/quản lý nhiều nhóm với vai trò chủ nhóm (D-25); một thành viên nhóm A vẫn được tạo nhóm B và làm chủ nhóm B (giả định, Q-150 — D-25 chưa nêu rõ ý này) |
| Hệ thống | **Quản trị** (QT) | Quản lý tài khoản, danh mục Shop, cấu hình thông số, xử lý khiếu nại/lỗi | Không xem dữ liệu phiên chi tiết trừ khi xử lý ca, có ghi nhật ký **(giả định, Q-22)** |
| Trong nhóm | **Chủ nhóm** (CN) | Người tạo nhóm; quản lý thành viên, đặt lịch phiên, nhận thông báo, xem báo cáo nhóm | Mỗi nhóm đúng 1 CN (D-10). **Không tham gia phiên** của nhóm mình, không bị ghi dữ liệu phiên; không tính vào sĩ số 4–10 **(giả định, Q-141)** (D-25) |
| Trong nhóm | **Thành viên** (TV) | Người tham gia nhóm; vào phiên, nhận thành tích/Coins | Thuộc tối đa 1 nhóm tại một thời điểm (D-21). Muốn vào nhóm khác phải rời nhóm hiện tại |

Quyền CN chỉ áp dụng cho nhóm mình tạo. Các hành động cá nhân (hồ sơ, Shop, nhật ký, dữ liệu của tôi) thuộc mọi Người dùng, không phụ thuộc vai trò trong nhóm.

## 3. Bảng quyền

Ký hiệu: ✔ được · ✖ không · ~ một phần (ghi rõ). “Của mình” = dữ liệu về chính người đó; quyền CN giới hạn trong nhóm mình tạo và phiên của nhóm đó (04 §3). Cột ND áp dụng cho mọi người dùng (kể cả khi chưa ở nhóm nào).

| # | Hành động | CN | TV | ND (mọi người dùng) | QT | Nguồn |
| --- | --- | --- | --- | --- | --- | --- |
| A-01 | Đăng ký / đăng nhập / đăng xuất | — | — | ✔ | ✔ | GĐ1 §7 |
| A-02 | Sửa hồ sơ (tên, avatar, trang bị khung/hình nền) | — | — | ✔ của mình | ✖ | GĐ1 §4.7 |
| A-03 | Xem hồ sơ công khai của người cùng nhóm | ✔ | ✔ | ✖ ngoài nhóm | ✔ (+ email tài khoản) | 04 §3 |
| A-04 | Tạo nhóm (4–10 thành viên, không gồm CN — giả định, Q-141) → trở thành CN; được tạo nhiều nhóm (D-25) | — | — | ✔ | ✖ | D-02, D-10 |
| A-05 | Sửa / giải tán nhóm | ✔ | ✖ | — | ✖ | D-10 |
| A-06 | Khai mục đích sử dụng báo cáo khi tạo nhóm | ✔ (bắt buộc) | ✖ | — | ✖ | NFR-P09 **(giả định, Q-12)** |
| A-07 | Mời thành viên (mã / email), xóa thành viên khỏi nhóm | ✔ | ✖ | — | ✖ | GĐ1 §4.1 |
| A-08 | Đồng ý điều khoản minh bạch và vào nhóm | ✖ không cần với nhóm mình (không tham gia phiên, D-25) | ✖ khi đã là TV nhóm khác (D-21) | ✔ để trở thành TV, chỉ khi chưa là TV nhóm nào (D-21) | ✖ | NFR-P04; D-21 |
| A-09 | Rút đồng ý / rời nhóm | ✖ (chỉ giải tán, Q-34) | ✔ | — | ✖ | 04 §2 **(giả định, Q-20)** |
| A-10 | Đặt / sửa / hủy lịch phiên 25 hoặc 50 phút (một lần: US-02.10 Must; lặp lại: US-02.10b Should, BR-113) | ✔ | ✖ | — | ✖ | D-06; Q-78 |
| A-10b | Nhận nhắc trước giờ phiên (US-02.14, Should) | ✔ | ✔ | — | ✖ | BR-79; Q-80 |
| A-10c | Báo cáo nhóm / hồ sơ lạm dụng (US-02.13, Should); quản trị xử lý (US-09.06) | ✔ | ✔ | — | ✔ xử lý | BR-109; Q-63, Q-105 |
| A-11 | Mở phiên tự do cá nhân | — | — | ✔ (Should) | ✖ | **(giả định, Q-02 B — Should)** |
| A-12 | Tham gia phiên (đúng giờ / vào muộn ≤5 phút — vào muộn: Should) | ✖ (D-25) | ✔ | — | ✖ | D-25; **(giả định, Q-18)** |
| A-13 | Tạm dừng có lý do (1 lần, ≤5 phút, lý do chọn sẵn) | ✖ (D-25) | ✔ | — | ✖ | D-25; **(giả định, Q-11)** |
| A-14 | (Hủy — D-20: không có chế độ gộp ở MVP; luôn báo ngay) | — | — | — | — | D-20 |
| A-15 | Nhận thông báo **ngay** khi có người thoát | ✔ | ✔ (mọi TV của nhóm và mọi người trong phiên) | — | ✖ | GĐ1 §4.3, D-05, D-20. Mất kết nối / tạm dừng: chỉ CN thấy trong báo cáo, không push (D-19, D-20) |
| A-16 | Biết phiên đã mất thưởng tập thể **và tên người thoát** | ✔ | ✔ | — | ✖ | D-05, D-22 (thay NFR-P16, BR-38 bản cũ) |
| A-17 | Xem sự kiện thoát, thời điểm, lý do tạm dừng | ✔ | ✔ của mình | — | ~ chỉ khi xử lý khiếu nại/lỗi, có nhật ký (Q-22) | 04 §3 |
| A-18 | Viết / sửa giải trình cho sự kiện thoát (sửa trong 24h) | ✖ | ✔ của mình | — | ✖ | NFR-P10 **(giả định, Q-16)** |
| A-19 | Khiếu nại sự kiện thoát sai | ✖ | ✔ của mình | — | ✖ | NFR-P14 (đề xuất) |
| A-20 | Đánh dấu “miễn trừ” sự kiện bị khiếu nại | ✔ | ✖ | — | ✖ | NFR-P14 (đề xuất); Q-37 |
| A-21 | Xem điểm danh, chuỗi, huy hiệu | ~ chỉ điểm danh và kết quả phiên **trong nhóm mình**; **không thấy chuỗi** (chỉ số cấp người dùng, mọi nhóm); huy hiệu chỉ khi TV tự bật trên hồ sơ (A-03) | ✔ của mình | ✔ của mình | ~ số liệu tổng hợp | D-12, 04 §3 |
| A-22 | Xem số dư / lịch sử Coins | ✖ của TV (Q-23) | — | ✔ của mình | ~ khi xử lý lỗi | 04 §3 |
| A-23 | Mua và trang bị đồ Shop | — | — | ✔ của mình | ✖ | GĐ1 §4.6 |
| A-24 | Quản lý danh mục Shop (thêm/sửa/ẩn đồ, giá) | ✖ | ✖ | ✖ | ✔ | GĐ1 §3 |
| A-25 | Cấu hình thông số Coins (mức/phiên, trần/ngày) | ✖ | ✖ | ✖ | ✔ | D-09 |
| A-26 | Viết / sửa / xóa nhật ký | — | — | ✔ của mình | ✖ | GĐ1 §4.7 |
| A-27 | Đọc nhật ký của người khác | ✖ | ✖ | ✖ | ✖ | NFR-P05 |
| A-28 | Xem báo cáo tháng cá nhân | ✔ TV nhóm mình | ✔ của mình | — | ✖ | 04 §3 |
| A-29 | Xem báo cáo tháng tổng nhóm | ✔ | ~ chỉ khi nhóm ≥5 thành viên, không gồm CN (Q-24, BR-104) | — | ✖ | 04 §3 |
| A-30 | Nhận email tóm tắt báo cáo, không kèm PDF (Must); tải PDF trong app (Should) | ✔ | ✖ | — | ✖ | GĐ1 §4.8; D-24 |
| A-31 | Xem / xuất (JSON/CSV) / xóa dữ liệu của mình; xóa tài khoản | — | — | ✔ | ✖ | NFR-P11–P13 |
| A-32 | Xem nhật ký truy cập (ai đã xem/xuất dữ liệu mình) | — | — | ✔ của mình | ✔ toàn hệ thống | NFR-P07 **(giả định, Q-21)** |
| A-33 | Quản lý tài khoản (khóa/mở) | ✖ | ✖ | ✖ | ✔ | GĐ1 §3, D-10 |
| A-34 | Thấy số lần thoát / xếp hạng của TV khác | ~ chỉ TV nhóm mình, không xếp hạng công khai; danh sách sắp theo tên A→Z, không sắp theo chỉ số **(đề xuất, Q-143; BR-115)** | ✖ tổng số lần thoát; chỉ thấy tên người thoát từng phiên (A-16, D-22) | ✖ | ✖ | D-03, NFR-P06, D-22 |
| A-35 | Xem chi tiết một phiên **đã kết thúc** của nhóm (ai thoát, giờ server, giải trình, LOST/tạm dừng) — US-08.10, Must. **Chỉ đọc**: không xem trạng thái từng người theo thời gian thực khi phiên đang chạy, không có thao tác can thiệp (nhắc, rung, tạm dừng, dừng phiên) | ✔ nhóm mình, chỉ đọc **(đề xuất, Q-144; BR-116)** | ✖ (xem phiên của mình ở A-37) | — | ~ chỉ khi xử lý khiếu nại/lỗi, có nhật ký (Q-22) | D-22, D-25; BR-116; T-BA-105 |
| A-36 | Xem chỉ số từng nhóm ở màn danh sách nhóm | ✔ mỗi nhóm số riêng; không cộng gộp, không so sánh/xếp hạng nhóm **(đề xuất, Q-145; BR-117)** | — | — | ✖ | D-03; BR-117 |
| A-37 | Xem lịch sử phiên của tôi (US-03.14, Should) | ✖ của TV (dùng A-35) | — | ✔ của mình | ✖ | BR-119; T-BA-102 |

“—” = không áp dụng ở cột này (quyền nằm ở cột ND hoặc ngược lại). Không có hành động gán vai trò: CN do tạo nhóm mà có (D-10). CN không có hành động nào trong phiên (A-12, A-13, A-18, A-19 = ✖, D-25); A-15, A-16 của CN là nhận thông báo/kết quả với tư cách người quản lý. CN chỉ thấy dữ liệu phiên **sau** khi server xác nhận sự kiện, qua màn chỉ-đọc A-35; không can thiệp phiên (D-25, BR-116, Q-144).

## 4. Danh sách epic

| Epic | Mô tả | MoSCoW | Phiên bản | Lý do |
| --- | --- | --- | --- | --- |
| EP-01 Tài khoản & vai trò | Đăng nhập (Cognito), vai trò hệ thống ND/QT, vai trò trong nhóm CN/TV, đồng ý minh bạch, quyền dữ liệu cá nhân | Must | MVP | Nền cho phân quyền và riêng tư (GĐ1 §6, §7; D-10) |
| EP-02 Nhóm | Mọi ND tạo nhóm 4–10 thành viên (CN quản lý nhiều nhóm, không tham gia phiên — D-25), TV thuộc tối đa 1 nhóm (D-21); mời mã (email: Should); CN đặt lịch phiên một lần | Must | MVP | Cấu trúc cốt lõi (D-02, D-06, D-10, D-21) |
| EP-03 Phiên & Lockdown | Đếm ngược 5s, giao diện tối, khoan hồng 3s, phát hiện rời app trên **iOS và Android** (khóa màn hình không tính thoát), phiên tiếp tục khi có người thoát, mất kết nối (LOST không phạt cả phiên, D-19). Tạm dừng có lý do, vào muộn, sự cố server: Should | Must | MVP | Giá trị lõi; rủi ro kỹ thuật cao nhất, nhân đôi do 2 nền tảng (GĐ1 §10 #1; D-05, D-07, D-08) |
| EP-04 Thông báo thoát | Báo **ngay** (SNS) cho cả nhóm và mọi người trong phiên, kèm tên người thoát (D-20, D-22); giải trình. Khiếu nại: Should. Chế độ gộp cuối phiên: Won't (D-20) | Must | MVP | Tiêu chí demo “vài giây” (GĐ1 §11); giảm báo oan (§10 #3), quan trọng hơn vì D-05 phạt cả phiên |
| EP-05 Thành tích | Điểm danh, chuỗi ngày, huy hiệu mốc; ngắt chuỗi cả phiên khi có người thoát; chuỗi chỉ hiện cho chính người dùng (D-12) | Must | MVP | Thay cược bằng ghi nhận (GĐ1 §4.4, D-01, D-05) |
| EP-06 Coins & Shop | Quy đổi Coins 25’=10, 50’=25, trần 100/ngày; mất thưởng tập thể; mua khung avatar/hình nền | Must (cơ bản) | MVP; huy hiệu/danh hiệu bán trong Shop: sau | Động lực tích cực (GĐ1 §4.5–4.6; D-05, D-09) |
| EP-07 Hồ sơ & Nhật ký | Hồ sơ trang trí, nhật ký riêng tư đơn giản (viết + riêng tư, D-15) | Must (đơn giản) | MVP; sửa/xóa nhật ký: Should; chia sẻ nhật ký: sau | GĐ1 §7 MVP; D-15; Q-06 |
| EP-08 Báo cáo tháng | Chỉ số TV/nhóm, xem trong app, email tóm tắt không kèm PDF (SES, D-24); CN xem chi tiết phiên đã kết thúc, chỉ đọc (US-08.10); PDF tải trong app và so tháng trước là Should | Must (cơ bản) | MVP; PDF, xuất nâng cao: sau | Tiêu chí demo (GĐ1 §11); D-13, D-24 |
| EP-09 Quản trị | Tài khoản, danh mục Shop, xử lý khiếu nại/lỗi, báo cáo lạm dụng nhóm; giao diện cấu hình thông số là Could | Should | MVP tối thiểu (seed dữ liệu, đáp ứng C-09); giao diện admin đầy đủ: sau | Có thể thay bằng dữ liệu nạp sẵn khi demo; không còn việc gán vai trò (D-10) |
| EP-10 Xã hội | Kết bạn, bảng tin bài viết, báo cáo vi phạm, kiểm duyệt | Could → Won't ở MVP | Sau | GĐ1 §7, §10 #4; **(giả định, Q-05)** |

## 5. Tính năng con theo MoSCoW

### Must (MVP)

| Epic | Tính năng |
| --- | --- |
| EP-01 | Đăng nhập/đăng xuất; vai trò hệ thống ND/QT, vai trò CN/TV theo nhóm (D-10); màn đồng ý minh bạch (không ô đánh dấu sẵn); rút đồng ý và rời nhóm; “Dữ liệu của tôi” (xem); sửa hồ sơ cơ bản (US-01.03, D-17) |
| EP-02 | ND tạo nhóm 4–10 người, trở thành CN; TV thuộc tối đa 1 nhóm (D-21); mời bằng mã nhóm; xem nhóm và thành viên; xóa TV; khai mục đích báo cáo; CN đặt lịch phiên **một lần** 25/50’ (D-06), sửa/hủy lịch |
| EP-03 | Vào phiên theo lịch; đếm ngược 5s; giao diện tối tĩnh; chỉ báo “Phiên đang được ghi”; phát hiện rời app trên iOS và Android bằng Flutter (D-07); khoan hồng 3s (1 lần/phiên, Q-10); cho tắt màn hình, khóa màn hình không tính thoát (D-08); khi 1 người thoát, phiên vẫn chạy đến hết giờ cho mọi người (D-05); báo mọi người phiên mất thưởng, kèm tên người thoát (D-22); mất kết nối ghi riêng, không phạt cả phiên (D-19); kết thúc phiên, xem kết quả |
| EP-04 | Push **ngay** cho cả nhóm và mọi người trong phiên khi có người thoát (D-20); TV giải trình, CN xem giải trình (Q-16) |
| EP-05 | Ghi điểm danh ngày; chuỗi theo ngày có lịch nhóm (Q-17), xem chuỗi của mình; huy hiệu mốc; ngắt chuỗi mọi TV trong phiên có người thoát (D-05) |
| EP-06 | Cộng Coins khi **hoàn thành có thưởng** (25’=10, 50’=25, trần 100/ngày/người, cấu hình được — D-09, D-11); mất thưởng tập thể khi có người thoát (D-05); xem số dư/lịch sử Coins (D-17); Shop khung avatar + hình nền; mua, trang bị |
| EP-07 | Xem hồ sơ của mình; hồ sơ hiển thị khung, hình nền (US-07.04, D-17); nhật ký riêng tư: viết; chủ nhóm, thành viên khác và quản trị không xem được trong app (nội dung mã hóa phía server; người vận hành hạ tầng về kỹ thuật vẫn có thể giải mã — BR-100, NFR-P05) (D-15) |
| EP-08 | Báo cáo tháng tự động (EventBridge + Lambda): chỉ số mỗi TV và mỗi nhóm; CN xem báo cáo, TV xem dòng của mình; gửi email **tóm tắt** cho CN, không kèm PDF (SES, D-24); thông báo mục đích sử dụng; **CN xem chi tiết phiên đã kết thúc, chỉ đọc** — lối vào chính cho dữ liệu phiên của CN (US-08.10, T-BA-105; BR-116; Q-144, Q-146) |

### Should

| Epic | Tính năng |
| --- | --- |
| EP-02/03 | Phiên tự do cá nhân, tính Coins, không báo ai (Q-02 B — D-06 chỉ chốt phiên nhóm theo lịch CN). **Chưa có story** (T-BA-44) |
| EP-02 | Lịch lặp lại theo ngày trong tuần, bắt buộc ngày kết thúc, tối đa 12 tuần (US-02.10b; BR-113; Q-78) — **ngoài nguồn GĐ1**; tách khỏi US-02.10 (T-BA-43) |
| EP-02 | Nhắc thành viên trước giờ phiên (US-02.14; BR-79; Q-80) |
| EP-02 | Sửa thông tin nhóm; mời bằng email; giải tán nhóm; CN đổi điều khoản → TV đồng ý lại (D-13) |
| EP-02/09 | TV báo cáo lạm dụng nhóm / tên–avatar, quản trị xử lý (Q-63, Q-105). Phía TV: US-02.13; phía quản trị: US-09.06 |
| EP-03 | Vào muộn ≤5 phút, Coins theo tỉ lệ; ghi “vắng” tách khỏi “thoát” (Q-18, D-13) |
| EP-03 | Tạm dừng có lý do (Q-11, D-13); phiên hủy do sự cố server + thông báo hủy (Q-14, D-13) |
| EP-03 | Lịch sử phiên của tôi — chỉ phiên của chính mình (US-03.14, **giả định** Should; BR-119; mockup S10, T-BA-102) |
| EP-04 | Khiếu nại + CN miễn trừ, khôi phục thưởng tập thể nếu miễn trừ (NFR-P14, Q-37) |
| EP-01 | Xuất dữ liệu cá nhân JSON/CSV; xóa tài khoản; nhật ký truy cập (Q-21) |
| EP-05 | Xem lịch điểm danh của mình; bộ sưu tập huy hiệu và chọn hiển thị trên hồ sơ (US-05.06; US-07.05 hủy — gộp vào US-05.06, D-16); thông báo ngắt chuỗi; lịch sử thành tích; CN xem điểm danh TV trong nhóm mình — không gồm chuỗi (D-12, D-13) |
| EP-07 | Đổi ảnh avatar; xem hồ sơ công khai người cùng nhóm (D-13); xem lại/sửa, xóa nhật ký (D-15) |
| EP-08 | Tải PDF trong app (D-24); so sánh với tháng trước; báo cáo tổng nhóm cho TV khi nhóm ≥5 thành viên (Q-24); báo cáo kỳ không có dữ liệu (D-13) |
| EP-09 | Giao diện quản trị: đăng nhập, tài khoản, danh mục Shop, điều chỉnh Coins, khiếu nại chuyển lên, lạm dụng nhóm, nhật ký truy cập |

### Could

| Epic | Tính năng |
| --- | --- |
| EP-09 | Giao diện cấu hình thông số hệ thống (US-09.08). MVP cấu hình bằng dữ liệu nạp sẵn (T-05) nên vẫn đáp ứng C-09 |
| EP-06 | Huy hiệu, danh hiệu bán trong Shop (Q-38) |
| EP-08 | Xuất thêm Excel; xuất nâng cao (Q-36) |
| EP-07 | Chia sẻ nhật ký với bạn bè (cần EP-10, Q-06) |
| EP-05 | Huy hiệu nhóm khi 100% hoàn thành phiên |
| EP-03 | Khoan hồng theo thời lượng (25’=1, 50’=2) nếu phỏng vấn cho thấy phạt oan (Q-10 C) |
| EP-02 | Chuyển giao quyền chủ nhóm cho TV khác (Q-34) |

### Won't (bản này)

| Tính năng | Lý do |
| --- | --- |
| Kết bạn, bảng tin bài viết, kiểm duyệt bài | GĐ1 §7 giai đoạn sau; Q-05 |
| Nhiều văn phòng / công ty; nhiều CN mỗi nhóm | GĐ1 §7; D-10; Q-04 |
| Chế độ gộp thông báo cuối phiên (US-04.03, US-04.04) | D-20: luôn báo ngay; sau MVP |
| Một TV thuộc nhiều nhóm; cảnh báo trùng lịch giữa nhiều nhóm (US-02.12 Hủy) | D-21 |
| CN tham gia phiên của nhóm mình (US-03.13 Hủy) | D-25 |
| Tự miễn trừ khi có cuộc gọi | Chạm ràng buộc riêng tư; Q-15 |
| Xếp hạng nhóm hoặc xếp hạng tự nguyện | GĐ1 §9 hoãn |

## 6. Ngoài phạm vi (không làm ở bất kỳ phiên bản nào)

| Hạng mục | Nguồn |
| --- | --- |
| Cược điểm hoặc tiền trong phiên | D-01, GĐ1 §7, §9 |
| Nạp Coins / cược bằng tiền thật | D-03, GĐ1 §9 |
| Theo dõi nội dung điện thoại, app đang dùng, màn hình | D-03, GĐ1 §6, §9 |
| Đọc / đồng bộ danh bạ máy, thư mục nhân sự công ty, mạng nội bộ, tài khoản Google Workspace, Slack hay nguồn ngoài app khác để tìm/gợi ý đồng nghiệp. Chỉ mời bằng mã nhóm (email: Should) do người dùng nhập | GĐ1 §6; D-03; T-BA-117 (mockup S7) |
| Chủ nhóm theo dõi trạng thái từng người theo thời gian thực hoặc can thiệp phiên (nhắc, rung, tạm dừng, dừng hộ) | GĐ1 §6; D-25; BR-116 **(đề xuất, Q-144)** |
| Cộng gộp / so sánh / xếp hạng chỉ số giữa các nhóm | D-03; BR-117 **(đề xuất, Q-145)** |
| Cơ chế ngẫu nhiên trong Shop (hộp bí ẩn, quay thưởng, gacha) | D-01; BR-121 |
| Ghi dữ liệu ngoài thời gian phiên | GĐ1 §6, NFR-P02 |
| Xếp hạng công khai từng cá nhân | D-03, GĐ1 §9 |
| Dừng/hủy phiên của cả nhóm khi 1 người thoát (“nổ phòng”). Lưu ý: D-05 **có** phạt tập thể (mất Coins + ngắt chuỗi) nhưng phiên vẫn chạy — khác với GĐ1 §9, D-05 thay thế | D-05, GĐ1 §9 |
| Vai trò hệ thống “Trưởng phòng” / quản trị gán quyền quản lý nhóm | D-10 |
| Bán lợi thế bằng Coins (chỉ đồ thẩm mỹ) | GĐ1 §4.6 |
| Bảng tin công khai toàn công ty | GĐ1 §9 |
| Host/Guest, phòng 2–6 người (mô hình đặc tả 1.0 — nguồn cũ đã xóa) | CLAUDE.md, GĐ1 §0 |

## 7. Ràng buộc

| Mã | Ràng buộc | Nguồn |
| --- | --- | --- |
| C-01 | Nhóm Bá Khí 5 người, ~4 sprint; hạn nộp cần hỏi giảng viên | GĐ1 §8; D-07 |
| C-02 | **Bắt buộc ≥3 dịch vụ AWS**, mỗi dịch vụ có vai trò thật (dự kiến: EC2+ALB, RDS PostgreSQL, ElastiCache, Cognito, SNS, SES, EventBridge+Lambda, S3+CloudFront, DynamoDB, CloudWatch, Secrets Manager, Route 53, ACM) | GĐ1 §8; D-04 |
| C-03 | Ứng dụng di động viết bằng **Flutter**, chạy **cả iOS và Android** (một mã nguồn). Phát hiện rời app/khóa màn hình cần mã riêng từng nền tảng. Nhóm có tài khoản Apple Developer nhưng **không có máy Mac**: build/ký IPA và đẩy TestFlight chỉ qua **GitHub Actions runner macOS** (T-06); không debug iOS trực tiếp trên máy, mỗi lần thử iOS phải qua một vòng build CI | D-07, D-18, D-26 |
| C-04 | Thử nghiệm trên máy thật **cả iOS và Android**; phụ thuộc hành vi hệ điều hành — spike phát hiện thoát (phân biệt khóa màn hình vs rời app, D-08) ở Sprint 1–2. Phần iOS cần **≥1 iPhone thật**, cài qua TestFlight **(giả định, Q-142)** | GĐ1 §8, §10 #1; D-07, D-08, D-26 |
| C-10 | Phút chạy runner macOS GitHub Actions có hạn mức/chi phí; build iOS chỉ chạy khi cần (nhánh chính, thẻ phát hành, chạy tay) **(giả định)** | D-26 |
| C-05 | Hạn mức và cảnh báo ngân sách AWS từ ngày đầu | GĐ1 §8 |
| C-06 | Riêng tư là ràng buộc cứng: không đọc nội dung máy, không ghi ngoài phiên | GĐ1 §6; CLAUDE.md |
| C-07 | CSDL lõi PostgreSQL (RDS); log/nội dung xã hội DynamoDB | D-04 |
| C-08 | Chưa có kết luận pháp lý về dữ liệu cá nhân VN — cần tham vấn chuyên môn trước khi dùng thật | GĐ1 §6; 04 §6 |
| C-09 | Thông số Coins (mức/phiên, trần/ngày) phải cấu hình được, không mã cứng | D-09 |

## 8. Thuật ngữ

| Thuật ngữ | Định nghĩa |
| --- | --- |
| Người dùng | Mọi tài khoản thường; vai trò hệ thống mặc định (D-10) |
| Quản trị | Vai trò hệ thống duy nhất có đặc quyền (D-10) |
| Chủ nhóm | Người dùng đã tạo nhóm; mỗi nhóm đúng 1 chủ nhóm; có thể là chủ nhóm của nhiều nhóm. Chỉ quản lý (tạo nhóm, đặt lịch, nhận thông báo, xem báo cáo), **không tham gia phiên** (D-25). Trong văn phòng thường là trưởng phòng, nhưng hệ thống không có vai trò “trưởng phòng” (D-10) |
| Thành viên | Người dùng đã đồng ý và tham gia một nhóm; tối đa 1 nhóm (D-10, D-21). Chỉ thành viên mới tham gia phiên (D-25) |
| Trưởng phòng | Người thật ngoài đời (đối tượng phỏng vấn), không phải vai trò trong hệ thống; trong app dùng vai trò chủ nhóm (D-10) |
| Văn phòng | Đơn vị chứa các nhóm; MVP chỉ 1 văn phòng (GĐ1 §7) |
| Nhóm | Tập 4–10 thành viên (không gồm chủ nhóm — giả định, Q-141) do một chủ nhóm tạo và quản lý (D-02, D-10, D-25) |
| Phiên (phiên tập trung) | Khoảng 25 hoặc 50 phút nhóm cùng úp máy; bắt đầu theo lịch chủ nhóm đặt (D-06) |
| Phiên tự do | Phiên cá nhân ngoài lịch, tính Coins, không báo ai (Should, Q-02) |
| Lockdown | Trạng thái phiên đang chạy: giao diện tối tĩnh, theo dõi rời app |
| Đếm ngược | 5 giây trước phiên để úp máy; chưa ghi sự kiện |
| Khoan hồng | 3 giây cho phép quay lại sau khi rời app mà không bị tính thoát; 1 lần/phiên (Q-10) |
| Thoát | Rời app quá thời gian khoan hồng trong phiên (khóa/tắt màn hình không tính, D-08); báo ngay cả nhóm và người trong phiên, kèm tên (D-20, D-22), và gây **mất thưởng tập thể** (D-05) |
| Mất thưởng tập thể | Khi có ≥1 người thoát, phiên vẫn chạy đến hết giờ nhưng **mọi thành viên** trong phiên không nhận Coins của phiên và bị ngắt chuỗi (D-05) |
| Mất kết nối | Server không nhận heartbeat trong `heartbeat_timeout_s` (10 giây) → DISCONNECTED, ghi mốc `disconnected_at` (BR-66). Không kết nối lại trước `disconnected_at` + `disconnect_hold_s` (10 giây) → LOST (BR-19). Mốc gốc cho AC/NFR là `disconnected_at`. Ghi sự kiện riêng, không báo như thoát; LOST không gây mất thưởng tập thể, chỉ người đó không nhận Coins (D-19) |
| Tạm dừng có lý do | Dừng phiên tối đa 1 lần ≤5 phút với lý do chọn sẵn; chủ nhóm thấy lý do, không mất Coins, không cộng phút (Q-11) |
| Giải trình | Ghi chú của thành viên kèm một sự kiện thoát; chủ nhóm thấy kèm sự kiện; không hoàn Coins (Q-16) |
| Khiếu nại / Miễn trừ | Thành viên báo sự kiện thoát bị phát hiện nhầm; chủ nhóm đánh dấu miễn trừ → không tính thoát (NFR-P14, Q-37) |
| Vắng | Không tham gia phiên theo lịch; không tính thoát, không báo (Q-18) |
| Hoàn thành phiên (cá nhân) | Hết thời lượng phiên mà **bản thân** không thoát — trạng thái cuối COMPLETED, **kể cả khi phiên bị mất thưởng tập thể** (D-11, BR-23) |
| Hoàn thành có thưởng | Hoàn thành phiên (cá nhân) **và** phiên không bị mất thưởng tập thể (không `forfeited`) (D-11) |
| Điểm danh | Ngày có ≥1 phiên hoàn thành (cá nhân) (D-11, BR-46; Q-17) |
| Chuỗi | Số ngày có lịch nhóm liên tiếp đều điểm danh; ngày không có lịch không ngắt (Q-17); bị ngắt khi bản thân thoát hoặc ở phiên mất thưởng tập thể (D-05). Chỉ số cấp người dùng, chỉ hiện cho chính người đó (và hồ sơ nếu tự bật); chủ nhóm không thấy (D-12) |
| Huy hiệu | Thành tích theo mốc chuỗi, số phiên hoàn thành có thưởng, tổng giờ tập trung (BR-52); không dùng để tiêu |
| Coins | Điểm thưởng khi hoàn thành có thưởng (D-11; 25’=10, 50’=25, trần 100/ngày/người, cấu hình được — D-09); chỉ mua đồ thẩm mỹ |
| Shop | Danh mục đồ thẩm mỹ (khung avatar, hình nền; sau: huy hiệu, danh hiệu) |
| Hồ sơ | Trang cá nhân hiển thị khung, hình nền, thành tích công khai |
| Nhật ký | Ghi chép hằng ngày, riêng tư; chủ nhóm/quản trị không xem được trong app (BR-100, NFR-P05) |
| Đồng ý minh bạch | Xác nhận của thành viên trước khi vào nhóm về dữ liệu được ghi, ai thấy (kể cả tên người thoát hiện cho cả nhóm, D-22), và quy tắc mất thưởng tập thể (04 §2, D-05) |
| Báo cáo tháng | Tổng hợp chỉ số thành viên và nhóm, tạo tự động, gửi email tóm tắt cho chủ nhóm (D-24) |
| Nhật ký truy cập | Bản ghi mỗi lần chủ nhóm/quản trị xem hoặc xuất dữ liệu cá nhân của thành viên (NFR-P07) |
| Chi tiết phiên | Màn chỉ đọc của chủ nhóm cho một phiên đã kết thúc của nhóm mình (US-08.10, BR-116) |
| Lịch sử phiên của tôi | Danh sách phiên của chính người dùng (US-03.14, Should, BR-119) |

### 8.1 Tên hiển thị trên giao diện (T-BA-86, mockup S8)

Giao diện và tài liệu cho người dùng chỉ dùng cột "Tên UI". Từ ở cột "Cấm dùng" không được xuất hiện trên màn, thông báo, email, dữ liệu mẫu. Kiểm tra: rà chuỗi hiển thị không chứa từ cấm.

| Thuật ngữ | Tên UI | Cấm dùng |
| --- | --- | --- |
| Ứng dụng | DropIt! | FocusLoop, SquadFocus, tên thương hiệu khác |
| Coins | Coins | Xu, pts, điểm, XP, EXP, Drops, FocusCoins, Focus Coins |
| Nhóm | nhóm | squad, room, phòng, văn phòng |
| Chủ nhóm | chủ nhóm | Trưởng phòng, Lead, Manager, Host, Công ty |
| Thành viên | thành viên | Guest |
| Quản trị | quản trị | Phân quyền (tên phân hệ) |
| Phiên | phiên | sprint, room |
| Thành tích | điểm danh, chuỗi, huy hiệu | Hạng, Level, high score, độ kỷ luật, Drop Score, Session Efficiency, điểm chuyên cần/uy tín, Leaderboard |
| (không có trong sản phẩm) | — | cược, STAKE, pool, bounty, multiplier, "at risk", Mystery Box |
