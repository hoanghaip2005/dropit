# V-11 Banner người thoát (phía thành viên đang trong phiên)

Story: US-03.09 (Must), US-03.08 (Must), US-04.01 (AC-04.01.2, .3, .7) · Quy tắc: BR-27, BR-35, BR-38, BR-39, BR-81, BR-82, §3 #46, #47 · Quyết định: D-05, D-20, D-22 · NFR: NFR-02, NFR-P06, NFR-P18 · Token: DESIGN.md

## Mục đích
Cho người đang ở màn phiên biết ngay, kèm tên, khi một người khác thoát và phiên đã mất thưởng tập thể; không làm họ rời app, không chặn thao tác.

## Vai trò
Thành viên có trạng thái chưa kết thúc trong phiên (WAITING/FOCUSING/GRACE/PAUSED/DISCONNECTED). Người ngoài phiên và chủ nhóm nhận qua V-16 (push + hộp thông báo).

## Lối vào / lối ra
- Vào: socket phiên giao `MEMBER_EXITED` (kèm `SESSION_FORFEITED` nếu là người khởi phát).
  - App ở tiền cảnh, màn hình mở → hiện ngay trên V-08.
  - Đang khóa màn hình / GRACE / PAUSED → xếp hàng, hiện khi mở khóa hoặc quay lại app (BR-82).
- Ra: tự ẩn sau 6 giây **(giả định)**, hoặc người dùng vuốt ẩn. Không mở màn khác. Bản lưu ở V-16.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Vị trí | Dải trên cùng V-08, không che đồng hồ phiên và chỉ báo "Phiên đang được ghi" | BR-82 |
| Khung | Nền `#000000`, viền `#5C5C5C` 1px, bo 24px; chữ trắng `body-lg`; biểu tượng tĩnh | DESIGN.md; VQ-05 |
| Xuất hiện / biến mất | Hiện và ẩn tức thì, **không** trượt/mờ dần | Lockdown tĩnh (DESIGN.md) |
| Âm thanh / rung | Không | BR-82 |
| Nội dung — người thoát đầu tiên | "‹Tên A› đã rời phiên lúc 09:10:03. Phiên đã mất thưởng tập thể — vẫn tiếp tục đến hết giờ." (một banner, không phải hai) | `MEMBER_EXITED` + `SESSION_FORFEITED`, BR-38, AC-04.01.2 |
| Nội dung — người thoát tiếp theo | "‹Tên B› đã rời phiên lúc 09:15:40." | BR-39, AC-03.09.5 |
| Dòng trạng thái phiên (cố định sau banner) | Nhãn nhỏ dưới đồng hồ: "Phiên đã mất thưởng tập thể" (`lockdown-text-secondary #A1A1A6`) giữ đến hết phiên | BR-35 (cờ một chiều) |
| Nhắc tiếp tục | Dòng phụ trong banner đầu tiên: "Bạn vẫn hoàn thành phiên nếu ở lại đến hết giờ." | D-11 |
| Xếp hàng nhiều banner | Hiện lần lượt, mỗi banner ≤ 6 giây; nếu ≥3 đang chờ: gộp "‹A›, ‹B› và 1 người khác đã rời phiên." **(giả định)** | BR-82 |
| Giờ | Giờ server, hh:mm:ss, Asia/Ho_Chi_Minh | BR-03, NFR-21 |

Payload: `{type, session_id, actor_display_name, exited_at, forfeited, forfeited_by_display_name}`. Không có trường khác (AC-03.09.2).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Banner ≤ 2 giây (p95) sau khi server phát (NFR-02) |
| Đang khóa màn hình / GRACE / PAUSED | Không gì trên màn khóa; banner hiện ≤ 2 giây sau khi mở khóa/quay lại (AC-03.09.9) |
| Đang tải / rỗng | Không áp dụng |
| Lỗi — socket mất | Banner không tới; khi nối lại, server gửi lại các thông báo chưa giao; luôn có bản ở V-16 (BR-81) |
| Mất mạng | Theo V-10; banner xếp hàng đến khi nối lại |
| Bản thân là người thoát | Không nhận banner về chính mình (AC-03.09.8); xem V-13 |
| Sự cố hủy phiên sau đó | Dòng "Phiên đã mất thưởng tập thể" thay bằng "Phiên đã hủy do sự cố" *(US-03.12, Should; AC-03.12.6)* |

## Câu chữ chính
- "‹Tên› đã rời phiên lúc ‹hh:mm:ss›. Phiên đã mất thưởng tập thể — vẫn tiếp tục đến hết giờ."
- "‹Tên› đã rời phiên lúc ‹hh:mm:ss›."
- "Bạn vẫn hoàn thành phiên nếu ở lại đến hết giờ."
- "Phiên đã mất thưởng tập thể"

## Điều cấm
- Không tên app, lý do tạm dừng, giải trình, Coins, số lần thoát tích lũy của người thoát (BR-27, BR-34, NFR-P06, NFR-P18).
- Không banner cho LOST, PAUSED, WITHDRAWN, ABSENT, GRACE đã hồi phục (AC-03.09.12, Q-136).
- Không push hệ thống, không thông báo cục bộ trên màn khóa cho người đang trong phiên (BR-82).
- Không từ ngữ phán xét ("vi phạm", "phá phiên", "lỗi của") — câu trung tính (R-P12).
- Không nút hành động (nhắn tin, "nhắc", báo cáo người thoát).
- Không màu đỏ cho chữ trên nền đen (3.25:1, VQ-05).

## AC liên quan
AC-03.09.1, .2, .5, .6, .8, .9, .12; AC-03.08.1, .2, .5; AC-04.01.2, .3, .7.
