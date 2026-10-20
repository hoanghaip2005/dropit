# Tài liệu tổng quát: Quy trình làm một ứng dụng

Dùng cho nhóm làm app di động có backend và cloud. Áp dụng được cho đồ án môn học lẫn sản phẩm thật.

## 1. Vòng đời làm một app

```
Ý tưởng → Yêu cầu → Thiết kế → Phát triển → Kiểm thử → Phát hành → Vận hành → Đóng dự án
              ↑________________ lặp lại theo sprint ________________↓
```

Thực tế không đi một chiều: nhóm lặp lại các bước theo từng sprint (1–2 tuần), mỗi sprint cho ra một bản chạy được.

| Giai đoạn | Mục tiêu | Việc chính | Đầu ra |
| --- | --- | --- | --- |
| 1. Ý tưởng | Biết app giải quyết vấn đề gì cho ai | Xác định người dùng, nỗi đau, đối thủ, điểm khác biệt | Tầm nhìn 1 trang, danh sách ý tưởng đã loại |
| 2. Yêu cầu | Thống nhất làm gì và không làm gì | Viết user story, chọn MVP, quy tắc nghiệp vụ | Đặc tả yêu cầu (SRS), Product Backlog |
| 3. Thiết kế | Biết làm như thế nào trước khi code | Luồng người dùng, wireframe, kiến trúc, CSDL, API | Bản thiết kế UI, sơ đồ kiến trúc, ERD, đặc tả API |
| 4. Phát triển | Biến thiết kế thành sản phẩm chạy được | Code theo sprint, review, tích hợp liên tục | Bản build chạy được mỗi sprint |
| 5. Kiểm thử | Tìm lỗi trước khi người dùng thấy | Test chức năng, tích hợp, hiệu năng, bảo mật | Kế hoạch test, báo cáo lỗi, kết quả test |
| 6. Phát hành | Đưa app đến tay người dùng | Build bản release, nộp store, cấu hình production | Bản phát hành, trang store, Privacy Policy |
| 7. Vận hành | Giữ app chạy ổn, sửa lỗi, cải tiến | Giám sát, xử lý sự cố, thu thập phản hồi | Runbook, báo cáo sự cố, backlog cải tiến |
| 8. Đóng dự án | Tổng kết và bàn giao | Rút kinh nghiệm, lưu tài liệu, báo cáo cuối | Báo cáo tổng kết, tài liệu bàn giao |

**Cổng chuyển giai đoạn:** chỉ sang bước sau khi bước trước có đầu ra được cả nhóm đồng ý. Ví dụ không code khi chưa chốt MVP và chưa có thiết kế cho các màn hình lõi.

## 2. Vai trò trong nhóm

| Vai trò | Trách nhiệm chính |
| --- | --- |
| Trưởng nhóm / Product Owner | Giữ tầm nhìn, quyết định ưu tiên, nhận bàn giao |
| Thiết kế UI/UX | Luồng, wireframe, design system |
| Mobile (iOS/Android) | Giao diện, logic phía client, tích hợp API |
| Backend | API, nghiệp vụ, CSDL, bảo mật |
| Cloud/DevOps | Hạ tầng, CI/CD, giám sát, chi phí |
| Kiểm thử (QA) | Test case, chạy test, báo lỗi |
| Quản trị (Admin/Web) | Trang quản trị, công cụ vận hành |

Nhóm nhỏ thường kiêm nhiều vai trò. Điều quan trọng là **mỗi việc có một người chịu trách nhiệm chính**, dù người khác cùng làm.

## 3. Bộ tài liệu cần có

| Nhóm | Tài liệu | Ghi chú |
| --- | --- | --- |
| Quản lý | Tầm nhìn & phạm vi, kế hoạch/sprint, backlog, bảng phân công, sổ rủi ro | Cập nhật mỗi sprint |
| Yêu cầu | SRS, user story, quy tắc nghiệp vụ | Là nguồn sự thật cho cả nhóm |
| Thiết kế | User flow, wireframe/mockup, design system | Làm trước khi code màn hình |
| Kỹ thuật | Kiến trúc, ERD, đặc tả API, sơ đồ trạng thái/sequence, tài liệu bảo mật | Backend và mobile cùng thống nhất |
| Hạ tầng | Tài liệu cloud, CI/CD, môi trường, ước tính chi phí | Kèm cảnh báo ngân sách |
| Kiểm thử | Kế hoạch test, test case, báo cáo | Sinh ra từ tiêu chí chấp nhận |
| Phát hành | Privacy Policy, điều khoản, nội dung store, release notes | Store bắt buộc Privacy Policy |
| Vận hành | Runbook, hướng dẫn giám sát, README | Để người mới vào chạy được |

