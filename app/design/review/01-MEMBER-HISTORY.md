# Đợt 01 — Lịch sử phiên thành viên

## Bản xem mới nhất sau bổ sung yêu cầu

- Ngày 22/10/2026: đã thêm badge mode/thời gian thật, tab Ngày/Tuần/Tháng, chọn ngày, banner thưởng hôm nay và truy vấn đủ trang trong kỳ. Các ghi chú bản đầu bên dưới là lịch sử, không mô tả giới hạn phân trang hiện tại.
- Release web thành công, HTTP `/fresh` 200 lúc `2026-10-22T15:41:58+07:00`, `X-Preview-Version=191b09fd1a99`.
- Xem: http://127.0.0.1:8080/_preview/191b09fd1a99/#/history . SHA256 JS: `91FF33CB0B96454A15219331C848EB995F793246FDF0C6EDED7AC69EF6875B8B`.
- 12 Flutter tests đạt, analyze 8 file sạch; backend typecheck sạch, 41 tests đạt. Backend live HTTP xác nhận thưởng theo ngày/cap và mode Squad từ dữ liệu thật; không sửa seed.
- Backend hiện chỉ có phiên nhóm: trả `SQUAD`. Renderer hỗ trợ `SOLO` khi contract xác nhận; chưa có engine học cá nhân trong đợt này. Không giả lịch sử Cá nhân trên dữ liệu thật.
- V05–V11 được verifier đóng mức source; V04 ảnh/runtime vẫn mở. Không suy nghiệm thu thị giác từ build hoặc HTTP.

Trạng thái: **ĐÃ SỬA MÃ / CHỜ VERIFIER / CHƯA XÁC MINH HÌNH ẢNH**.

## Phạm vi

- Route `/history`, vai trò thành viên.
- Nguồn: `mockup/n_10_l_ch_s_phi_n/code.html`, `app/design/design-system.html`.
- Mã: `app/lib/features/history/history_screen.dart`.
- Đọc `REFERENCE_AUDIT.md`, `IMPLEMENTATION_AUDIT.md`, D02/D06–D12 trong `DECISIONS.md`.
- Chưa giao quyền sửa token toàn app. Implementer và verifier phải là hai agent khác nhau; ghi tên khi bắt đầu.

## Các lô bắt buộc theo thứ tự

1. Chốt build và ảnh trước: 390×844; có dữ liệu, rỗng, tải, lỗi. Ghi hash nguồn, build, vai trò, thời điểm. Chưa có ảnh runtime hiện tại.
2. Xác minh phạm vi tuần/tháng: thống kê dùng `inRange`, danh sách dùng `page.items`. Chốt cùng một ý nghĩa kỳ lọc; kiểm dữ liệu qua ranh giới tuần/tháng, giới hạn 50 bản ghi và cursor. Không trình bày tổng toàn kỳ nếu API chỉ trả một phần.
3. Sửa riêng nền, card, typography, hàng lịch sử, bộ chọn kỳ theo phân xử. Giữ tên nhóm, giờ, thời lượng, trạng thái, thưởng đúng dữ liệu. Không thêm biểu đồ hoặc dữ liệu giả từ mockup.
4. Verifier đối chiếu trước/sau cùng viewport; kiểm 320×740, 768×1024, chữ lớn, tên dài, chọn kỳ và mở chi tiết. Findings chưa đóng thì trả implementer, không chuyển đợt 02.

## Tiêu chí đóng

- Bộ lọc và thống kê không gây hiểu nhầm phạm vi dữ liệu.
- Giữ phân biệt hoàn thành có/mất thưởng, EXITED, LOST, ABSENT, VOID.
- Mỗi khác biệt có quyết định giữ/sửa/thích nghi cùng lý do.
- Analyze/kiểm thử hành vi liên quan đạt; ảnh runtime đúng build được verifier kiểm độc lập.
- Chưa đạt tiêu chí ảnh thì hồ sơ vẫn mở, dù code đã sửa.

## Bằng chứng và vòng kiểm

Chưa có ảnh trước/sau hoặc xác nhận thị giác. Bổ sung bảng bằng chứng và vòng verifier theo `VIEW_TEMPLATE.md` khi triển khai. Không dùng URL preview đơn lẻ làm build identity.

