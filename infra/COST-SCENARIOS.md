# Chi phí AWS theo khối lượng — 25/10/2026

Phạm vi: beta một Lightsail 1 GB, PostgreSQL cùng máy, Cognito Lite, Lightsail Object Storage, SNS push và SES outbound. Không phải kiến trúc đích ECS/ALB/RDS/CloudFront/WAF. Không có phép tính min/max tuyệt đối cho AWS pay-as-you-go; đây là biên của ba kịch bản cụ thể, chưa là hạn mức đã enforce.

## Số liệu đo và giả định

Đo repo hiện tại: build/web 50.774.855 byte/94 file, assets 8.535.853 byte. Build có nhiều biến thể renderer và file debug/symbol nên trình duyệt thường không tải tất cả. Để dự toán bảo thủ, tính mỗi cold load tải cả 50,775 MB chưa nén. Không coi con số đó là network measurement. Heartbeat code mỗi5giây. DB size/CPU/RAM chưa đo production.

50 MAU, tối đa10 đồng thời do người dùng cung cấp. Tải thấp/cơ sở/cao đều 50 MAU. Giả định 1 thiết bị/người, 1 cold load/phiên; 100 REST response/phiên, mỗi response10KB; egress heartbeat1KiB/lượt. Các giá trị response/egress và số thao tác là giả định, chưa benchmark; chưa bao hết mọi request, TLS, broadcast và cache. Transfer công thức là subtotal của các thành phần được mô hình hóa, không phải upper bound mạng tuyệt đối. Trần bộ nhớ/CPU chưa có benchmark để bảo đảm máy1GB đủ.

| Đầu vào tháng | Thấp | Cơ sở | Cao |
|---|---:|---:|---:|
| Phiên/người |4|20|60|
| Phút/phiên |25|50|50|
| Tổng lượt người-phiên |200|1.000|3.000|
| Giờ người dùng |83,33|833,33|2.500|
| Heartbeat |60.000|600.000|1.800.000|
| Cold load web |200|1.000|3.000|
| Push/người-phiên trước retry |2|5|20|
| Publish push gồm dự phòng1retry cho mọi lượt |800|10.000|120.000|
| Email outbound không attachment |50|250|1.000|
| DB tổng cuối tháng (GB) |0,05|0,25|1|
| Upload tổng cuối tháng (GB) |0,01|0,10|1|
| Backup9bản đầy đủ (GB) |0,54|3,15|18|
| Egress subtotal (GB) |10,416|52,389|157,168|

Lượt người-phiên không phải số session nhóm; ví dụ5người học chung là5lượt. Kịch bản cao cần250giờ/tháng nếu luôn10người đồng thời, không vi phạm10concurrent. API/DB workload vẫn phải đo bằng script tải thật. Giữ upload+DB suốt nhiều tháng làm storage tăng; bảng mô hình kích thước tổng, không tự đặt lại dữ liệu mỗi tháng.

Backup tính9*(DB+upload), không giả incremental/compression. Upload backup tối đa31daily+5weekly=36 bản đầy đủ/tháng, tương ứng2,16/12,6/72GB ingress vào bucket; ingress theo pricing bundle miễn phí. Restore test1lần/tháng đọc một bản tổng0,06/0,35/2GB, nằm trong25/25/250GB transfer bucket. Không tải cả9bản ra Internet mỗi ngày. Gói5GB không đủ cho18GB; kịch bản cao chủ động tính gói100GB $3, không tính overage tùy tiện và không tự nâng gói khi chưa duyệt.

## Đơn giá sử dụng

