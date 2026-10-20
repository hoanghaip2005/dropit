# DropIt! — Giai đoạn 1: Ý tưởng (bản dùng cho văn phòng)

Nhóm: Bá Khí · Phiên bản 1.1 (nháp) · Nền tảng: SquadFocus, điều chỉnh để áp dụng vào văn phòng

> Các mục đánh dấu **(giả định)** hoặc **(đề xuất)** là suy luận của mình, chưa được kiểm chứng với người dùng thật. Nhóm cần xác nhận hoặc sửa trước khi sang giai đoạn 2.

## 0. Thay đổi so với bản 1.0

| Hạng mục | Bản 1.0 (SquadFocus) | Bản 1.1 (văn phòng) |
| --- | --- | --- |
| Bối cảnh | Sinh viên, nhóm học | Văn phòng, trưởng phòng quản lý nhiều nhóm |
| Nhóm | Phòng 2–6 người, ai cũng tạo được | **Trưởng phòng tạo nhiều nhóm, mỗi nhóm 4–10 người** |
| Cược điểm | Cược Điểm Điểm Danh, thua thì mất | **Bỏ cược** |
| Khi có người thoát app | Cả phòng "nổ", mất cược | **Hệ thống báo trưởng phòng**; ảnh hưởng đến phiên xem mục 4 |
| Điểm danh và chuỗi | Vừa là tiền cược vừa là uy tín | Chỉ là **thành tích**, không dùng để tiêu |
| Coins | Kiếm khi hoàn thành phiên | **Mỗi lần hoàn thành được quy thành Coins**, mua đồ trang trí trong Shop |
| Báo cáo | Không có | **Báo cáo cuối tháng** cho trưởng phòng |
| Xã hội | Ngoài MVP | **Kết bạn, xem bài viết, nhật ký hằng ngày** (đề xuất làm theo giai đoạn, mục 7) |

## 1. Tóm tắt ý tưởng

**DropIt!** giúp văn phòng tạo những khung giờ tập trung chung. Trưởng phòng lập nhiều nhóm 4–10 người. Trong phiên, mọi người úp điện thoại xuống; nếu ai rời app, hệ thống báo cho trưởng phòng. Nhân viên tích **điểm danh và chuỗi** làm thành tích, nhận **Coins** để mua khung avatar, hình nền profile; có thể kết bạn, xem bài viết và ghi nhật ký mỗi ngày. Cuối tháng trưởng phòng xem báo cáo.

Ý chính: thay áp lực "mất điểm" bằng **minh bạch, thành tích và phần thưởng thẩm mỹ**, phù hợp môi trường làm việc hơn.

## 2. Vấn đề **(giả định)**

| Vấn đề | Biểu hiện |
| --- | --- |
| Điện thoại làm đứt mạch làm việc | Vài phút lại xem thông báo, mạng xã hội |
| Trưởng phòng khó nắm mức độ tập trung của nhóm | Chỉ cảm nhận, không có số liệu |
| Nhắc nhở trực tiếp dễ mất lòng | Ngại nhắc, hoặc nhắc xong căng thẳng |
| Thiếu động lực tích cực | Chỉ có phê bình, ít ghi nhận |
| Cuối tháng không có dữ liệu để đánh giá khách quan | Báo cáo dựa vào cảm tính |

## 3. Người dùng

| Vai trò | Mong muốn | Nỗi đau |
| --- | --- | --- |
| **Trưởng phòng** | Nhóm tập trung, có số liệu cuối tháng, ít phải nhắc | Không biết ai/khi nào bị xao nhãng, sợ bị coi là giám sát quá mức |
| **Thành viên (nhân viên)** | Được ghi nhận thành tích, có không gian cá nhân đẹp, có kết nối đồng nghiệp | Sợ bị theo dõi, sợ bị phạt oan khi có việc đột xuất |
| **Quản trị hệ thống** | Quản lý tài khoản, danh mục Shop, kiểm duyệt nội dung | Xử lý báo cáo vi phạm, lỗi dữ liệu |

## 4. Cơ chế cốt lõi

**Cấu trúc:** Văn phòng → Nhóm (4–10 người) → Phiên tập trung.

