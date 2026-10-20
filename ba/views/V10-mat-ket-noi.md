# V-10 Mất kết nối / LOST

Story: US-03.07 (Must) · Quy tắc: BR-19, BR-20, BR-21, BR-36, BR-48, BR-65, BR-66, §3 #1, #2, #7, #40–#43 · Quyết định: D-08, D-19 · NFR: NFR-23, NFR-P18 · Token: DESIGN.md

## Mục đích
Báo người dùng app đang mất liên lạc với server và đang thử nối lại, không làm họ hoảng mà rời app. Khi quá hạn giữ chỗ, giải thích rằng chỉ họ không nhận Coins; phiên của nhóm không bị ảnh hưởng.

## Vai trò
Thành viên đang FOCUSING/PAUSED (DISCONNECTED) hoặc đã LOST.

## Lối vào / lối ra
- Vào: client mất socket hoặc không gửi được heartbeat khi đang ở V-08 → lớp phủ V-10 trên V-08 (không chuyển màn).
- Ra:
  - Nối lại, server trả trạng thái trước (FOCUSING/PAUSED) → bỏ lớp phủ, về V-08 (AC-03.07.2).
  - Nối lại, server trả LOST → V-14 biến thể "Mất kết nối" (sau `ends_at`) hoặc khối LOST ngay trên V-08 nếu phiên còn chạy.
  - Nối lại sau `ends_at` mà còn trong hạn → V-12/V-14 (COMPLETED, phút tính đến `disconnected_at`, AC-03.07.8).

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Lớp phủ trên nền đen | Khung viền `#5C5C5C` (≥3:1), chữ trắng; không đổi màu nhấp nháy | DESIGN.md; VQ-05 (không dùng chữ đỏ trên đen) |
| Biểu tượng mạng | Biểu tượng tĩnh + nhãn chữ (không chỉ dựa vào màu) | NFR-20 |
| Dòng chính | "Đang kết nối lại…" | US-03.07 ghi chú (giả định) |
| Dòng giải thích | "Ở lại trong app. Mất mạng không tính là rời app. Nếu không kết nối lại kịp, chỉ bạn không nhận Coins phiên này; cả nhóm không bị ảnh hưởng." | D-19, BR-21 |
| Đồng hồ còn lại của phiên | Giữ hiển thị thời gian còn lại theo `ends_at` đã nhận | BR-03 |
| Chỉ báo ghi | Giữ "Phiên đang được ghi" (server vẫn đang theo dõi phiên) | NFR-P08 |
| Không có đếm "giữ chỗ còn N giây" | Client không biết `disconnected_at` của server **(đề xuất, VQ-03)** | BR-19 mục 3 |
| Khối LOST (khi nối lại và server trả LOST, phiên còn chạy) | "Bạn đã mất kết nối quá lâu. Phiên của bạn đã kết thúc: Mất kết nối — 0 Coins. Phiên của nhóm vẫn tiếp tục và không bị ảnh hưởng." Nút "Về trang chủ" | BR-21, BR-32, D-19 |
| Socket | Kết nối lại gửi `session_id`; server trả `{state, ends_at}` | BR-20 |

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường (DISCONNECTED, đang thử) | Lớp phủ "Đang kết nối lại…", thử lại tự động; không nút bấm |
| Nối lại thành công trong hạn | Lớp phủ biến mất ngay (không hoạt ảnh); về V-08 đúng trạng thái trước |
| LOST, phiên còn chạy | Khối LOST như trên; chỉ báo ghi tắt (AC-03.03.3) |
| LOST, sau `ends_at` | V-14 biến thể "Mất kết nối" |
| Nối lại khi đang GRACE | Không phải ca của màn này: GRACE vẫn chạy trên server (§3 #1); client hiện V-09 hoặc V-13 theo kết quả server |
| Đã báo khóa màn hình | Không hiện V-10 khi mở khóa nếu server chưa coi là DISCONNECTED (BR-66, AC-03.07.9) |
| Đang tải | Là chính trạng thái "Đang kết nối lại…" |
| Rỗng | Không áp dụng |
| Lỗi — sự cố server được xác nhận | "Phiên đã hủy do sự cố hệ thống. Kết quả của bạn không bị tính." *(US-03.12, Should)* |

## Câu chữ chính
- "Đang kết nối lại…"
- "Ở lại trong app. Mất mạng không tính là rời app."
- "Nếu không kết nối lại kịp, chỉ bạn không nhận Coins phiên này; cả nhóm không bị ảnh hưởng."
- LOST: "Mất kết nối — 0 Coins. Phiên của nhóm vẫn tiếp tục và không bị ảnh hưởng."
- LOST, chuỗi: "Chuỗi của bạn giữ nguyên." — **chỉ** khi phiên không `forfeited` (BR-48, đề xuất Q-27). Nếu phiên đã `forfeited` do người khác: "Phiên đã mất thưởng tập thể do ‹Tên› rời phiên — chuỗi của bạn bị ngắt." (BR-37, §3 #24)

## Điều cấm
- Không gọi LOST là "thoát", "rời app", "vi phạm" (D-19, NFR-P18).
- Không thông báo cho ai khác về việc người này mất mạng / LOST (BR-21, Q-136).
- Không gợi ý "mở Cài đặt Wi-Fi" bằng liên kết rời app (rời app trong lúc đã nối lại sẽ thành GRACE).
- Không hiện đồng hồ giữ chỗ do client tự tính (VQ-03).
- Không thông báo đẩy hệ thống về mất kết nối.

## AC liên quan
AC-03.07.1, .2, .3, .4, .5, .6, .7, .8, .9, .10; AC-03.03.3; AC-03.09.12.
