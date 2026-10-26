# DropIt! — Design system dựa trên Stitch

Ngày: 22/10/2026. Trạng thái: đã áp dụng bước đầu cho tài khoản chỉ là chủ nhóm; phía thành viên chưa chuyển sang bộ này. HTML là thư viện tham chiếu.

Triển khai: `buildOwnerTheme()` kích hoạt khi `ownerOnlyProvider == true`, áp dụng toàn bộ route kể cả màn chi tiết ngoài tab. Canvas xám, primary đen, input/secondary viền xám, control theo theme; navigation chủ nhóm tối. Card nhóm không viền, inset trung tính. Header quản lý dùng cùng phân cấp; lịch phiên có icon và card bo lớn. Tài khoản đồng thời là thành viên dùng giao diện thành viên hiện hành; chưa đổi theme riêng theo từng nhóm.

## Nguồn và thứ tự ưu tiên

Project Stitch `2723223813529979616`. Tham chiếu chính: T-02 Danh sách nhóm `ef8748bdc11b4c0391735eb01a463747`, The Shop `f4e4f5f3b5ba4bde91664e19e7c3b2f7`, User Profile `973c5f1448634ef48a45a4ce7525a858`. Đối chiếu bản export tại `mockup/t_02_danh_s_ch_nh_m/code.html` và `mockup/dropit/DESIGN.md`.

Lấy token từ màn hình sáng, không lấy metadata dark của toàn project. Yêu cầu mới của người dùng và dữ liệu thật ưu tiên hơn copy, số liệu, tính năng cũ trong mockup. Khung avatar AI đã duyệt được giữ. Tài liệu này thay thế quyết định nền kem và outline card của lần refresh trước khi triển khai tiếp.

## Màu ngữ nghĩa

| Token | Mã | Dùng cho |
|---|---|---|
| canvas | #F4F5F7 | Nền màn, không dùng nền kem |
| card | #FFFFFF | Card nổi trên canvas |
| inset | #F8F9FA | Nội dung lồng trong card |
| ink | #111111 | Tiêu đề và nội dung chính |
| muted | #6C6C70 | Chữ phụ cần đọc; tránh #8E8E93 cho chữ nhỏ trên trắng |
| primary | #010102 | Nút chính theo Stitch |
| brand | #B02F00 | Nhấn thương hiệu, Coins, liên kết |
| brand-soft | #FFF1EC | Chip, badge, icon plate |
| decorative | #FF5722 | Trang trí; không dùng chữ nhỏ trên trắng |
| success | #1B7F3B | Đã hoàn thành |
| success-soft | #E8F9ED | Nền trạng thái thành công |
| danger | #BA1A1A | Lỗi và thao tác hủy/rời |
| danger-soft | #FFDAD6 | Nền lỗi |
| line | #E5E7EB | Input, nút phụ, divider; không phải viền card |
| focus | #B02F00 | Vòng focus 2px, offset 3px |

HTML cho chuyển giữa nút chính đen nguyên bản Stitch và biến thể cam thương hiệu (yêu cầu trước). Mặc định đen để đối chiếu chính xác; lựa chọn này chỉ đổi vai trò primary, không đổi nền/card. Việc dùng nút đen có chủ đích khác với để component chưa được thiết kế.

## Typography và layout

Inter local, đủ tiếng Việt. H1 28/36 700; H2 22/28 600; tiêu đề section 18/24 600; body 14/20 400; body lớn 16/24; caption 12/16; nhãn 12/16 600. Không dùng tất cả chữ in hoa hoặc letter-spacing rộng cho tiếng Việt.

Spacing 4, 8, 12, 16, 24, 32. Mobile gutter 16; tablet 24; desktop 40. Radius: input/nút 16; card thường 16; card lớn 32; inset 16; badge và filter pill. Màn mobile không có chiều rộng cố định. Tên nhóm dài xuống dòng; thao tác không tràn ở 320px; chữ phóng lớn vẫn cuộn được.

## Card

- Card thường: trắng, padding 16, radius 16, **border: none**, shadow `0 4px 20px -2px rgba(17,17,17,.05)`.
- Card nhóm: trắng, padding 16–20, radius 32. Header icon + tên + vai trò; inset tiến độ riêng nhóm; lịch phiên; hành động cuối. Không cộng tỷ lệ nhiều nhóm, không thêm avatar giả.
- Card inset: #F8F9FA, radius 16, không viền, không bóng.
- Card tương tác: cùng bề mặt, hover dịch lên tối đa 2px; focus ring chỉ xuất hiện lúc dùng bàn phím. Card đang chọn có badge/check, không thêm outline thường trực.
- Stat: chữ số 28/36, label 12/16; màu nhấn chỉ ở số/biểu tượng.

## Component và trạng thái

Nút chính 56px; compact/phụ 48px; vùng chạm tối thiểu 44px. Primary đen theo nguồn; brand là biến thể. Secondary nền trắng, viền line; tertiary nền trong, chữ brand; destructive đỏ, có xác nhận trước thao tác không thể đảo ngược. Disabled nền #E5E7EB, chữ muted, vô hiệu thao tác; loading giữ chiều rộng và chặn bấm lặp.

Filter: trắng khi thường; selected nền brand-soft, chữ brand, check và aria-pressed. Input cao ít nhất 52px, viền line; focus ring brand; error kèm thông điệp và icon. Checkbox/radio/switch dùng primary đã chọn; không chỉ dựa vào màu. Badge trạng thái dùng chữ + icon. Navigation nguyên bản: nền #1C1C1E, pill nổi, icon mặc định #A1A1A6, active #FF5722; không thêm khung ngoài. Active có label và aria-current.

Dialog nền trắng radius 32, overlay đen 35%, có tiêu đề, nút đóng, focus trap, Escape, trả focus. Toast dùng role=status; không chiếm focus. Empty state có một CTA và hướng dẫn ngắn. Skeleton dùng cùng hình học với nội dung, không nhấp nháy mạnh. Progress dùng dữ liệu thật; null là chưa có dữ liệu, không diễn giải thành 0%.

Icon production: Material Symbols Outlined theo Stitch, 20–24px, nét nhất quán; icon nút 20px. HTML dùng SVG nét 1.8, cùng lưới 24 để xem offline. Icon trang trí aria-hidden; nút chỉ icon phải có tên truy cập. Không dùng emoji làm icon hệ thống.

## Chuyển động

Hover 160ms ease-out, press scale .98 trong 100ms, dialog 220ms ease-out; progress 300ms. Chỉ animate opacity/transform khi có thể. Tôn trọng prefers-reduced-motion và MediaQuery.disableAnimations; tắt pulse/spin khi giảm chuyển động, nhưng vẫn hiện trạng thái chữ. Không loop shimmer trên toàn màn; animation mỹ phẩm dừng khi route không active.

## HTML mẫu và Flutter/shadcn

`design-system.html` có swatch sao chép mã màu, typography, card, nút và trạng thái, input, filter, checkbox/radio/switch, icon, navigation, dialog/toast và preview màn Nhóm. Dữ liệu là mẫu, không gọi API và không thay đổi tài khoản.

shadcn/ui là mã component React trên DOM/CSS, không chạy trực tiếp trong Flutter, kể cả Flutter Web. Giữ Flutter: ánh xạ CSS variables sang DT/ThemeExtension, component sang widget dùng chung. Nếu có website React riêng, dùng shadcn/ui làm nền hành vi/accessibility, thay token và style theo tài liệu này; không lấy style mặc định làm thiết kế. Không cần chuyển framework chỉ để đạt giao diện này.
