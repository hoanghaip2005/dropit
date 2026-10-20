# V-45 Sửa / hủy lịch phiên

Story: US-02.11 (Must); US-02.10b lặp lại (Should) · Quy tắc: BR-02, BR-04, BR-29, BR-33, BR-65, BR-78, BR-79, BR-80, BR-108 · Quyết định: D-06, D-21, D-25 · Q: Q-29, Q-79 · Token: DESIGN.md

## Mục đích
Cho chủ nhóm đổi giờ / thời lượng hoặc hủy một phiên **chưa bắt đầu đếm ngược**; thành viên được báo thay đổi.

## Vai trò
Chủ nhóm của nhóm sở hữu phiên.

## Lối vào / lối ra
- Vào: V-46 (phiên ở SCHEDULED) "Sửa" / "Hủy phiên"; V-40 / V-41 danh sách phiên sắp tới.
- Ra: lưu / hủy thành công → V-46 hoặc danh sách, toast; "Bỏ" → màn trước.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Đầu màn | Tên lịch · nhóm · trạng thái "Đã lên lịch" | §2.1 SCHEDULED |
| Ngày | Bộ chọn ngày (giờ VN) | NFR-21 |
| Giờ bắt đầu | Bộ chọn giờ:phút; chú thích "Phiên bắt đầu đếm ngược 5 giây trước giờ này." | BR-04 |
| Thời lượng | Nút gạt viên thuốc 25 / 50 phút (không ô nhập số) | BR-02 |
| Coins tương ứng | Chú thích "25 phút: +10 Coins · 50 phút: +25 Coins cho mỗi thành viên hoàn thành có thưởng." | D-09 |
| Hạn sửa | "Sửa hoặc hủy được đến ‹hh:mm:ss› (trước khi đếm ngược)." = `started_at − 5s` | BR-04, BR-79 |
| Nút "Lưu thay đổi" | Đen | — |
| Nút "Hủy phiên" | Chữ `#BA1A1A` ở cuối | BR-29 |
| Hộp xác nhận hủy | "Hủy phiên ‹Tên lịch› lúc ‹hh:mm dd/mm›? Thành viên sẽ được báo. Không có dữ liệu nào được ghi." · "Hủy phiên" / "Giữ phiên" | AC-02.11.2 |
| Lựa chọn lặp *(US-02.10b, Should)* | "Chỉ lần này" / "Lần này và các lần sau" — ẩn khi chưa trong phạm vi | BR-79 |

API: `PATCH /sessions/{id}`, `POST /sessions/{id}/cancel` — server kiểm tra trạng thái SCHEDULED theo giờ server tại lúc nhận (BR-33).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Biểu mẫu với giá trị hiện tại |
| Đã COUNTDOWN / ACTIVE / COMPLETED | Mọi trường khóa; dải: "Phiên đã bắt đầu — không sửa hoặc hủy được." (AC-02.11.3); không có nút "Hủy phiên" |
| Bấm lưu sát giờ, server đã sang COUNTDOWN | "Phiên vừa bắt đầu đếm ngược — thay đổi không được lưu." (AC-02.11.4: 08:59:54,999 được; 08:59:55,000 từ chối) |
| Giờ mới < giờ server + 1 phút | Dưới ô giờ: "Giờ bắt đầu phải sau thời điểm hiện tại ít nhất 1 phút." (AC-02.11.5, BR-79) |
| Trùng phiên khác của nhóm | "Trùng phiên khác của nhóm (‹Tên lịch› ‹hh:mm–hh:mm›)." (BR-78) — chỉ kiểm trong nhóm này |
| Nhóm TẠM NGƯNG LỊCH / CHỜ GIẢI TÁN | Không cho lưu giờ mới; "Nhóm đang ‹trạng thái› — không đổi lịch được." (BR-108, BR-80) |
| Đang lưu | Nút "Đang lưu…" khóa |
| Lỗi mạng | "Chưa lưu được. Lịch cũ vẫn giữ nguyên." + "Thử lại" |
| Đang tải | Khung xương |
| Rỗng | Không áp dụng |

## Câu chữ chính
- "Sửa hoặc hủy được đến ‹hh:mm:ss›."
- "Phiên đã bắt đầu — không sửa hoặc hủy được."
- "Giờ bắt đầu phải sau thời điểm hiện tại ít nhất 1 phút."
- "Trùng phiên khác của nhóm."
- Toast: "Đã lưu. Thành viên đã được báo." / "Đã hủy phiên. Thành viên đã được báo."

## Điều cấm
- Không dừng, kéo dài, kết thúc sớm phiên đã bắt đầu (BR-29, BR-116).
- Không thời lượng khác 25/50 (BR-02).
- Không kiểm/cảnh báo trùng lịch với nhóm khác, kể cả nhóm cùng chủ (BR-78, BR-114 c).
- Không ô "tham gia phiên" cho chủ nhóm (D-25).
- Không cược, thưởng thêm, "bounty" khi đặt lịch (D-01).

## AC liên quan
AC-02.11.1, .2, .3, .4, .5; AC-02.10.8 (trạng thái nhóm); AC-02.10b.2, .3, .5 (Should).
