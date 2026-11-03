# 13 — Đăng ký vào trang chủ, tham gia nhóm tùy chọn

Ngày: 03/11/2026. Nhánh: `feature/registration-flow`.

## Phạm vi và nguồn

Yêu cầu hiện tại của người dùng thay thế ý định onboarding tạo/tham gia nhóm ở đợt 10. Hai view bị tác động: RegistrationScreen và trạng thái chưa có nhóm của HomeScreen. Giữ component/theme hiện có, màn nhập mã và đồng ý quy tắc hiện có. Không đổi quyền backend hoặc dữ liệu thật.

## Audit nguồn và phân xử

Agent `flow_review` đọc prompt reference reviewer/app auditor/design arbiter, kiểm mã và phân xử trước triển khai:

- SỬA: `_confirm` đang chuyển `/join` hoặc `/groups/new`; chuyển `/home` sau xác minh, đăng nhập và lưu hồ sơ thành công, kể cả đăng ký từ link mời.
- SỬA: bỏ lựa chọn tạo/tham gia nhóm khỏi form đăng ký vì không còn quyết định bước kế tiếp.
- THÍCH NGHI: Home rỗng dùng CTA “Tham gia nhóm”, giải thích có thể tham gia sau khi có mã.
- GIỮ: router không có guard bắt buộc membership; auth/restore đặt onboarded, owner-only vẫn về Groups; đăng nhập tài khoản hiện có vẫn giữ điều hướng invite chủ động.
- GIỮ: Home không dựng phiên học/thống kê nhóm khi chưa có membership; Groups có empty state. Join/Consent giữ validation, công tắc mặc định tắt và API consent.

## Kiểm chứng

Fixture tests dùng dữ liệu giả rõ ràng, không tạo tài khoản thật:

- Đăng ký chỉ gửi mã chưa tạo phiên; mã sai không đăng nhập (registration_screen_test).
- Xác minh thành công vào Home với/không có query invite; Home chưa có nhóm không tải upcoming.
- Authenticated state mở lại Home và chuyển từ login vẫn về Home khi chưa có nhóm.
- Home → Tham gia nhóm → nhập mã → quy tắc; consent ban đầu tắt, chưa gửi join; bật và đọc hết mới gọi consent, quay về Home.
- Kiểm thử hồi quy auth production, login, restore, invite hiện có.
- `flutter analyze`: không có vấn đề.
- Kết quả cuối: 58 tests đạt trong 7 file registration_screen, registration_home_flow, production_auth, member_invite, invite_duration_policy, session_restore, login_screen. Test mới có đăng nhập lại qua LoginScreen thực với auth API giả lập.
- `flutter build web --release`: thành công, artifact `app/build/web`. Có cảnh báo Wasm dry-run từ socket_io_common và font Cupertino; build JavaScript vẫn thành công.

Independent verifier: agent `flow_review`, khác agent triển khai, kiểm diff/source/tests/docs: không có finding chặn. Test consent dùng fixture membership rỗng cố định nên chỉ chứng minh gọi consent và trở về Home, không chứng minh membership mới từ backend thật. Logic invalidate membership giữ nguyên.

### Kiểm tra độc lập mã nguồn

`flow_review` đã đọc diff hai view, bốn test luồng mới và hồ sơ này: không thấy finding chặn trong phạm vi thay đổi. Test mở lại/login dùng authenticated state được inject; kiểm chứng refresh/login thực hiện riêng trong bộ hồi quy. Fixture consent ghi nhận API và điều hướng, nhưng giữ danh sách nhóm rỗng nên không chứng minh việc cập nhật membership từ backend thật. Cơ chế invalidate nhóm sau consent giữ nguyên. Kết luận này chỉ áp dụng mã nguồn và phạm vi test, không phải nghiệm thu hình ảnh hoặc email E2E.

## Giới hạn hình ảnh và môi trường

**CHƯA XÁC MINH HÌNH ẢNH**: chưa có ảnh runtime mới trên thiết bị/browser cho trạng thái đăng ký và Home; không tuyên bố khớp mockup. Test widget không thay E2E Cognito/email thật. Không triển khai production trong đợt này.
