# DropIt guardrails — 25/10/2026

Profile deployment: dropit-admin (AdminUser có MFA), không dùng root. Chưa tạo backend runtime credentials/keys. Không mặc định AdminUser least privilege: user này vẫn AdministratorAccess qua AdminGroup có sẵn. Giảm quyền admin hiện hữu phải có scope riêng, không âm thầm sửa.

Đã kiểm account: có5budgets cũ, giữ nguyên. Default-Services-Monitor đã tồn tại, tái sử dụng. Default subscription DAILY với AND impact>=100USD và>=40%, giữ nguyên; DropIt subscription riêng cần ngưỡng impact>=1USD OR percentage>=50% (anomaly detection không phải mọi tăng chi phí đều cảnh báo). Monitor AWS service dimension không cần tạo trùng.

Budget mới account-wide10USD/month, không tag-filter để tránh bỏ lọt phí. Absolute actual5/8/9/10USD, forecast9USD, EMAIL subscriber cần người dùng cung cấp. IncludeTax=true, IncludeCredit=false/IncludeRefund=false để credits không che gross usage. Không auto-stop/delete tài nguyên, không paid budget actions. Budget có độ trễ và không hard cap300.000đ.

Runtime policy chỉ cấp sau khi có SNS application/endpoint ARN thực. Actions SNS CreatePlatformEndpoint trên platformapplication, SetEndpointAttributes/Publish trên endpoint của đúng application; thêm GetEndpointAttributes nếu implementation cần. Không sns:*, iam:*, billing hoặc quyền tạo máy. Lightsail backup có thể dùng bucket resource access gắn instance, tránh IAM access key dài hạn nếu khả thi; giới hạn bucket/prefix, lifecycle cleanup tách quyền và kiểm restore. Không attach placeholder policy vào tài khoản thật.

Cần kiểm cơ chế credential của Lightsail: không mặc định có EC2 instance profile tùy ý. Chốt trusted delivery credential/runtime và backup access trước launch. Không đưa quyền admin vào máy hoặc Flutter. Token/secret không nằm repo/log.

Tình trạng: dự thảo budget ởbudget.json; chờ email để tạo notification/subscription và đọc lại xác minh. Chưa provision compute/storage/Cognito/SNS/SES. Chưa gửi test email. Ghi kết quả triển khai tiếp ởDEPLOYMENT.md, không lưu địa chỉ email cá nhân vào repo.