## Đợt sửa 22/10/2026

Implementer: `/root/implementation_audit`. Phân xử nguồn: `/root/design_arbitration`; điều phối `/root` xác nhận giới hạn thời gian đến hiện tại. Verifier phải là agent khác. Quyền triển khai tiếp dù thiếu ảnh runtime do điều phối giao; cổng hình ảnh vẫn mở.

| ID | Quyết định / lý do | Mã đã sửa |
|---|---|---|
| H01 | Sửa: tuần/tháng áp dụng cả danh sách, thống kê và empty. Kỳ từ đầu tuần (thứ Hai) hoặc đầu tháng giờ VN đến `now`, gồm đúng mốc hiện tại; loại tương lai. Lịch sử không trình bày phiên tương lai. | `historyInPeriod`, một danh sách `inRange` chung. |
| H02 | Thích nghi: API mới trả trang đầu thì không bịa tổng toàn kỳ. Cursor có giá trị sẽ hiện cảnh báo phạm vi ngay trước thống kê; không hardcode số 50, không đổi API. | `historyPartialNotice`. Chưa thêm tải tiếp; đây vẫn là giới hạn công khai. |
| H03 | Sửa: sắp timestamp giảm dần, nhóm theo ngày đầy đủ năm giờ VN. Ngày null không thể gán vào kỳ nên loại khỏi kỳ hiện tại, không bịa ngày. | `historyDay`, nhóm `DateTime`; nhãn dùng `dayLabel` (đã gồm năm cho ngày cũ; không nối năm lặp). |
| H04 | Theo tham chiếu: xám `#F4F5F7`, card trắng không border, bỏ icon tròn đầu dòng, nhãn trạng thái riêng. | Palette token hiện có dùng local; `_HistoryRow`, `_HistoryStat`. Không sửa theme hoặc widget chung. |
| H05 | Theo N-10: selector thời gian đen khi chọn, trung tính khi không chọn; selected có semantic state và độ đậm chữ, vùng chạm tối thiểu 44px. Đây là bộ chọn kỳ riêng, không quyết định mọi filter/nút app phải đen. | `_PeriodSelector`. |
| H06 | Giữ: back, không thêm bottom nav; `/history` là màn ngoài shell. Giờ bắt đầu–kết thúc hiển thị lịch dự kiến như trước; Coins/state theo payload. | Route và quyền không thay. Giữ các nhãn COMPLETED mất/có thưởng, EXITED, LOST, ABSENT, VOID, WITHDRAWN. |

### Bằng chứng mã và kiểm thử

- Phạm vi file: `app/lib/features/history/history_screen.dart`, `app/test/history_design_test.dart`, hồ sơ này. Không thay token toàn app, result hoặc API.
- Nguồn SHA256 `mockup/n_10_l_ch_s_phi_n/code.html`: `B2D7BF5CEA404C0E0062D2D16444A5CA2538E2D3668B248D8E71FC097B34F953`.
- Thư viện SHA256 `app/design/design-system.html`: `11AD6BB9D68A6C7ABD34AEE9E7533FFD02A68F5E19B974E13A492751460D8C05`.
- Mã sau sửa SHA256 `history_screen.dart`: `9FDCDAE7EE1F123C131AFA591DB2682C5C167382796D8C7CBF943959B04E60CA`.
- `flutter test test/history_design_test.dart`: 6 kiểm thử đạt. Kiểm mốc đầu tuần/tháng UTC→VN, năm cũ, tương lai/null, thứ tự, không mutate input; widget đổi kỳ cùng dòng và thống kê, caption cursor, 320/390/768px, text scale 1.5; selected semantics; loading → error → retry → empty theo kỳ. Test lỗi tắt auto retry riêng ở fixture để kiểm đúng nút retry thủ công. Test hẹp ban đầu tìm dòng chưa được dựng ngoài viewport; đã sửa test cuộn tới dòng, không sửa tiêu chí.
- `flutter analyze lib/features/history/history_screen.dart test/history_design_test.dart`: không có issue.
- Widget test hỗ trợ hành vi/layout, **không thay thế ảnh browser runtime**. Các test widget dùng chiều cao 1024; chưa xác minh baseline 390×844 hoặc 320×740 trên trình duyệt.

