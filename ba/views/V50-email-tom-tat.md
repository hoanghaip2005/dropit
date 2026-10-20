# V-50 Email tóm tắt báo cáo tháng

Story: US-08.07 (Must), US-08.08 (Must) · Quy tắc: BR-53, BR-57, BR-60, BR-105, §Báo cáo §3 · Quyết định: D-10, D-21, D-24 · NFR: NFR-17, NFR-P09 · Kênh: Amazon SES

## Mục đích
Báo cho chủ nhóm báo cáo tháng đã sẵn sàng, kèm tóm tắt **cấp nhóm**; chi tiết chỉ xem trong app.

## Vai trò
Người nhận: chủ nhóm của nhóm tại lúc tạo báo cáo (BR-57). Không gửi thành viên, không gửi quản trị (AC-08.07.4).

## Lối vào / lối ra
- Vào: email gửi ≤ 1 giờ sau khi tạo báo cáo (02:00 ngày 1).
- Ra: nút "Mở báo cáo trong app" → (đăng nhập nếu cần) → V-48 đúng nhóm, đúng kỳ (AC-08.07.7).

## Thân thư (mẫu)

| Phần | Nội dung | Nguồn |
| --- | --- | --- |
| Tiêu đề thư | "DropIt! — Báo cáo tháng mm/yyyy của nhóm ‹Tên nhóm›" | BR-105 |
| Mở đầu | "Báo cáo tháng mm/yyyy của nhóm ‹Tên nhóm› đã sẵn sàng." | BR-105 |
| Mục đích | "Mục đích sử dụng báo cáo: ‹nguyên văn lúc tạo›" (hoặc câu mặc định AC-08.08.3) | AC-08.08.1 |
| Tóm tắt | Số phiên đã diễn ra · Tỉ lệ hoàn thành phiên · Tỉ lệ hoàn thành có thưởng · Số phiên mất thưởng tập thể · So với tháng trước (tăng/giảm điểm %) | BR-105, §3 |
| Nút | "Mở báo cáo trong app" (link yêu cầu đăng nhập) | AC-08.07.7 |
| Chân thư | "Email này chỉ gửi cho chủ nhóm. Chi tiết từng thành viên chỉ xem trong app." | AC-08.07.4 |

Một email cho mỗi nhóm; chủ của 2 nhóm nhận 2 email, không gộp (AC-08.07.2).

## Trạng thái

| Trạng thái | Nội dung |
| --- | --- |
| Bình thường | Như mẫu |
| Kỳ không có phiên | Email ngắn: "Nhóm ‹Tên nhóm› không có phiên trong tháng mm/yyyy." + mục đích + nút mở app (BR-105, AC-08.09.1) |
| Không có tháng trước | Dòng so sánh: "Chưa có tháng trước để so sánh." (giả định) |
| Gửi lỗi | Thử lại tối đa 3 lần trong 24 giờ; vẫn lỗi → ghi "gửi thất bại", báo cáo vẫn xem trong app; không gửi người khác thay (AC-08.07.3) |
| Biên thời gian | Gửi ở phút 59 sau khi tạo: đạt; phút 61: không đạt NFR-17 (AC-08.07.5) |
| Mở link — chưa đăng nhập | Vào V-02, đăng nhập xong mở đúng báo cáo |
| Mở link — không phải chủ nhóm | 403 "Bạn không có quyền xem báo cáo nhóm này." (AC-08.07.7) |
| Mở link — mất mạng | App báo "Cần kết nối mạng để xem." |

## Điều cấm
- Không đính kèm, không link tải PDF (AC-08.07.6, D-24).
- Không dòng từng thành viên, không tên người thoát (AC-08.07.6).
- Không Coins, chuỗi (BR-53).
- Không số liệu nhóm khác, không gộp nhiều nhóm (D-21).
- Không ảnh theo dõi mở thư (tracking pixel) **(D-27)**.

## AC liên quan
AC-08.07.1 … .7; AC-08.08.1, .3; AC-08.09.1.
