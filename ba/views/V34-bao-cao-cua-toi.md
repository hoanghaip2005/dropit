# V-34 Báo cáo của tôi (dòng của mình)

Story: US-08.03 (Must), US-08.08 (Must); US-08.04 tổng nhóm (Should) · Quy tắc: BR-55, BR-57, BR-59, BR-61, BR-102, BR-103, BR-104, §Báo cáo §2 · Quyết định: D-11, D-12, D-21, D-22 · Q: Q-113, Q-137 · NFR: NFR-P03, NFR-P10, NFR-11 · Token: DESIGN.md

## Mục đích
Cho thành viên xem đúng dòng báo cáo tháng mà chủ nhóm thấy về mình, kèm mục đích sử dụng báo cáo.

## Vai trò
Thành viên (kể cả đã rời nhóm, trong thời hạn lưu 13 tháng — BR-103).

## Lối vào / lối ra
- Vào: V-19 "Báo cáo của tôi"; V-25 mục "Báo cáo tháng"; V-16 "Báo cáo tháng … đã sẵn sàng".
- Ra: chạm sự kiện rời app → V-15; quay lại.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Bộ chọn nhóm | Các nhóm có dòng của bạn trong kỳ (thường 1; 2 nếu đổi nhóm giữa tháng). Không có "Tất cả nhóm" | AC-08.03.2, D-21 |
| Bộ chọn kỳ | Tháng/năm, chỉ các kỳ có dòng của bạn | BR-103 |
| Khối mục đích | Thành phần V-35, đặt **đầu** báo cáo | US-08.08, AC-08.08.1 |
| Câu minh bạch | "Chủ nhóm thấy đúng các số dưới đây về bạn." | NFR-P03 |
| Ghi chú vào/rời | "Vào nhóm ngày dd/mm" / "Rời nhóm ngày dd/mm" | BR-59 |
| Bảng chỉ số | Mỗi dòng một chỉ số, tên đúng §2 | §Báo cáo §2 |
| — | Số ngày điểm danh (trong nhóm) | |
| — | Số phiên hoàn thành · Trong đó: hoàn thành có thưởng | D-11 |
| — | Tổng phút tập trung | |
| — | Số lần rời app | |
| — | Số lần gây mất thưởng tập thể | đề xuất Q-42 |
| — | Số phiên bị mất thưởng tập thể đã tham gia | |
| — | Số lần mất kết nối | |
| — | Số lần vắng · vào muộn (khi US-03.11) · tạm dừng (khi US-03.06) | |
| Sự kiện rời app | Danh sách: phiên, giờ server, giải trình (nhãn "thêm sau khi tạo báo cáo" nếu gửi sau) | BR-61, BR-102, NFR-P10 |
| Thời điểm tạo | "Tạo lúc 02:00 01/10. Số liệu không đổi sau khi tạo." | BR-56 |
| Tab "Tổng nhóm" *(US-08.04, Should)* | Ẩn khi chưa trong phạm vi; khi có: chỉ hiện nếu nhóm ≥ 5 thành viên lúc tạo | BR-104 |

API: `GET /me/reports?group_id=&period=` — chỉ trả dòng của người gọi (AC-08.03.3).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Như trên |
| Chưa có báo cáo nào (mới vào nhóm) | "Báo cáo đầu tiên sẽ có vào 01/‹mm›." (ngày 1 tháng sau tháng vào nhóm) |
| Kỳ có dòng nhưng không có phiên | Các số = 0; hai câu "Không có phiên nào trong kỳ" **(giả định)** |
| Đã rời nhóm | Vẫn xem các kỳ có dòng; nhãn "Bạn đã rời nhóm này" (AC-08.03.4) |
| Quá thời hạn lưu | Kỳ không còn trong bộ chọn; nếu mở từ liên kết cũ: "Báo cáo đã hết thời hạn lưu." |
| Đang tải | Khung xương |
| Lỗi | "Chưa tải được báo cáo." + "Thử lại" |
| Mất mạng | Bản đã lưu + "Chưa cập nhật" |

## Câu chữ chính
- "Báo cáo của tôi · ‹Tên nhóm› · Tháng ‹mm/yyyy›"
- "Chủ nhóm thấy đúng các số dưới đây về bạn."
- "Báo cáo đầu tiên sẽ có vào 01/‹mm›."
- "Tạo lúc ‹hh:mm dd/mm›. Số liệu không đổi sau khi tạo."
- "thêm sau khi tạo báo cáo"

## Điều cấm
- Không dòng, tên, chỉ số hay số lần thoát của người khác (AC-08.03.3, AC-08.03.5, Q-137).
- Không chuỗi, không tổng giờ huy hiệu, không Coins (D-12, BR-53, BR-61).
- Không xếp hạng, không "bạn cao hơn trung bình nhóm" (D-03).
- Không màn gộp nhiều nhóm (AC-08.03.2).
- Không sửa số liệu từ màn này; sửa sai chỉ qua giải trình (V-15).

## AC liên quan
AC-08.03.1, .2, .3, .4, .5; AC-08.08.1, .2, .3.