### Còn mở cho verifier

- Chưa có ảnh before/reference/after đúng build; chưa kiểm thị giác font, shadow, gutter, focus và khoảng cách thực.
- Root build web sau checks; ghi `X-Preview-Version` và hash JS tại lần chụp, không suy build từ URL.
- Cần kiểm runtime loading/error/empty, tất cả nhãn trạng thái, tên dài, navigation tới đúng phiên/quay lại, chữ lớn và nhiều ngày. Chưa có bằng chứng cho các trạng thái này thì không ghi đạt.
- Chưa có tổng toàn kỳ khi cursor tồn tại, chưa tải thêm. Nhãn giới hạn đã có; không gọi tính năng này là thống kê đầy đủ.

### Vòng sửa theo verifier nguồn

- `/root/design_reference` phát hiện nhãn ngày lặp năm, typography thống kê lớn hơn nguồn, selector nền xám thay trắng.
- Đã sửa: bỏ suffix năm vì `dayLabel` đã xử lý ngày cũ; thống kê giá trị 22px, nhãn 12px; selector nền trắng theo N-10/D02. Mã khóa nhóm vẫn đầy đủ năm.
- Chạy lại `flutter test --no-pub test/history_design_test.dart`: 6/6 đạt; `flutter analyze --no-pub lib/features/history/history_screen.dart test/history_design_test.dart`: không issue.
- Đây là phản hồi nguồn/code đã sửa; chờ verifier xác nhận lại và ảnh runtime. Không coi là nghiệm thu thị giác.

### Bản web bàn giao

- Root chạy lại `flutter test --no-pub test/history_design_test.dart` sau patch cuối: 6/6 đạt. `git diff --check` file màn không có lỗi whitespace.
- Build release web thành công với `API_BASE_URL=http://localhost:3000`; build JavaScript có cảnh báo dry-run Wasm từ dependency socket và font Cupertino hiện hữu, không chặn build này.
- HTTP `/fresh` trả 200 lúc `2026-10-22T15:26:28+07:00`; `X-Preview-Version`: `9668f15ab76b`.
- SHA256 `main.dart.js`: `99CBD2BDB803F5329E43A4DE83D3AF968E3BCA0F95C0E33207197B12E88DD009`.
- URL xem: http://127.0.0.1:8080/_preview/9668f15ab76b/#/history . URL có thể phục vụ build mới ở lần sau; hash trên ghi bản tại thời điểm kiểm.
- Verifier đã đóng V01–V03 ở phạm vi source/docs, xem `01-VERIFICATION.md`. V04 ảnh/runtime vẫn mở; HTTP 200 không chứng minh giao diện đạt.

- Recheck typography cuối: giá trị thống kê dùng `headlineMedium` (22px/28px, w600), thay việc chỉ đặt fontSize trên headlineLarge còn giữ weight/line-height sai. Mã hash phía trên đã cập nhật. Root chạy lại targeted tests và build sau chỉnh này; không khẳng định kết quả test trước đó xác minh patch cuối.

## Bổ sung theo yêu cầu mới — Ngày, chế độ, thời gian thực, thưởng hôm nay

Trạng thái: **ĐÃ SỬA MÃ / 12 TESTS ĐẠT / CHƯA XÁC MINH HÌNH ẢNH**. Phần này thay các mô tả đợt cũ về selector chỉ tuần/tháng, trang đầu và thời gian kế hoạch. Bản web/hash cũ ở trên chỉ là lịch sử; root build lại sau patch này.

### Quyết định và checklist đã triển khai

