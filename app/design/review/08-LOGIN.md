# Đợt 08 — đăng nhập thật

Ngày 24/10/2026. Phạm vi một view `/login`, chưa đăng nhập, dùng chung trước khi biết vai trò. Ưu tiên người dùng: bỏ login mock, chuẩn bị production. Người dùng chốt Cognito, chưa tạo cấu hình AWS.

## Nguồn, phân xử, sở hữu

- [Audit nguồn](08-LOGIN-AUDIT.md), [quyết định](08-LOGIN-DECISIONS.md), [kiểm tra độc lập](08-VERIFICATION.md).
- Nguồn chính `mockup/sign_in_login/code.html`, yêu cầu người dùng và hợp đồng Cognito; hashes trong audit/verifier.
- `/root/implementation_audit`: LoginScreen, tests và fixture regression. Onboarding giữ nguyên.
- `/root/design_reference`: audit, sau đó backend verifier/config/tests.
- `/root`: auth controller, API 401, socket refresh, template/setup và build.
- `/root/design_arbitration`: phân xử và kiểm cuối khác người triển khai; không sửa implementation.

## Diff và trạng thái

Form email/password thật, labels/autofill, hiện mật khẩu, submit bàn phím, lỗi an toàn, chống gửi lặp và kiểm mounted. Bỏ chọn seed/dev endpoint khỏi app. Thiếu cấu hình khóa submit, không giả đăng nhập thành công. Không thêm link đăng ký/reset không hoạt động.

Backend xác minh Cognito access JWT qua JWKS/RS256/issuer/client/expiry/token_use. Token chỉ trong bộ nhớ, refresh tự động; socket reconnect đọc token mới. HTTP401 của request cũ không được đăng xuất session mới. Helper dev chỉ trong test; dev backend vẫn có guard dev/test, không dùng production.

State matrix source/widget: thiếu config, invalid form, loading, mật khẩu sai, lỗi mạng, challenge không hỗ trợ, thành công, dispose, viewport320/text1.5/keyboard. Runtime AWS chưa có pool/tài khoản để xác minh.

## Kiểm thử và vòng kiểm lại

- Flutter toàn suite: **173 đạt, 1 integration bỏ qua**. Bao gồm login15, auth10, session15, local gaps16.
- Backend unit: **58 đạt**, trong đó auth19. Backend typecheck sạch theo owner.
- Verifier V08-01 trả lỗi response401 cũ; root sửa so sánh Authorization với session hiện tại; regression pass, verifier đóng source vòng2.
- Regression draft journal: fixture cũ đọc `dev_user`; thay auth giả tường minh trong test, kiểm giữ nháp qua tạo lại container đạt.
- Build/preview identity ghi ở mục bàn giao sau build. Kiểm thử source không thay kiểm hình ảnh.

## Ảnh và giới hạn

**CHƯA XÁC MINH HÌNH ẢNH.** Không có screenshot browser đúng build/trạng thái; truy cập UI trước đó bị chặn, không dùng công cụ khác để né. Chưa có ảnh trước/sau cùng viewport nên không kết luận khớp mockup.

CloudFormation và [hướng dẫn Cognito](../../docs/COGNITO-SETUP.md) chưa được triển khai. Cần kiểm AWS thật, đồng bộ profile email/name đáng tin cậy, chốt challenge/recovery/session và hạ tầng trước production. Không đổi dữ liệu thật để chụp ảnh.

Đợt tiếp: 05C kho đồ, 05D hồ sơ/thành tích, từng view riêng. Không coi login hoặc theme chung là toàn bộ flow đã hoàn thiện.

## Bàn giao build

- Web release thành công 24/10/2026, API local `http://127.0.0.1:3000`, chưa gắn Cognito IDs; trạng thái dự kiến là chưa cấu hình.
- Preview: `http://127.0.0.1:8080/_preview/d2581b6e510a/#/login`, HTTP200.
- `main.dart.js` SHA256 local và HTTP khớp: `962E059F6A20884BE0F23DC1A71DDD19075E21B24493B2A306CFE987521207BE`.
- Flutter analyze toàn app sạch. Build JavaScript đạt; dry-run Wasm còn cảnh báo dependency socket_io_common, font Cupertino chưa khai báo, cờ pwa-strategy deprecated. Không tuyên bố build Wasm/Android đã được kiểm.
- Backend health local không truy cập được lúc bàn giao; chưa khởi chạy backend Cognito khi thiếu cấu hình. Preview HTTP200 không chứng minh auth end-to-end.
