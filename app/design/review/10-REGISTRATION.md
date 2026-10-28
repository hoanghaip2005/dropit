# 10 — Đăng ký và xác minh email

28/10/2026. Phạm vi `/register` (hai bước) và CTA `/login`; không đổi theme toàn app.

## Nguồn và quyết định

- Người dùng yêu cầu đăng ký cả chủ nhóm học và thành viên; xác nhận “chủ tiệm” nghĩa chủ nhóm.
- Reference/app audit + arbitration: agent signup_design. Nguồn `mockup/sign_in_login/code.html`, SHA256 `624119C4D4797A4C5B0EB53F13523EA1E1802B0955D5888E5551188480F6C36F`; chỉ có liên kết đăng ký, không mockup signup riêng.
- THÍCH NGHI: tái dùng login hiện tại, OwnerStyle canvas/inset/ink/primary; card trắng, không thêm theme.
- Vai trò là ý định onboarding. OWNER chỉ có khi người dùng tạo nhóm; MEMBER sau nhập mã và đồng ý. Không claim/flag đặc quyền do client chọn.
- Cognito SignUp / ConfirmSignUp / ResendConfirmationCode; chưa xác minh không cấp phiên. Không admin-confirm để làm đẹp ảnh.
- Tên hiển thị được người dùng chủ động đặt qua endpoint hồ sơ đã xác thực; không tin dữ liệu ID token chưa xác minh.
- Mật khẩu theo pool: ít nhất 12 ký tự, hoa/thường/số/ký tự đặc biệt; không trim mật khẩu.
- Root sở hữu auth API/router/login CTA; signup_ui sở hữu registration_screen.dart. Verifier khác implementer.

## Hạ tầng

Pool hiện tại bật self-registration, giữ email auto-verification và COGNITO_DEFAULT email delivery. Đọc toàn bộ cấu hình, chỉ đổi AdminCreateUserConfig.AllowAdminCreateUserOnly; không tạo pool mới, không đổi tài khoản có sẵn. Email mặc định Cognito có hạn mức; không coi là hệ thống gửi email không giới hạn.

## Kiểm tra

Ma trận: form trống/sai, mật khẩu không khớp, busy/error, xác minh mã sai/hết hạn, resend cooldown, quay lại sửa email, hai lựa chọn vai trò; 320/390/768px, text1.5 và bàn phím. Theo dõi build/ảnh và kết quả độc lập sau triển khai. CHƯA XÁC MINH HÌNH ẢNH ở thời điểm lập hồ sơ; chưa xác minh email end-to-end bằng hộp thư thật.

## Kết quả triển khai

- 38 tests đăng ký/auth/login đạt. Analyze sạch. Widget test gồm tên điều khiển, password policy, code lỗi không signIn, resend cooldown, disposed pending, retry hồ sơ không dùng lại code, 320px text1.5.
- Production web có CTA đăng ký, form chọn tạo/tham gia nhóm và kết nối Cognito. User chọn tự đăng ký sau: không gửi email test, không xác minh thủ công thay người dùng. Email end-to-end và hai luồng điều hướng sau mã thật chưa được xác minh runtime.
- Independent verifier signup_design đã đóng findings source; ảnh `artifacts/signup-check/register-final.png` 390×844 xác minh phần đầu form. CTA dưới vùng cuộn; không gọi ảnh này toàn trang. Icon tạo nhóm thiếu được đổi sang glyph hiện có, cần ảnh kiểm lại build cuối.
- Caddy entrypoints no-store; bootstrap gỡ Flutter service-worker/cache cũ. Đã cập nhật trang hỗ trợ về đăng ký website.
- Shop production trước đó trả 0 món; bổ sung `backend/db/shop-catalog.sql` riêng, không seed users/history/Coins. API trả 18 món bán + 2 mặc định/1 ẩn. Browser test1 đăng nhập và hiển thị artwork, ảnh `artifacts/signup-check/shop-test1.png`.
- Hai tài khoản do người dùng yêu cầu `test1@gmail.com`, `test2@gmail.com` được tạo admin với MessageAction SUPPRESS (không gửi thư), không đánh dấu email_verified; cùng MEMBER trong nhóm DEMO. Mật khẩu tuân thủ pool, không lưu trong audit. API login cả hai và browser test1 đã xác minh.
- Vòng kiểm lại cuối: signup_design xem `artifacts/signup-check/register-release-final.png` (1280×720, DPR1), xác nhận icon tạo nhóm hiện, đóng P2. Phần đầu form không thấy lỗi bố cục; phần dưới/bước mã chưa đủ bằng chứng để kết luận nghiệm thu toàn flow.