1. **Trưởng phòng** tạo nhiều nhóm, mời thành viên (mã hoặc email), đặt khung giờ phiên (25 hoặc 50 phút), nhận thông báo, xem báo cáo.
2. **Phiên và Lockdown:** đếm ngược 5 giây để úp máy, giao diện tối tĩnh, khoan hồng 3 giây khi vừa rời app.
3. **Khi có người thoát app:** hệ thống ghi sự kiện và **báo trưởng phòng** (mặc định báo ngay; tùy chọn gộp báo cuối phiên). Người thoát không nhận Coins của phiên đó và bị ngắt chuỗi ngày. **(đề xuất)** Phiên của những người còn lại vẫn tiếp tục, thay cho "nổ phòng", vì trong văn phòng việc phạt cả nhóm dễ gây mâu thuẫn. Cần nhóm quyết định (mục 13).
4. **Thành tích (không còn cược):** điểm danh hằng ngày, chuỗi ngày liên tiếp hoàn thành phiên, huy hiệu theo mốc. Không có cơ chế làm mất điểm do cược.
5. **Coins:** mỗi phiên hoàn thành được quy thành Coins theo thời lượng (ví dụ 25 phút = 10, 50 phút = 25, cấu hình được, có trần mỗi ngày).
6. **Shop:** khung avatar, hình nền profile, huy hiệu, danh hiệu. Chỉ có đồ thẩm mỹ, không bán lợi thế gì.
7. **Hồ sơ và xã hội:** hồ sơ cá nhân hiển thị khung, hình nền, thành tích; kết bạn; xem bài viết; **nhật ký hằng ngày**, mặc định riêng tư, người viết tự chọn chia sẻ.
8. **Báo cáo cuối tháng** cho trưởng phòng:
   - Mỗi thành viên: số ngày điểm danh, số phiên hoàn thành, tổng phút tập trung, số lần thoát, chuỗi dài nhất.
   - Mỗi nhóm: tỉ lệ hoàn thành phiên, so với tháng trước.
   - Xuất PDF/Excel và gửi qua email.

## 5. Điểm khác biệt **(giả định, cần kiểm tra lại)**

| Nhóm giải pháp | Hạn chế so với DropIt! |
| --- | --- |
| App tập trung cá nhân có thưởng ảo | Không có trưởng phòng, không có khung giờ chung, không có báo cáo nhóm |
| App chặn ứng dụng | Không có yếu tố đồng đội; dễ tắt |
| Phần mềm theo dõi thời gian làm việc | Mang tính giám sát nặng, dễ gây phản cảm |
| Chế độ tập trung có sẵn của hệ điều hành | Người dùng tự tắt, không có số liệu cho trưởng phòng |

**DropIt! nhấn mạnh:** (1) tập trung **theo khung giờ chung của nhóm**; (2) **minh bạch hai chiều**, thành viên biết trưởng phòng thấy gì; (3) **ghi nhận tích cực** bằng thành tích, Coins, trang trí profile; (4) báo cáo tự động cuối tháng. Nhóm nên tự dùng thử vài app tương tự trước khi đưa bảng này vào báo cáo.

## 6. Quyền riêng tư và minh bạch (nhạy cảm, cần làm kỹ)

Vì trưởng phòng được báo khi nhân viên rời app, đây là phần dễ gây phản ứng nhất. Nguyên tắc **(đề xuất)**:

- Chỉ ghi sự kiện "rời app trong phiên" và thời điểm; **không** đọc nội dung điện thoại, không biết người dùng mở app nào.
- Chỉ theo dõi **trong thời gian phiên**; ngoài phiên không ghi gì.
- Thành viên **xem được đúng dữ liệu mà trưởng phòng xem** về mình, và phải đồng ý rõ ràng khi tham gia nhóm.
- Có cách xử lý việc đột xuất: miễn trừ cuộc gọi công việc hoặc nút "tạm dừng có lý do", tránh phạt oan.
- Báo cáo nhằm khích lệ và hỗ trợ; công ty nên quy định rõ báo cáo có hay không dùng để đánh giá/kỷ luật.
- **Nhật ký riêng tư mặc định, trưởng phòng không đọc được.** Bài viết có nút báo cáo và kiểm duyệt.
- Cần tìm hiểu quy định bảo vệ dữ liệu cá nhân hiện hành của Việt Nam và nội quy của văn phòng, nên tham vấn người có chuyên môn trước khi dùng thật. Đây không phải tư vấn pháp lý.

