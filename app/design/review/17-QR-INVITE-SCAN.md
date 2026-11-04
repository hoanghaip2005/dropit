# 17 — Quét mã QR mời tham gia

Trạng thái: kiểm tra source độc lập đạt; **CHƯA XÁC MINH HÌNH ẢNH** và camera trên thiết bị thật.

## Phạm vi và nguồn

- Yêu cầu người dùng: thêm biểu tượng quét QR bên phải “Nhập mã nhóm” để quét mã và vào nhóm.
- Màn danh sách nhóm `GroupsScreen`; luồng thủ công `JoinScreen` (V-04); màn đồng ý `ConsentScreen` (V-05).
- QR hiện có tại màn mời được tạo bởi `groupInviteUrl(code)` với fragment `/consent/:code`.
- Đối chiếu nguồn/app và phân xử trước triển khai: thích nghi scanner theo nền tảng, giữ nhập mã thủ công; chỉ điều hướng đến consent, không tự gia nhập.

## Quyết định và hành vi

- D15: chấp nhận QR chứa mã 8 ký tự hợp lệ hoặc URL consent cùng origin với `API_BASE_URL`.
- Mã không hợp lệ hoặc URL ngoài/route khác bị từ chối; scanner không mở URL bên ngoài.
- Scanner chỉ điều hướng tới `/consent/:code`. Quy tắc đồng ý bắt buộc và API gia nhập hiện tại không thay đổi.
- Chỉ mở quyền camera sau thao tác bấm quét; lỗi quyền/thiết bị/trình duyệt có hướng nhập mã thủ công.
- Android khai báo CAMERA; iOS mô tả lý do sử dụng camera. Web cần context bảo mật như HTTPS hoặc localhost và trình duyệt có BarcodeDetector gốc; không tải scanner script/WASM từ CDN.
- D16: cho phép người dùng chọn ảnh từ thư viện. Native dùng `MobileScannerController.analyzeImage`; web dùng `zxing2` thuần Dart trên bytes cục bộ, không cần BarcodeDetector/CDN. Ảnh không upload/lưu và được thu tối đa 2048px khi chọn.

## Thay đổi và kiểm tra

- `group_screens.dart`: thêm nút quét cạnh nút nhập mã, vẫn giữ thao tác nhập tay.
- `invite_qr_scanner.dart`, `router.dart`: camera scanner, kiểm payload và điều hướng consent.
- `qr_image_decoder_stub.dart`, `qr_image_decoder_web.dart`: giải mã QR ảnh web bằng ZXing thuần Dart; hoạt động cả trong Chrome/Electron không có BarcodeDetector và không có request CDN.
- `image_picker` đã có trong ứng dụng; dùng cho lựa chọn ảnh, không yêu cầu metadata đầy đủ.
- `AndroidManifest.xml`, `Info.plist`: quyền/mô tả camera theo nền tảng.
- `invite_qr_scanner_test.dart`: mã, URL consent cùng origin, từ chối payload sai và URL khác.
- `groups_qr_entry_test.dart`: mở scanner route, giữ nhập tay, kiểm layout rộng 320px và 390px.
- `member_invite_test.dart`: kiểm hồi quy QR/link/copy trong màn mời.
- `mobile_scanner.analyzeImage` dùng cho ảnh chọn trên Android/iOS; web build kiểm tra nhánh BarcodeDetector. Chưa có ảnh QR mẫu/runtime để xác nhận giải mã đầu-cuối trên từng nền tảng.
- Kiểm tra độc lập phát hiện và đã đóng lỗi bỏ qua mã hợp lệ khi một capture có QR sai đứng trước; regression test xác nhận route lấy mã hợp lệ đầu tiên.
- Kiểm tra độc lập phần chọn ảnh từ thư viện: không có finding source; lần chạy Chrome/Electron thực tế xác nhận `isSecureContext=true`, `BarcodeDetector=undefined`, dẫn tới thông báo chưa chính xác “hãy thử Chrome”. Đã bỏ giả định API có sẵn và thay bằng ZXing thuần Dart; test QR pixels decode thành công.

## Kết quả kiểm tra

- `flutter test test/invite_qr_scanner_test.dart test/groups_qr_entry_test.dart test/member_invite_test.dart`: đạt; test tạo QR code từ encoder và giải mã payload từ pixel cục bộ.
- `flutter analyze` các file scanner, group UI và hai test QR: không có vấn đề.
- `flutter build web --debug --dart-define=API_BASE_URL=http://127.0.0.1:3000 --dart-define=ENABLE_LOCAL_DEV_AUTH=true`: đạt. Có cảnh báo dry-run WASM ở dependency hiện có `socket_io_common`; build web hoàn tất.
- Verifier source độc lập: finding multi-QR đã sửa; kiểm tra source trước đó không có finding ở picker. Chrome/Electron runtime xác nhận `BarcodeDetector` là `undefined`, giải thích thông báo lỗi trước đây; fallback ZXing đã test mã nguồn/pixels, chưa kiểm chọn file thật end-to-end.
- Ảnh app sau triển khai: chưa có. Không kết luận visual pass từ test hoặc build.

## Bằng chứng còn thiếu

- Ảnh app sau triển khai ở build hiện tại, route `/groups`, cả vai trò/viewport liên quan.
- Camera runtime trên Android/iOS thật và browser có quyền camera. Widget test/build không thay bằng chứng camera.
- Verifier chưa thể xác minh ảnh/tương tác camera do không có ảnh runtime phù hợp; giữ trạng thái **CHƯA XÁC MINH HÌNH ẢNH**.