## 4. Mẫu nhanh

**Tầm nhìn 1 trang:** vấn đề, người dùng mục tiêu, giải pháp, 3–5 tính năng cốt lõi, ngoài phạm vi, tiêu chí thành công, ràng buộc (thời gian, người, ngân sách, yêu cầu của môn học).

**User story:**

> Là một *\[vai trò\]*, tôi muốn *\[việc cần làm\]* để *\[lợi ích\]*. Tiêu chí chấp nhận: *\[điều kiện kiểm tra được, có ca bình thường và ca lỗi\]*.

**Định nghĩa "Hoàn thành" (Definition of Done):** code đã review, có test, chạy trên thiết bị thật, không lỗi nghiêm trọng, tài liệu liên quan đã cập nhật, đã merge vào nhánh chính.

**Ưu tiên MVP (MoSCoW):** Must (bắt buộc), Should (nên có), Could (có thể có), Won't (không làm lần này). MVP chỉ gồm Must.

## 5. Kiến trúc điển hình của một app có backend

```
[App di động] ⇄ [Cân bằng tải / API Gateway] ⇄ [Server ứng dụng]
                                                  ├─ CSDL quan hệ (dữ liệu lâu dài)
                                                  ├─ Bộ nhớ đệm (dữ liệu nóng, thời gian thực)
                                                  ├─ Lưu trữ tệp (ảnh, tài nguyên)
                                                  ├─ Xác thực người dùng
                                                  ├─ Thông báo đẩy
                                                  └─ Tác vụ theo lịch / hàng đợi
                         Giám sát, log, cảnh báo bao quanh tất cả
```

**Câu hỏi nên trả lời khi chọn công nghệ:**

1. Có cần thời gian thực không? (WebSocket hay REST là đủ)
2. Dữ liệu có quan hệ chặt và cần transaction không? (SQL hay NoSQL)
3. Cần đăng nhập mạng xã hội không? (tự viết hay dùng dịch vụ có sẵn)
4. Dự kiến bao nhiêu người dùng đồng thời? (quyết định cần mở rộng hay không)
5. Nhóm đã quen công nghệ nào? (ưu tiên cái nhóm làm chắc)
6. Ngân sách hàng tháng tối đa là bao nhiêu?

**Khi dự án yêu cầu dùng dịch vụ cloud (ví dụ AWS):** ánh xạ từng thành phần ở sơ đồ trên sang một dịch vụ và ghi rõ **lý do dùng**. Ví dụ máy chủ → EC2, CSDL → RDS, bộ nhớ đệm → ElastiCache, tệp → S3, xác thực → Cognito, thông báo → SNS, tác vụ theo lịch → EventBridge + Lambda, giám sát → CloudWatch. Mỗi dịch vụ nên có việc thật, không thêm chỉ để đủ số lượng.

## 6. Cách làm việc nhóm

- **Scrum nhẹ:** sprint 1–2 tuần; họp lập kế hoạch đầu sprint, họp ngắn hằng ngày hoặc vài lần mỗi tuần, demo và rút kinh nghiệm cuối sprint.
- **Kanban:** bảng Việc cần làm → Đang làm → Đang review → Xong, giới hạn số việc đang làm mỗi người.
- **Git:** nhánh `main` luôn chạy được, nhánh `develop` hoặc nhánh tính năng cho từng việc, Pull Request bắt buộc có người review, tên nhánh và commit rõ ràng.
- **CI/CD:** tự động build và chạy test khi có Pull Request, tự động triển khai lên môi trường thử.
- **Môi trường:** tách `dev`, `staging`, `production`; không dùng dữ liệu thật để thử nghiệm.
- **Giao tiếp:** một kênh chính cho nhóm, một nơi duy nhất lưu tài liệu, ghi lại quyết định quan trọng kèm lý do.

## 7. Chất lượng