## 7. Phạm vi sơ bộ **(đề xuất)**

Nhóm có 5 người và khoảng 4 sprint, lại còn rủi ro kỹ thuật ở phần phát hiện thoát app, nên mình đề xuất chia giai đoạn để không bị phình phạm vi.

| Giai đoạn | Nội dung |
| --- | --- |
| **MVP (lõi)** | Đăng nhập và vai trò (trưởng phòng/thành viên); tạo nhóm 4–10 người, mời thành viên; phiên + Lockdown + phát hiện thoát app + khoan hồng; **thông báo cho trưởng phòng**; điểm danh, chuỗi; Coins + Shop cơ bản (khung, hình nền); hồ sơ; **báo cáo tháng cơ bản**; nhật ký riêng tư đơn giản |
| **Giai đoạn sau** | Kết bạn, bảng tin bài viết (cần kiểm duyệt), xuất báo cáo nâng cao, nhiều văn phòng/công ty |
| **Ngoài phạm vi** | Cược điểm hoặc tiền, nạp Coins bằng tiền thật, theo dõi nội dung hoặc app đang dùng, xếp hạng công khai từng cá nhân |

## 8. Ràng buộc

| Ràng buộc | Nội dung |
| --- | --- |
| Nhóm | Bá Khí, 5 người |
| **Yêu cầu quan trọng nhất** | **Dùng tối thiểu 3 dịch vụ AWS, nhiều hơn càng tốt** |
| Thời gian | Dự kiến 4 sprint, cần xác nhận hạn nộp thật |
| Nền tảng di động | **Cần chốt:** iOS, Android hay cả hai |
| Thử nghiệm | Cần máy thật; app phụ thuộc vào hành vi hệ điều hành |
| Chi phí | Đặt hạn mức và cảnh báo ngân sách AWS từ ngày đầu |

**Dịch vụ AWS dự kiến, gắn với tính năng mới:**

| Tính năng | Dịch vụ |
| --- | --- |
| Server phiên thời gian thực | EC2 (Node.js + Socket.io), ALB |
| Dữ liệu cốt lõi (người dùng, nhóm, phiên, Coins, Shop) | RDS PostgreSQL |
| Trạng thái phiên đang chạy | ElastiCache (Redis) |
| Đăng nhập, phân quyền trưởng phòng/thành viên | Cognito (nhóm người dùng) |
| Thông báo cho trưởng phòng khi có người thoát | SNS (push) |
| Gửi báo cáo cuối tháng qua email | SES |
| Tạo báo cáo tháng, đặt lịch phiên, reset chuỗi | EventBridge + Lambda |
| Ảnh avatar, khung, hình nền, tệp báo cáo | S3 + CloudFront |
| Bài viết, nhật ký, bảng tin, log sự kiện | DynamoDB |
| Giám sát, cảnh báo | CloudWatch |
| Bí mật, tên miền, chứng chỉ | Secrets Manager, Route 53, ACM |

Như vậy vượt xa mức tối thiểu 3 dịch vụ, và mỗi dịch vụ có vai trò thật.

## 9. Ý tưởng đã cân nhắc, loại hoặc hoãn

| Ý tưởng | Quyết định | Lý do |
| --- | --- | --- |
| Cược điểm trong phiên | Bỏ (theo yêu cầu) | Không phù hợp môi trường văn phòng |
| Cược hoặc nạp bằng tiền thật | Loại | Rủi ro pháp lý và quy định store |
| Trưởng phòng xem app nhân viên đang dùng/màn hình | Loại | Xâm phạm riêng tư, không khả thi trên iOS |
| Bảng xếp hạng công khai từng cá nhân | Hoãn | Dễ gây áp lực và so sánh; nếu có thì xếp hạng nhóm hoặc tự nguyện |
| Phạt cả nhóm khi một người thoát | Không dùng làm mặc định | Dễ gây mâu thuẫn đồng nghiệp; chờ nhóm quyết định |
| Bảng tin công khai toàn công ty | Hoãn | Cần kiểm duyệt, ngoài phạm vi MVP |

