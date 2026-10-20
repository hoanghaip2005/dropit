# V-16 Hộp thông báo và mẫu push

Story: US-04.01 (Must), US-03.09 (Must), US-04.06 (AC-04.06.2), US-05.05 (AC-05.05.1), US-02.08 (AC-02.08.1), US-01.07 (AC-01.07.1), US-02.11 · Quy tắc: BR-27, BR-28, BR-38, BR-39, BR-81, BR-82, BR-85, BR-91, BR-77, BR-29 · Quyết định: D-20, D-22, D-25 · NFR: NFR-01, NFR-P18 · Token: DESIGN.md

## Mục đích
Một nơi lưu mọi thông báo gửi cho người dùng (push hay không, BR-81), và bộ mẫu câu push thống nhất. Phía thành viên ngoài phiên và chủ nhóm nhận `MEMBER_EXITED` tại đây.

## Vai trò
Mọi người dùng đã đăng nhập. Nội dung phụ thuộc vai trò trong từng nhóm.

## Lối vào / lối ra
- Vào: biểu tượng chuông ở V-03/V-40 (có số chưa đọc); chạm push hệ thống.
- Ra: chạm mục → màn đích (bảng dưới). Không có thao tác xóa ở MVP **(giả định)**.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Danh sách | Mới nhất trước; mỗi mục: biểu tượng loại, câu chính, tên nhóm, thời điểm (giờ server, UTC+7), chấm "chưa đọc" | `GET /me/notifications?cursor=` |
| Mục rời app | Biểu tượng + nhãn "Rời phiên" chữ `#BA1A1A` (được phép: cảnh báo thoát) | DESIGN.md |
| Đánh dấu đã đọc | Khi chạm mục; nút "Đánh dấu tất cả đã đọc" | — |
| Phân trang | Tải thêm khi cuộn | — |

## Mẫu thông báo

Tiêu đề push luôn: "DropIt! · ‹Tên nhóm›". Giờ là giờ server.

| Mã sự kiện | Người nhận | Kênh | Thân thông báo | Chạm → |
| --- | --- | --- | --- | --- |
| `MEMBER_EXITED` + `SESSION_FORFEITED` (người thoát đầu tiên) | Cả nhóm (kể cả chủ nhóm, người không tham gia) + người trong phiên, trừ người thoát (BR-27) | Push + hộp (người ngoài phiên); banner V-11 + hộp (người trong phiên, BR-82) | "‹Tên› đã rời phiên ‹Tên lịch› lúc ‹hh:mm:ss›. Phiên đã mất thưởng tập thể — vẫn tiếp tục đến hết giờ." | Chủ nhóm: V-46. Thành viên: không có màn chi tiết người khác — mở V-03 (phiên đang chạy) hoặc V-14 sau `ends_at` |
| `MEMBER_EXITED` (người thoát tiếp theo) | Như trên | Như trên | "‹Tên› đã rời phiên ‹Tên lịch› lúc ‹hh:mm:ss›." | Như trên |
| `SESSION_RESULT` | Từng thành viên có trạng thái trong phiên | Push sau `ends_at` + hộp | Có thưởng: "Phiên ‹Tên lịch› đã kết thúc: +N Coins." · Mất thưởng: "Phiên ‹Tên lịch› mất thưởng tập thể — chuỗi bị ngắt." (BR-91, đề xuất Q-93) · Mất kết nối: "Phiên ‹Tên lịch› đã kết thúc: Mất kết nối — 0 Coins." · Vắng: "Bạn đã vắng phiên ‹Tên lịch›." | V-12 / V-13 / V-14 |
| Giải trình mới | Chủ nhóm | **Chỉ hộp** (không push, BR-85) | "‹Tên› đã gửi giải trình cho lần rời phiên ‹Tên lịch› lúc ‹hh:mm:ss›." | V-47 |
| Huy hiệu mới | Chính người dùng | **Chỉ trong app** (Q-95) | "Bạn nhận huy hiệu ‹Tên huy hiệu›." | V-27 / V-26 |
| Lịch thay đổi | Thành viên nhóm | Push + hộp | "Phiên ‹Tên lịch› đổi sang ‹hh:mm dd/mm›, ‹25/50› phút." | V-03 |
| Lịch bị hủy | Thành viên nhóm | Push + hộp | "Phiên ‹Tên lịch› lúc ‹hh:mm dd/mm› đã bị hủy." | V-03 |
| Bị xóa khỏi nhóm | Người bị xóa | Push + hộp | "Bạn không còn trong nhóm ‹Tên nhóm›." (BR-77) | V-19 |
| Thành viên rời nhóm | Chủ nhóm | Hộp **(giả định)** | "‹Tên› đã rời nhóm." — không lý do (04 §2) | V-20 |
| Báo cáo tháng sẵn sàng | Chủ nhóm; thành viên **(giả định)** | Hộp | "Báo cáo tháng ‹mm/yyyy› của ‹Tên nhóm› đã sẵn sàng." | V-48 / V-34 |
| `SESSION_CANCELLED_OUTAGE` *(Should)* | Cả phiên + chủ nhóm | Push + hộp | "Phiên ‹Tên lịch› đã hủy do sự cố hệ thống. Không ai bị tính." | V-14 (E) / V-46 |

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Danh sách |
| Rỗng | "Chưa có thông báo nào." |
| Đang tải | Khung xương 5 dòng |
| Lỗi | "Chưa tải được thông báo." + "Thử lại" |
| Mất mạng | Bản đã lưu + nhãn "Chưa cập nhật" |
| Đã tắt quyền thông báo hệ thống | Dải trên đầu: "Bạn đã tắt thông báo của DropIt!. Thông báo vẫn có ở đây." (không mở Cài đặt tự động) (AC-04.01.6) |

## Câu chữ chính
Như cột "Thân thông báo".

## Điều cấm
- Không tên app khác, lý do tạm dừng, giải trình, Coins, số lần thoát tích lũy trong thông báo về người khác (BR-27, NFR-P18).
- Không thông báo cho người khác khi ai đó LOST / PAUSED / WITHDRAWN / ABSENT (Q-136).
- Không push hệ thống cho người đang có trạng thái chưa kết thúc trong phiên (BR-82); không push về Coins/chuỗi/huy hiệu trong lúc phiên chạy (BR-91).
- Không chế độ gộp cuối phiên (D-20); không cài đặt "tắt thông báo người thoát" ở MVP.
- Chủ nhóm không nhận Coins/chuỗi của thành viên qua thông báo (BR-53).
- Thông báo của nhóm A không gửi cho người chỉ là chủ nhóm B (AC-04.01.10).

## AC liên quan
AC-04.01.1, .3, .6, .7, .8, .9, .10, .11; AC-03.09.1, .3, .10; AC-04.06.2; AC-05.05.1; AC-02.08.1; AC-01.07.1; AC-02.11.1, .2.
