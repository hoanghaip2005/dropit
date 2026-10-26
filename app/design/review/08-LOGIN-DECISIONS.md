# Đợt 08 — phân xử màn đăng nhập thật

Ngày 24/10/2026. Arbiter `design_arbitration`; không triển khai. **SOURCE_AUDIT — CHƯA XÁC MINH HÌNH ẢNH**.

## Phạm vi và nguồn

- Ưu tiên mới do root chuyển: đăng nhập production, bỏ chọn tài khoản mock. Không dùng UI seed hoặc dev token.
- Route `/login`; phạm vi UI `LoginScreen` và helper riêng trong `app/lib/features/auth/auth_screens.dart`. Giữ onboarding ngoài phạm vi. Root sở hữu auth/backend/config Cognito; worker không sửa các file đó khi chưa bàn giao.
- Nguồn chính `mockup/sign_in_login/code.html`, SHA256 `624119C4D4797A4C5B0EB53F13523EA1E1802B0955D5888E5551188480F6C36F`; nguồn app đã đọc: LoginScreen hiện dùng dev users/token. Audit reference độc lập bổ sung sau, không suy ra hình ảnh app từ code.
- Áp dụng thứ tự nguồn tại `DECISIONS.md`; không sao chép chức năng chưa có chỉ vì mockup vẽ sẵn. Không đọc hoặc ghi bí mật vào hồ sơ.
- Reference reviewer `design_reference` xác nhận nguồn: input pill 52 px, CTA 56 px; architecture §1.2 yêu cầu app gọi Cognito, backend xác minh JWT, không giữ mật khẩu; DQ04 lựa chọn SDK còn chờ. Kích thước mockup là baseline, được tăng theo chữ/accessibility.

## Quyết định chuyển triển khai

| ID | Quyết định | Lý do và tiêu chí |
|---|---|---|
| LOGIN01 | SỬA: canvas `#F4F5F7`, surface trắng/inset trung tính, CTA `#010102`, brand `#B02F00`. | Đồng bộ design system; không thêm card outline hoặc gradient trang trí tùy ý. Giữ khoảng ngang 16, nhịp 8/16/24; nội dung web giới hạn khoảng 430–480 px, nền phủ viewport. |
| LOGIN02 | THÍCH NGHI: nhận diện DropIt! rõ ràng phía trên form. | Dùng mark/wordmark sẵn có hoặc chữ DropIt! đơn giản; không chế logo mới hoặc tải asset không rõ nguồn. Giữ tiêu đề “Chào mừng trở lại”, mô tả ngắn theo mockup. |
| LOGIN03 | SỬA: form email và mật khẩu thật. | Label hiển thị bền vững; placeholder không thay label. Email keyboard/autofill phù hợp; mật khẩu che mặc định, nút hiện/ẩn có tooltip và semantics cập nhật. Email trim; không trim/đổi mật khẩu. Không giới hạn email công việc nếu hệ thống không có quy tắc đó. |
| LOGIN04 | SỬA: bỏ seed list, nhập ID tùy ý, banner phát triển, địa chỉ backend và thông báo kỹ thuật. | Không có đường đăng nhập giả trong UI production. Thiếu public config phải hiện trạng thái chưa cấu hình trung thực; tuyệt đối không fallback dev token. Không giả đăng nhập thành công để xem màn. |
| LOGIN05 | THÍCH NGHI: bỏ “Ghi nhớ đăng nhập” nếu persistence không có lựa chọn tương ứng. | Không tạo checkbox vô tác dụng. Việc lưu/khôi phục phiên do auth contract quyết định; UI không hứa bảo mật hoặc thời hạn chưa được xác minh. |
| LOGIN06 | THÍCH NGHI: đăng ký/quên mật khẩu chỉ xuất hiện khi có flow thật. | Không link chết, toast “sắp có” hoặc route giả. Nếu root triển khai challenge/reset, mô tả đúng bước; challenge không được coi là đã đăng nhập. Không tự mở rộng UI sang đăng ký toàn bộ trong lô này. |
| LOGIN07 | SỬA: lỗi và loading có ý nghĩa. | Kiểm trống/email tại form, lỗi xác thực chung “Email hoặc mật khẩu không đúng”; mạng/rate limit/cấu hình phân biệt với sai thông tin, không lộ raw exception/token/URL. Lỗi liên kết field hoặc vùng thông báo live. Submit bận chống gửi đôi và đổi input làm nhầm request; spinner giữ nhãn/nút ổn định, không treo sau lỗi. |
| LOGIN08 | SỬA: accessibility và responsive. | Tab order email → mật khẩu → hiện/ẩn → submit; Enter gửi đúng một lần. Nút tối thiểu 48 px, text/semantic rõ, focus nhìn thấy, error không chỉ dựa màu. Cuộn được khi bàn phím mở; 320 px và text scale 1.5 không che field/lỗi/CTA, không khóa phóng to. |
| LOGIN09 | THÍCH NGHI: Back theo router thực. | Không back rỗng hoặc quay lại màn đã bảo vệ khi chưa đăng nhập. Không ép header back chỉ vì mockup có; dùng `canPop`/fallback công khai đúng navigation hiện hữu. Auth success chỉ điều hướng sau khi có phiên hợp lệ; không điều hướng sau dispose. |
| LOGIN10 | CHỜ CONTRACT: hình thức Cognito do root chốt theo architecture. | Direct email/password phù hợp nguồn; nếu chọn Hosted UI Authorization Code + PKCE, thay bằng CTA ghi rõ chuyển đến trang đăng nhập, không dựng password form giả. Không gửi mật khẩu qua backend ứng dụng. LOGIN03 chỉ áp dụng khi direct auth được chọn. |

## Cổng bàn giao và kiểm tra độc lập

Worker sở hữu UI login; root sở hữu auth/config/backend. Khi contract sẵn sàng mới nối submit thật. Kiểm độc lập sau patch: validation, duplicate submit, error/offline/rate limit, thiếu config, success/session restore/logout, challenge, dispose; kiểm không còn dev bypass trong build production. Security source review không thay integration Cognito bằng cấu hình thật.

Verifier phải khác implementer. Ghi source hash, kết quả kiểm thử và build thực; không lưu password/token/config bí mật. Chỉ nghiệm thu thị giác khi có ảnh đúng build/trạng thái/viewport; hiện **CHƯA XÁC MINH HÌNH ẢNH**. Các phần backend hay flow chưa có bằng chứng phải ghi chưa kiểm, không suy ra đạt từ form đẹp.
