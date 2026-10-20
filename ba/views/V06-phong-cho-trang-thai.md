# V-06 Phòng chờ — bổ sung trạng thái

Story: US-03.01 (Must) · Quy tắc: BR-01, BR-02, BR-06, BR-08, BR-29, BR-114, BR-118 · Quyết định: D-05, D-06, D-08, D-09, D-25 · NFR: NFR-P02, NFR-P04 · Token: DESIGN.md
Bổ sung cho `mockup/session_lobby_1`, `mockup/session_lobby_2` (đã sửa đợt 1). Tệp này thêm trạng thái lỗi/biên và chốt cách hiện người trong phòng.

## Mục đích
Thành viên vào phòng chờ trước giờ bắt đầu, thấy thời lượng, giờ bắt đầu (giờ server), thưởng dự kiến và luật rời app.

## Vai trò
Thành viên đã đồng ý điều khoản hiện hành. Chủ nhóm: không có nút vào (AC-03.01.3).

## Lối vào / lối ra
- Vào: V-03 "Vào phòng chờ"; V-18 (Should).
- Ra: đến `started_at − 5s` → V-07; nút "Rời phiên" → hộp xác nhận "bạn sẽ bị ghi vắng" → "Xác nhận": ABSENT, không phạt (không `MEMBER_EXITED`, không `forfeited`) → V-03; "Hủy": ở lại V-06; mất kết nối → báo "Chưa rời phiên — không có kết nối", không xếp hàng (BR-118 (2)(3), AC-03.04.9, AC-03.04.10 (a), giả định Q-149); phiên bị hủy → V-03.

## Thành phần
| Phần tử | Dữ liệu | Nguồn |
| --- | --- | --- |
| Đầu màn | Tên lịch · thời lượng 25/50 phút · "Bắt đầu lúc hh:mm" (giờ server) | BR-01, BR-02 |
| Thưởng dự kiến | 25' = "+10 Coins", 50' = "+25 Coins" nếu cả phiên không ai rời app | D-09 |
| Số người | "5 người đã vào phòng chờ" — chỉ số, không danh sách trạng thái (VQ-02) | NFR-P02 |
| Luật | "Rời app quá 3 giây = thoát; cả phiên mất thưởng; cả nhóm biết tên bạn. Khóa màn hình không tính." | D-05, D-08, D-22 |
| Nút "Sẵn sàng" | Chờ chốt T-BA-96; nếu bỏ thì vào phòng chờ = WAITING | T-BA-96 |

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Như thành phần; đồng hồ đếm đến giờ bắt đầu theo giờ server |
| Chưa đồng ý điều khoản mới | Chặn, chuyển V-05 (AC-03.01.2) |
| Phiên bị hủy khi đang chờ | "Chủ nhóm đã hủy phiên này." → V-03; trạng thái VOID (AC-03.01.4) |
| Đã qua hạn vào | "Phiên đã bắt đầu. Bạn không vào được phiên này." (BR-08; vào muộn chỉ khi US-03.11 trong phạm vi) |
| Đã trong phiên khác | Không áp dụng ở MVP (1 nhóm, BR-78) |
| Dữ liệu sai thời lượng | "Phiên này không mở được. Đã báo lỗi." (AC-03.01.5) |
| Biên — nhóm 4 / 10 thành viên | Số người hiện đúng "4"/"10"; không tên |
| Đang tải | Khung xương |
| Lỗi tải | "Chưa vào được phòng chờ." + "Thử lại" |
| Mất mạng | "Đang kết nối lại…"; nối lại trước `started_at` thì giữ WAITING; không nối được đến hạn vào → như "Đã qua hạn vào" (giả định) |
| Chủ nhóm gọi API | 403 "Chủ nhóm không tham gia phiên" (AC-03.01.3) |

## Câu chữ chính
- "Bắt đầu lúc 09:00 · 25 phút · +10 Coins nếu cả phiên không ai rời app"
- "Khóa màn hình không tính là rời app."
- "Chủ nhóm đã hủy phiên này."

## Điều cấm
- Không chọn thời lượng của thành viên, không multiplier, phí, pool (T-BA-83, T-BA-96).
- Không danh sách trạng thái từng người, online/offline (NFR-P02).
- Không cảm biến úp máy (T-BA-81).
- Không nút vào cho chủ nhóm (D-25).

## AC liên quan
AC-03.01.1 … .5.