## 10. Giả định và rủi ro lớn nhất

| # | Rủi ro | Cách giảm | Mức độ |
| --- | --- | --- | --- |
| 1 | Hệ điều hành không cho phát hiện thoát app đủ nhanh, đáng tin | Spike trên máy thật (đã có kế hoạch) | **Cao nhất** |
| 2 | Nhân viên thấy bị giám sát, phản đối | Minh bạch hai chiều, đồng ý rõ ràng, chỉ ghi trong phiên (mục 6) | Cao |
| 3 | Phát hiện nhầm, thông báo trưởng phòng oan | Khoan hồng, miễn trừ cuộc gọi, cho nhân viên giải trình | Cao |
| 4 | Phạm vi phình do tính năng xã hội | Chia giai đoạn (mục 7) | Cao |
| 5 | Tải dồn vào đầu giờ khi nhiều nhóm bắt đầu cùng lúc | Thử tải, mở rộng EC2 qua ALB | Trung bình |
| 6 | Nội dung bài viết không phù hợp | Báo cáo, kiểm duyệt, giới hạn người xem | Trung bình |
| 7 | Rò rỉ dữ liệu cá nhân và nhật ký | Phân quyền chặt, mã hóa, Secrets Manager | Trung bình |
| 8 | Chi phí AWS vượt dự tính | Ước tính ở giai đoạn thiết kế, cảnh báo ngân sách | Trung bình |

## 11. Tiêu chí thành công

**Với đồ án (đề xuất):**

- Demo: một trưởng phòng quản lý ít nhất 2 nhóm; một nhóm có số người trong khoảng 4–10 (có thể kết hợp máy thật và mô phỏng).
- Khi thành viên thoát app, trưởng phòng nhận thông báo trong vài giây.
- Báo cáo cuối tháng tạo tự động và gửi được qua email.
- Dùng đủ dịch vụ AWS theo yêu cầu, mỗi dịch vụ có vai trò rõ trong báo cáo.

**Với dùng thử thật (nếu văn phòng đồng ý):**

- Tỉ lệ phiên hoàn thành, số phiên mỗi người mỗi tuần, mức hài lòng của nhân viên và trưởng phòng qua khảo sát ngắn.

## 12. Cổng sang giai đoạn 2 (Yêu cầu)

- [ ] Cả nhóm Bá Khí đồng ý phạm vi MVP ở mục 7
- [ ] Đã chốt cách xử lý khi có người thoát (mục 13, câu 1)
- [ ] Đã chốt nền tảng di động và người phụ trách
- [ ] Đã xác nhận hạn nộp và yêu cầu AWS từ giảng viên
- [ ] Có bản quy tắc minh bạch và quyền riêng tư (mục 6) được cả nhóm đồng ý
- [ ] Đã hỏi ý kiến ít nhất vài đồng nghiệp trong văn phòng
- [ ] Đã lên lịch spike phát hiện thoát app

## 13. Câu hỏi mở cho nhóm

1. Khi một người thoát, phiên của những người còn lại **tiếp tục** (đề xuất) hay cả nhóm bị ảnh hưởng?
2. Ai bắt đầu phiên: trưởng phòng đặt lịch cố định, hay thành viên tự mở? (đề xuất: lịch do trưởng phòng đặt, kèm phiên tự do tính Coins)
3. Thông báo trưởng phòng: **ngay lập tức** hay gộp cuối phiên? (đề xuất: mặc định ngay lập tức, cho phép chọn gộp)
4. Một người có thể ở nhiều nhóm không? Có nhiều trưởng phòng hoặc nhiều văn phòng không?
5. Bài viết: nội dung gì, ai xem được (bạn bè hay cả văn phòng), có kiểm duyệt không?
6. Nhật ký chỉ riêng tư, hay có chia sẻ với bạn bè?
7. Nhóm làm iOS, Android hay cả hai, và hạn nộp là khi nào?
8. Nhân viên văn phòng của bạn có sẵn sàng dùng thử không?