| Khía cạnh | Việc cần làm |
| --- | --- |
| Chức năng | Test theo user story, cả ca bình thường lẫn ca lỗi |
| Tích hợp | Thử client với server thật, thử mất mạng, đổi mạng |
| Thiết bị | Thử trên máy thật, nhiều hãng và nhiều phiên bản hệ điều hành |
| Hiệu năng | Đo thời gian phản hồi, thử tải số người dùng đồng thời |
| Bảo mật | Xác thực, phân quyền, mã hóa đường truyền, không để khóa bí mật trong code, kiểm tra dữ liệu đầu vào |
| Pin & dữ liệu | Hạn chế tác vụ nền, gọi mạng không cần thiết |
| Khả năng tiếp cận | Cỡ chữ, độ tương phản, nhãn cho trình đọc màn hình |

## 8. Pháp lý & phát hành lên store

- Privacy Policy và Điều khoản sử dụng (bắt buộc với store).
- Khai báo dữ liệu thu thập (Apple App Privacy, Google Data Safety).
- Chỉ xin quyền thật sự cần, giải thích rõ lý do cho người dùng.
- Chuẩn bị: icon, ảnh chụp màn hình, mô tả, phân loại độ tuổi, tài khoản tester.
- Thử qua TestFlight (iOS) và bản kiểm thử nội bộ (Android) trước khi công khai.
- Quy định của store thay đổi theo thời gian, nên đọc hướng dẫn mới nhất trước khi nộp.

## 9. Rủi ro & chi phí

**Rủi ro thường gặp:** phạm vi phình to, hạn chế kỹ thuật của hệ điều hành chưa được thử sớm, phụ thuộc vào một người, lệch giữa client và server, vượt ngân sách cloud, thiếu thời gian kiểm thử.

**Cách giảm:**

- Làm các việc rủi ro cao nhất trước (spike/PoC) trong sprint đầu.
- Chốt MVP sớm, mọi thay đổi phạm vi phải qua trưởng nhóm.
- Mỗi mảng có ít nhất hai người hiểu.
- Thống nhất hợp đồng API và sự kiện trước khi hai bên cùng code.
- Đặt cảnh báo ngân sách cloud từ ngày đầu, tắt tài nguyên không dùng.

## 10. Checklist trước khi phát hành

- [ ] Tất cả user story Must đã xong và qua tiêu chí chấp nhận
- [ ] Không còn lỗi nghiêm trọng, danh sách lỗi nhỏ đã được chấp nhận
- [ ] Đã thử trên máy thật, nhiều hãng và phiên bản
- [ ] Đã thử mất mạng, kết nối lại, dữ liệu rỗng, dữ liệu lớn
- [ ] Không còn khóa bí mật hay mật khẩu trong mã nguồn
- [ ] Môi trường production tách riêng, có sao lưu cơ sở dữ liệu
- [ ] Có giám sát và cảnh báo, có người trực trong lúc ra mắt
- [ ] Privacy Policy, điều khoản, khai báo dữ liệu đã sẵn sàng
- [ ] Nội dung store đầy đủ
- [ ] Có kế hoạch quay lui nếu bản phát hành lỗi
- [ ] README và runbook đã cập nhật

## 11. Lỗi thường gặp của nhóm mới

1. Vào code ngay khi chưa chốt phạm vi.
2. Làm quá nhiều tính năng nhưng không tính năng nào hoàn chỉnh.
3. Để đến cuối mới kiểm thử và mới thử trên máy thật.
4. Mỗi người hiểu yêu cầu một kiểu vì không có tài liệu chung.
5. Không ghi lại quyết định, sau đó cãi nhau về điều đã chốt.
6. Quên chi phí cloud, đến cuối tháng mới biết.
7. Dồn việc tài liệu và báo cáo vào tuần cuối.

## 12. Lộ trình gợi ý cho nhóm 5 người, 4 sprint

| Sprint | Trọng tâm | Kết quả cần có |
| --- | --- | --- |
| 1 | Chốt phạm vi, thiết kế lõi, dựng hạ tầng, thử rủi ro kỹ thuật cao nhất | Tài liệu yêu cầu và kiến trúc, bản PoC chạy được |
| 2 | Xây tính năng lõi từ đầu đến cuối | Luồng chính chạy được trên máy thật |
| 3 | Hoàn thiện tính năng phụ, giao diện, tích hợp dịch vụ cloud còn lại | Bản gần đầy đủ, có dữ liệu thật để thử |
| 4 | Kiểm thử, sửa lỗi, tối ưu, tài liệu, phát hành bản thử | Bản phát hành, báo cáo và slide tổng kết |