| ID | Hành vi mới / căn cứ | Bằng chứng code/test |
|---|---|---|
| H07 | Tab Ngày/Tuần/Tháng dùng chung ngày được chọn. Kỳ ngày/tuần/tháng theo giờ VN, from inclusive/to exclusive; week bắt đầu thứ Hai. Không nhận ngày tương lai trong picker, lọc bỏ timestamp tương lai/null. | `HistoryPeriod`, `_rangeKey`, `historyInPeriod`; tests ranh giới UTC/VN và ngày cũ. |
| H08 | Chọn ngày thật qua date picker; style scoped trắng/xám, selected đen, bo24, touch target nền tảng. Yêu cầu mới có ưu tiên cao hơn N-10 cũ chưa có chọn ngày. | `_pickDate`; widget test đổi sang input, chọn ngày cũ, xác nhận query UTC và empty, không chỉ mở/hủy dialog. |
| H09 | Query API theo kỳ, tải hết các trang trong kỳ trước khi xuất thống kê. Không chỉ lọc50 phiên mới nhất. Backend/API/model/provider do root sở hữu; UI không tự bịa tổng. | `historyPeriodProvider` do root thêm; hai provider tests kiểm all-pages/bounds và cursor lặp. UI giữ cảnh báo nếu payload vẫn có cursor. |
| H10 | Badge `Squad` chỉ từ `session_mode=SQUAD`; `Cá nhân` chỉ từ explicit `SOLO`; unknown hiện `Chưa rõ chế độ`. Không suy theo participant count hoặc group_name. Backend hiện chỉ sinh SQUAD; SOLO trong widget test là fixture tương lai, không tuyên bố app có tính năng cá nhân. | `_HistoryRow`; fixture cả SQUAD/SOLO/null. |
| H11 | Badge thời gian tập trung thật từ focusSeconds, giữ giây lẻ. Kế hoạch25phút có nhãn riêng, không dùng làm thời gian rời. Rời sớm dùng exitedAt thật; thiếu thì ghi chưa có thời điểm. COMPLETED có endedAt hiện giờ hoàn thành. | `historyFocusDuration`; test focus14phút, kế hoạch25, actual exited/ended, LOST riêng. |
| H12 | Banner thưởng **hôm nay** độc lập kỳ đang chọn; summary toàn ledger theo ngày/cap thật từ root. Loading/error không hiện0 thay thế; lỗi có thử lại. | `_TodayRewardBanner`; test pending/error không có value, retry nhận12/100, đổi ngày cũ vẫn giữ40/100. |
| H13 | Controls+banner tồn tại khi history loading/error/data. Khi một kỳ lỗi vẫn có thể chọn kỳ khác; summary không mất vì trạng thái lịch sử. | `controls` trong cả ba nhánh; test summary+picker tồn tại ở loading/error. |
| H14 | Qua00hVN hoặc resume sau ngày mới: invalidate summary và kỳ hiện tại, cập nhật mặc định today, giữ ngày user đã chọn; dispose timer/observer. | `historyNextMidnight`, timer, WidgetsBindingObserver; unit UTC7 qua31/12→01/01. Chưa có runtime lifecycle hoặc test clock giả toàn flow. |

### Kiểm tra vòng cuối

- Implementer `/root/implementation_audit`; root sở hữu API/backend/model/provider/appeals. Verifier `/root/design_reference` phân xử/recheck nguồn độc lập.
- `flutter test --no-pub test/history_design_test.dart test/history_period_provider_test.dart`: **12/12 đạt** (10 design tests,2 provider tests).
- `flutter analyze --no-pub lib/core/api.dart lib/core/models.dart lib/core/models_ext.dart lib/core/providers.dart lib/features/appeals/appeal_screens.dart lib/features/history/history_screen.dart test/history_design_test.dart test/history_period_provider_test.dart`: **không issue**.
- `git diff --check` hai file history code/test: sạch.
- Mã cuối `history_screen.dart` SHA256: `B178E8070566D776E1A36D284DC8FB8402B43F07BA250A497791CE1DECF24DA2`.
- Responsive widget tests 320/390/768px, text scale1.5 tiếp tục đạt sau bổ sung banner/badges. Các bước test đã cuộn thật để nhấn control/dòng ngoài viewport; không tắt hit-test warning để che lỗi.
- Chưa có ảnh browser runtime mới, chưa kiểm focus thật, keyboard date picker trên thiết bị, resume/qua đêm thật hoặc route tap qua browser. Giữ gate ảnh độc lập mở; tests không được gọi là visual pass.
