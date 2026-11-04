# 19 — Carousel quảng cáo mẫu trên Trang chủ

Trạng thái: triển khai xong; screenshot Home web desktop đã được kiểm tra độc lập; responsive mobile và native chưa xác minh.

## Phạm vi và nguồn

- View: Home thành viên hoặc Home có cả nhóm thành viên và nhóm đang quản lý.
- Vị trí: sau thẻ Coins hôm nay và trước thẻ chuỗi ngày.
- Yêu cầu người dùng đã xác nhận: 3 banner minh họa có nhãn rõ là nội dung mẫu; tự chuyển mỗi 5 giây; vuốt ngang và chọn chấm trang; chưa có chỉnh sửa/admin hoặc liên kết.
- Mockup tham chiếu: `mockup/employee_home/code.html` (SHA-256 `7B9E6956D5EB7DAA8582968C6406AF444C179E06D252F650C19A55E9F3BB211F`) có thứ tự Coins rồi chuỗi, không định nghĩa quảng cáo hay carousel.
- `mockup/employee_home_dashboard/code.html` (SHA-256 `EC6692AFC20555308B63C661766DFD4D4FC5EA1968933A62FC16559C8372D52C`) là biến thể lịch phiên, không có yêu cầu quảng cáo; không dùng làm căn cứ vị trí.
- Audit nguồn, audit app và phân xử: yêu cầu người dùng mới ưu tiên; đặt widget độc lập giữa Coins và chuỗi, không nằm trong card có tap Coins. Màn owner-only/empty không hiển thị summary này nên không có carousel.

## Quyết định và hành vi

- D18: chỉ hiển thị 3 câu minh họa, mỗi thẻ có nhãn “QUẢNG CÁO MẪU”; không có nhãn hàng, ưu đãi thật, CTA, hoặc điều hướng/link.
- Sau 5 giây chuyển ngang sang trang kế, trang cuối vòng về trang đầu.
- Người dùng vuốt ngang hoặc chọn chấm trang; thay đổi trang đặt lại bộ đếm.
- Tạm dừng tự chạy khi route Home không còn hiển thị hoặc ứng dụng không ở trạng thái resumed; khi quay lại bắt đầu lại bộ đếm 5 giây.
- Không gọi API, tải nội dung hay theo dõi người dùng. Việc gắn link và màn quản trị nằm ngoài phạm vi đợt.
- Màu nền dịu phân biệt 3 mẫu nhưng giữ typography và khoảng cách theo component hiện hành; không đổi theme dùng chung.

## Triển khai và kiểm tra

- `lib/features/home/home_screen.dart`: chèn carousel giữa card Coins và card chuỗi; chỉ trong summary hiện hữu.
- `lib/features/home/home_ad_carousel.dart`: 3 mẫu tĩnh; PageView, nút chấm có semantics, timer 5 giây, theo dõi lifecycle foreground và trạng thái route/TickerMode.
- `test/home_ad_carousel_test.dart`: đúng vị trí trong Home mixed-role fixture; kiểm tra đổi trang theo thời gian, vuốt, chấm trang, pause khi route bị che/app background, viewport 320px và text scale 2.
- `flutter test test/home_ad_carousel_test.dart`: 6 tests đạt.
- Regression `flutter test test/home_ad_carousel_test.dart test/registration_home_flow_test.dart`: 11 tests đạt.
- `flutter analyze lib/features/home/home_screen.dart lib/features/home/home_ad_carousel.dart test/home_ad_carousel_test.dart`: không có vấn đề.
- `flutter build web --debug --dart-define=API_BASE_URL=http://127.0.0.1:3000 --dart-define=ENABLE_LOCAL_DEV_AUTH=true`: đạt. Build có cảnh báo WASM từ dependency `socket_io_common`; không chặn build JavaScript.
- `git diff --check`: đạt.
- Build `app/build/web/main.dart.js` SHA-256: `461A5C41D1A4A602663FE954303C97CFDAF21959DED364CD329278BD9E7FF791`.
- Browser runtime: web build được phục vụ tại `http://127.0.0.1:8082/#/home`; API health HTTP 200. Xác nhận banner hiển thị sau Coins, trước chuỗi; browser quan sát được tự đổi trang và chấm trang bấm được. Swipe đã kiểm bằng widget test, chưa xác minh gesture trên trình duyệt desktop.
- Screenshot runtime lưu trong session evidence: `C:\Users\hau24\.copilot\session-state\3a083f48-dfba-45ee-a147-42f2893931d8\files\home-ad-carousel-runtime.png` (Home, local demo mixed role, desktop; ảnh PNG 1490×1079).
- Independent source verifier: không có finding đáng kể. Independent screenshot verifier xác nhận vị trí sau Coins/trước chuỗi, nhãn và nội dung dễ đọc, các chấm nằm gọn trong khung desktop. Ảnh tĩnh không chứng minh autoplay/swipe.

## Bằng chứng và giới hạn

- Ảnh người dùng cung cấp và ảnh browser trước thay đổi chỉ là baseline; không dùng làm ảnh sau sửa.
- Screenshot desktop trên build mới đã được verifier xem. Chưa có ảnh/screenshot 390×844 hoặc xác minh native; chưa kết luận responsive/native pass.
- Không kiểm tra nội dung Admin/link vì chưa được triển khai theo phạm vi.
