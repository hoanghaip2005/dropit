# Đăng nhập Cognito — cấu hình và giới hạn phát hành

Ngày 24/10/2026. Người dùng chọn Cognito, chưa tạo User Pool. Mẫu `infra/cognito.yaml` chưa được triển khai lên AWS. Đây là cấu hình chuẩn bị; không phải xác nhận production sẵn sàng.

## Tạo cấu hình

1. Mở AWS CloudFormation tại region mong muốn, tạo stack từ `infra/cognito.yaml`. Thao tác tạo tài nguyên có thể phát sinh chi phí AWS. Template giữ User Pool khi xóa/thay stack để tránh mất tài khoản.
2. Lấy ba Outputs `Region`, `UserPoolId`, `ClientId`. Đây là ID công khai; client không có secret. Không đặt AWS access key hoặc client secret trong Flutter.
3. Pool hiện chỉ cho quản trị viên tạo tài khoản. Tạo tài khoản xác minh email và đặt mật khẩu vĩnh viễn qua quy trình quản trị an toàn. Không dùng mật khẩu tạm: app chưa hỗ trợ challenge `NEW_PASSWORD_REQUIRED`. Template chưa bật MFA vì app chưa có UI challenge; cần triển khai challenge trước khi bật.
4. Cấu hình backend và build Flutter bằng cùng bộ ID. Không dùng ID trong ví dụ dưới làm cấu hình thật.

Backend environment:

```text
NODE_ENV=production
DEV_AUTH=0
COGNITO_REGION=<Region>
COGNITO_USER_POOL_ID=<UserPoolId>
COGNITO_CLIENT_ID=<ClientId>
```

Build Flutter (thay các placeholder; `API_BASE_URL` là origin backend HTTPS, không có `/v1`):

```powershell
D:/flutter/bin/flutter.bat build web --release --pwa-strategy=none --dart-define=API_BASE_URL=https://api.example.com --dart-define=COGNITO_REGION=REGION --dart-define=COGNITO_USER_POOL_ID=POOL_ID --dart-define=COGNITO_CLIENT_ID=CLIENT_ID
```

Development có bất kỳ Cognito ID sẽ chọn verifier Cognito và từ chối cấu hình thiếu; `DEV_AUTH=1` là lựa chọn explicit chỉ dành dev/test. Production từ chối dev auth. Thiếu Cognito, form vô hiệu hóa submit, không fallback tài khoản mẫu.

## Hành vi hiện tại

- Email/mật khẩu gửi trực tiếp tới Cognito HTTPS. Backend kiểm access JWT bằng JWKS, issuer, client, token_use, hạn dùng và RS256.
- Access/refresh token chỉ ở bộ nhớ. Tải lại/đóng app phải đăng nhập lại. Token dev cũ trong preferences bị bỏ và xóa.
- Có refresh; reconnect socket lấy token hiện tại. Đăng xuất xóa phiên/cache cục bộ, chưa gọi thu hồi refresh token tại Cognito.
- Không có control đăng ký, quên mật khẩu, ghi nhớ hoặc MFA giả. Tài khoản cần challenge/đặt lại mật khẩu nhận thông báo liên hệ quản trị viên.

## Cổng phát hành còn mở

- Tạo pool/client, tài khoản thật; kiểm login đúng/sai, refresh/expiry, logout, reconnect, quyền REST/socket. Chưa có kiểm thử AWS end-to-end.
- Access token Cognito thông thường không mang email/name. Backend hiện có thể tạo profile email null, tên “Người dùng”. Cần đồng bộ thuộc tính đáng tin cậy trước khi phát hành tính năng hồ sơ/email báo cáo; không tin email do client tự gửi.
- Hoàn thiện recovery/signup/challenge theo phạm vi sản phẩm, quyết định phiên bền vững và thu hồi phiên.
- Triển khai HTTPS, origin CORS/socket cụ thể, DB production/migrations/backup, khóa nhật ký được quản lý, uploads/email provider thật, giám sát và rollback. Local uploads/outbox và khóa mặc định không đủ để phát hành.
- UI login: **CHƯA XÁC MINH HÌNH ẢNH**. Test/layout không thay ảnh runtime đúng build.

Giữ bản phát hành trước để rollback frontend/backend cùng cấu hình tương thích; không xóa User Pool hay dữ liệu thật để rollback UI.
