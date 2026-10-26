# Triển khai guardrails — 25/10/2026

Đã thực hiện bằng profile dropit-admin, xác thực AdminUser có MFA. Không dùng root cho đợt này.

- Tạo và đọc lại budget `DropIt-Monthly-10USD`: MONTHLY, COST, USD10, account-wide, include tax, không trừ credits/refunds.
- **CHƯA CÓ NOTIFICATION/SUBSCRIBER** cho budget mới: đang chờ email người dùng. Budget tồn tại không đồng nghĩa cảnh báo đã hoạt động.
- Giữ nguyên5budget cũ và default anomaly monitor/subscription. Subscription mặc định threshold100USD AND40%, không phù hợp budget nhỏ; chưa tạo subscription thấp khi chưa có recipient.
- IAM kiểm read-only: root có MFA; AdminUser có1MFA, đổi mật khẩu lần đầu hoàn tất, nhóm AdminGroup AdministratorAccess. Không chỉnh quyền admin hiện hữu, không tạo IAM access key hoặc cấp runtime permissions.
- Chưa tạo máy, bucket, Cognito, SNS application hoặc SES. Runtime/backup policy chờ resource ARN và lựa chọn credential least privilege.

Tiếp theo: email recipient -> tạo5budget notifications actual5/8/9/10USD, forecast9USD -> anomaly subscription DAILY >=1USD OR>=50% trên monitor sẵn có -> readback config/status. Việc AWS gửi email/recipient nhận được phải xác minh riêng. Alert có độ trễ, không hard cap.

## Cập nhật đã triển khai — 25/10/2026

- Đã tạo5notifications cho DropIt-Monthly-10USD: ACTUAL GREATER_THAN5/8/9/10USD, FORECASTED GREATER_THAN9USD, threshold ABSOLUTE_VALUE. Readback từng notification và subscriber khớp email người dùng cung cấp; không lưu email cá nhân trong repo.
- Đã tạo `DropIt-Low-Cost-Alerts`, DAILY trên Default-Services-Monitor, OR absolute impact>=1USD hoặc percentage>=50%. Readback subscriber EMAIL trạng tháiCONFIRMED, recipient khớp. Ngưỡng chỉ lọc anomaly AWS đã phát hiện, không phát hiện mọi khoản chi tăng.
- Giữ nguyên các budget/monitor/subscription cũ. Không paid budget actions, không tự dừng/xóa tài nguyên.
- Chưa kiểm một cảnh báo thực tới inbox; không tạo chi phí giả để test. Config verified không tương đương email delivery verified. Billing/anomaly có độ trễ; không hard cap.
- IAM runtime/backup policy vẫn chưa attach, chờ ARN dịch vụ và credential model. Không máy/bucket/Cognito/SNS platform/SES được provision từ đợt guardrail.
