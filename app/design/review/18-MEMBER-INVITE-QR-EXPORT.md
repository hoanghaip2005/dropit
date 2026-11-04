# 18 — Tải ảnh QR mời thành viên

Trạng thái: đã triển khai; kiểm tra mã độc lập không có finding; **CHƯA XÁC MINH HÌNH ẢNH** và tải file runtime.

## Phạm vi và nguồn

- View: `InviteScreen`, cả vai trò chủ nhóm và thành viên.
- Yêu cầu người dùng: thêm nút tải ảnh QR trong phần “Mời thành viên”.
- Nguồn hành vi: D14 giữ riêng “Chép mã” và “Chép link nhóm”; D15–D16 giữ payload QR trỏ tới consent và luồng quét hiện có.
- Audit nguồn/app trước đây ghi nhận màn chưa có thao tác xuất QR. Chưa có mockup đã duyệt mô tả riêng chức năng tải ảnh; dùng secondary button hiện có và đặt ngay dưới QR, trước phần mã mời.

## Quyết định và hành vi

- D17: tạo PNG riêng từ đúng URL hiện tại của QR, không chụp ảnh toàn màn hình.
- Lưu bằng bộ hỗ trợ file của nền tảng, với tên `dropit-invite-qr.png`.
- Trong lúc lưu, khóa thao tác lặp và hiển thị loading. Native phân biệt lưu/hủy; web chỉ báo tải đã bắt đầu vì trình duyệt không xác nhận hoàn tất.
- Không đổi quyền mời, consent, mã/link clipboard hoặc quyền chỉ chủ nhóm được đổi mã.
- Lỗi lưu được ghi log và hiển thị thông báo; không báo thành công giả.

## Thay đổi và kiểm tra

- `lib/features/groups/group_screens.dart`: thêm nút và trạng thái loading trong thẻ QR; payload lấy từ `groupInviteUrl` đang hiển thị.
- `lib/features/groups/invite_qr_export.dart`: render PNG 1024×1024, nền trắng và QR đen; lưu qua `file_saver`.
- `test/member_invite_test.dart`: kiểm tra vị trí nút, URL được xuất, thông báo thành công/lỗi và quyền đổi mã theo vai trò.
- `test/invite_qr_export_test.dart`: kiểm tra chữ ký PNG và giải mã ảnh để xác nhận payload chính xác.
- Kiểm tra mục tiêu `flutter test test/member_invite_test.dart test/invite_qr_export_test.dart`: đạt, 6 tests.
- `flutter build web --debug --dart-define=API_BASE_URL=http://127.0.0.1:3000 --dart-define=ENABLE_LOCAL_DEV_AUTH=true`: đạt. Build có cảnh báo WASM từ dependency `socket_io_common` hiện có.
- `flutter analyze`: không có finding trong helper/export tests; còn một info lint ở `lib/app/router.dart:51` (`curly_braces_in_flow_control_structures`), ngoài thay đổi tải QR.
- Independent source verifier: không có finding mức cao trong PNG, URL, tên file, trạng thái web/native, lỗi/hủy hoặc hành vi chép/đổi mã; xác nhận chưa kiểm tra runtime.
- `git diff --check`: đạt sau cập nhật mã.

## Bằng chứng còn thiếu

- Chưa có screenshot app sau build mới, đúng route/role/viewport; không kết luận visual pass.
- Chưa xác minh tải file thực qua Chrome hoặc lưu native trên Android/iOS; widget test dùng callback giả để kiểm tra luồng UI.
- Chưa xác minh tải file thực qua Chrome hoặc lưu native; đánh giá hình ảnh vẫn mở tới khi có ảnh runtime.