- Lightsail Linux public IPv4 1GB: $7/tháng, allowance transfer2TB/tháng theo bảng; cần xác nhận bundle Singapore. Không thêm phíIPv4 lần nữa vì đã nằm trong bundle. Mô hình chưa có snapshot, disk phụ hoặc server khác.
- Object Storage: $1/tháng5GB/25GBtransfer hoặc $3/tháng100GB/250GBtransfer. Snapshot là dịch vụ khác không bật. Dung lượng vượt gói phải tính lại.
- Cognito Lite direct email/password: $0 tại50MAU nếu account/organization còn10.000MAUfree tier; không SMS/Plus/add-on. Nếu free tier đã dùng hết thì phải thay dòng này, không áp dụng kết quả tổng dưới đây.
- SNS standard requests:1triệu requests/tháng miễn phí, mobile push1triệu deliveries/tháng miễn phí theo bảng. Tất cả ba kịch bản dưới allowance, giả định account chưa dùng allowance nơi khác và payload<64KB. Dự phòng100endpoint create+100enable thêm200requests vẫn dưới1triệu. FCM/APNs transport không có dòng phí per-push riêng trong mô hình này. Không dùng SMS/SNS email notification.
- SES outbound $0,10/1.000email recipients, không trừ free tier/credits; attachment0 nên phí attachment0. Không Mail Manager, dedicated IP, global endpoints.
- IAM và TLS Caddy không có dòng phí riêng; logs local rotation. Không dùng CloudWatch paid ingestion, Secrets Manager/KMS riêng trong cấu hình beta này. Chi phí cảnh báo Budgets/email-only phải kiểm tài khoản; không bật paid actions hay paid monitoring ngoài dự toán.

## Thành tiền tháng

| Khoản USD | Thấp | Cơ sở | Cao |
|---|---:|---:|---:|
| Lightsail |7|7|7|
| Backup bucket |1|1|3|
| Cognito |0*|0*|0*|
| SNS |0*|0*|0*|
| SES |0,005|0,025|0,100|
| Transfer vượt allowance theo mô hình |0|0|0|
| **Tổng USD** |**8,005**|**8,025**|**10,100**|
| Cơ sở VND,26.000đ/USD |208.130|208.650|262.600|
| **VND gồm dự phòng15%** |**239.350**|**239.948**|**301.990**|

*Điều kiện free allowance như trên. Dự phòng15% = giả định gộp thuế/phí ngoại tệ, không phải thuế suất xác nhận, không thay số thực tế trên hóa đơn. Không domain mới, Apple Developer membership, tài nguyên account khác, staging/HA, overage, WAF hoặc tấn công. Một máy là single point of failure. Chưa provision AWS.

Trung điểm của thấp/cao=(8,005+10,100)/2=$9,0525, khoảng270.670đ có dự phòng. Trung bình ba kịch bản không trọng số=$8,71, khoảng260.429đ. Cả hai là trung bình số học, không phải expected bill. Kịch bản cơ sở là239.948đ; không có xác suất/usage thật để kết luận hóa đơn trung bình.

Ở300.000đ, giá cơ sở USD tối đa theo dự phòng=300.000/(26.000*1,15)=$10,0334. Gói cao$10,10 vượt khoảng1.990đ. Nếu máy1GB không đủ và cần2GB $12 thì ngay phương án backup$1+SES0,025 là$13,025, khoảng389.448đ/tháng có dự phòng. Đây là rủi ro lớn hơn phí push/email; chưa được load-test nên không khẳng định gói$7 đủ.

## Công thức có thể kiểm lại

sessions=50*sessions_per_user
heartbeat=sessions*minutes*60/5
cold_web_GB=50.774855*cold_loads/1000
REST_GB=sessions*100*10000/1e9
heartbeat_GB=heartbeat*1024/1e9
backup_GB=9*(db_GB+upload_GB)
SES_USD=email_recipients/1000*0.10
monthly_USD=7+bucket_plan+SES+Cognito+SNS+overage
VND=monthly_USD*26000*1.15

Dữ liệu máy đọc: `infra/cost-scenarios.json`. Cần benchmark10concurrent, đo egress/log/DB growth rồi thay giả định. Hạn mức app/bucket và cảnh báo chưa được triển khai, nên biên cao trên không phải hard cap.

## Nguồn giá

Đọc25/10/2026: https://aws.amazon.com/lightsail/pricing/ ; https://aws.amazon.com/cognito/pricing/ ; https://aws.amazon.com/sns/pricing/ ; https://aws.amazon.com/ses/pricing/ . Các bảng động có đơn giá theo region; cần xác nhận lại console/calculator tại thời điểm tạo tài nguyên. Không dùng credits dùng thử để làm số thấp hơn.
