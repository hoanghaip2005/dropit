# Kế hoạch chi phí thử nghiệm DropIt!

Ngày 24/10/2026. Người dùng chốt 300.000đ/tháng, 50 MAU, 10 người cùng lúc. Chưa provision AWS, chưa có billing alarms/IAM guardrails thực tế. Tài liệu này là phương án triển khai, không phải hard cap hay xác nhận tải đạt.

## Phương án tối thiểu

Một Lightsail Linux public IPv4 1 GB RAM, 40 GB SSD, $7/tháng. Caddy phục vụ Flutter web/HTTPS và reverse proxy Node REST/Socket.IO; PostgreSQL cùng máy. Build Flutter/Node ở máy phát triển hoặc CI, không build trên máy 1 GB. Cognito Lite, admin tạo tài khoản, không SMS/Plus/threat protection trả phí.

Một Lightsail Object Storage bundle $1/tháng (5 GB storage, 25 GB transfer) dành cho backup private. Không công khai backup. Dump PostgreSQL + dữ liệu uploads cần phục hồi, mã hóa trước khi upload; giữ 7 bản ngày và 2 bản tuần, tổng dưới 4 GB. Cần triển khai và diễn tập restore trước khi nhận dữ liệu thật. Không bật snapshot tự động ngoài phương án này.

Không RDS, NAT Gateway, ALB, ECS/Fargate, Kubernetes, autoscaling hoặc CDN giai đoạn đầu. App uploads và assets trên máy, hạn mức; chưa dùng bucket công khai. Dùng domain đã có; domain mới là chi phí riêng cần tính lại.

## Ước tính tháng đủ

| Khoản | USD/tháng | Điều kiện |
|---|---:|---|
| Lightsail 1 GB public IPv4 | 7 | Một instance duy nhất, xác nhận bundle tại region trước khi tạo |
| Private backup bucket | 1 | Không vượt 5 GB storage/25 GB transfer, không thêm bundle |
| Cognito Lite email/password | 0 dự kiến | 50 MAU; nằm trong 10.000 MAU free tier dùng chung account/organization, phải kiểm account có đủ điều kiện và phần đã dùng |
| Caddy TLS, local rotated logs | 0 phí dịch vụ riêng | Chạy trong instance, không bật paid log ingestion |
| Tổng cơ sở | **8** | Chưa thuế/phí thẻ/tên miền/email provider/overage |

Tỷ giá lập kế hoạch 26.000đ/USD, không phải tỷ giá ngân hàng hiện hành. $8 = 208.000đ. Dự phòng thuế 10% + phí ngoại tệ 5% trên cơ sở = 31.200đ; tổng minh họa 239.200đ, còn 60.800đ dự phòng. Không khẳng định thuế thực tế là 10%; xem hóa đơn/tài khoản. Ngưỡng vận hành đề xuất $9; cảnh báo account $5/$8/$9/$10. Các khoản account đang có phải tính chung, không chỉ project tag.

Chưa tính email báo cáo production: local outbox chưa gửi mail thật. Nếu cần gửi báo cáo trong đợt thử nghiệm phải thêm dự toán SES/provider, giới hạn gửi và xác minh domain trước; không coi tổng $8 là đầy đủ cho tính năng chưa triển khai.

Máy 2 GB $12/tháng đã vượt 300.000đ khi tính backup/thuế. Nếu 1 GB không qua load test thì dừng phương án, cân nhắc VPS fixed-price khác hoặc tăng ngân sách; không âm thầm nâng gói.

## Giới hạn và cảnh báo phải thiết lập trước launch

1. Account/project thử nghiệm riêng nếu có thể; region ap-southeast-1 dự kiến. Tài khoản runtime không có quyền tạo/nâng gói tài nguyên. Quyền triển khai tách riêng; không gắn AWS administrator vào app. Quota thấp là lớp hỗ trợ, không phải hard cap USD.
2. AWS Budgets ở account: actual $5/$8/$9/$10, forecast $9; Cost Anomaly Detection. Người dùng cấu hình địa chỉ nhận thông báo. Chưa tạo notification hay gửi email nào.
3. Một instance, một bucket, không autoscaling. Bật quota ứng dụng: 50 account thử nghiệm, mục tiêu 10 người cùng lúc; giới hạn connection theo user/IP, rate limit REST/auth-related flows, giới hạn request/body. Cognito app client ID là công khai nên giới hạn proxy riêng không bao hết request trực tiếp tới Cognito; admin-only signup giảm mở rộng account ngoài ý muốn.
4. Avatar tối đa 2 MB, kiểm loại ảnh, thay ảnh phải dọn bản cũ; tổng uploads ban đầu 500 MB. Log rotation tổng 200 MB, không log body/token/password. Cảnh báo disk 70/85%, RAM/CPU và transfer; kiểm chi phí hằng ngày. Các số là cấu hình đề xuất, chưa được áp dụng trong app.
5. Backup dưới 4 GB, transfer có cảnh báo trước allowance; Lightsail có overage, bundle không phải trần tuyệt đối. Không tự tải backup lớn hoặc public assets từ bucket ngoài dự toán.
6. Khi account gần $9: kiểm nguồn tăng, khóa đăng ký/upload mới hoặc chuyển maintenance theo runbook đã thử. Có thể tự động hóa bằng budget action + quyền giới hạn sau khi kiểm khả năng hỗ trợ dịch vụ. Không tự xóa DB/bucket. Dừng instance vẫn có thể còn storage/IP/backup phí; phải kiểm từng tài nguyên.

AWS Budgets cập nhật có độ trễ, notification/action không đảm bảo dừng tại đúng số tiền. Với yêu cầu tuyệt đối không vượt 300.000đ, AWS trả sau không cung cấp bảo đảm đó chỉ bằng Budgets. Nên chọn hosting trả trước có hard quota/suspend và xem điều khoản overage.

## Cổng thử nghiệm

- Kiểm account đã có dịch vụ/commitment nào phát sinh phí, free-tier Cognito còn bao nhiêu; không đọc/lưu khóa AWS trong hồ sơ.
- Chốt region/bundle/invoice tax, domain và email; tạo billing guardrails trước app infrastructure.
- Kiểm 10 socket đồng thời, join/heartbeat/reconnect, PostgreSQL và báo cáo cùng hoạt động trong 30–60 phút; không OOM, không rơi phiên, độ trễ chấp nhận được. Chưa có kết quả benchmark.
- Restore backup sang DB thử và kiểm tính nhất quán; tài nguyên tạm phải có TTL/dọn sau thử, nằm trong budget.
- Máy đơn là single point of failure; downtime khi bảo trì, không HA/SLA production. Chỉ beta nhỏ; không coi 50 MAU chứng minh đủ 10 concurrent.

## Nguồn giá

Đọc trang công khai ngày 24/10/2026, không dựa credit/free trial để tính compute:

- https://aws.amazon.com/lightsail/pricing/ — public IPv4 Linux 1 GB $7; 2 GB $12; object bucket $1/5 GB/25 GB transfer; overage tính riêng theo region.
- https://aws.amazon.com/cognito/pricing/ — direct/social Lite và Essentials 10.000 MAU free tier/account hoặc organization; Plus không có free tier. SMS và add-on tính riêng.
- https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html — Budgets và giới hạn giám sát.

Trạng thái: đã tính phương án và pin `UserPoolTier: LITE` trong template; chưa deploy, chưa thiết lập billing, chưa áp dụng hạn mức ứng dụng.
