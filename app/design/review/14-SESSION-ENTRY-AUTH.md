# 14 — Entrée phiên và auth

28/10/2026; source yêu cầu mới người dùng ưu tiên hơn quy tắc đóng cửa cũ.

- GIỮ: chủ nhóm quản lý, thành viên tham gia; không sửa dữ liệu phiên thật để minh họa.
- THÍCH NGHI: lobby mở10phút trước, admission tới start+1phút; start giữ nguyên, kết thúc không kéo dài, người vào trễ ghi late_join. Nếu trống sau hạn mới NO_ATTENDEE. Backend test bảo vệ deadline.
- SỬA: home tự cập nhật giờ mỗi giây/refetch15s, nút nói rõ giờ mở hoặc vào ngay; early-entry tự retry khi lobby mở, không phải về home thủ công.
- AUTH: login chỉ kiểm không rỗng, không kiểm độ dài/độ phức tạp. Đăng ký6..256 ký tự, Cognito pool thực tế MinimumLength6, complexity=false; không đổi mật khẩu tài khoản đã tồn tại. User yêu cầu mật khẩu tự chọn;6 là giới hạn Cognito.
- QR giữ return route qua onboarding/login/register, chỉ allow nội bộ /consent/:code không redirect URL ngoài.
- Reward duration:1..25 floor(min*10/25),26..49 10+floor((min-25)*15/25),>=50 tối đa25; giữ25/50 thưởng10/25, trần ngày100 không đổi. Không cấp thưởng ảo ở UI.
- root sở hữu app auth/router/core/home/session, backend_management backend; group_management/profile_shop kiểm source độc lập phần người khác.
- CHƯA XÁC MINH HÌNH ẢNH build mới đến khi có runtime capture; không coi test thay visual.

Coin: test1 xác định Cognito sub rồi ADMIN_ADJUST tới99999 trong transaction/idempotent, số dư đọc lại99999. Không lưu credentials.
