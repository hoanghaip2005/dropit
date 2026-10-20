# V-23 Sửa hồ sơ

Story: US-01.03 (Must; gộp US-07.02 theo D-14), US-07.03 (Should — đổi ảnh chi tiết) · Quy tắc: BR-97, BR-98, BR-99 · Q: Q-126 · NFR: NFR-11, NFR-P01 · Token: DESIGN.md

## Mục đích
Đặt tên hiển thị và ảnh đại diện để người cùng nhóm nhận ra mình.

## Vai trò
Người dùng đã đăng nhập (chỉ hồ sơ của chính mình).

## Lối vào / lối ra
- Vào: V-22 "Sửa hồ sơ".
- Ra: "Lưu" thành công → V-22 với toast "Đã lưu hồ sơ."; "Hủy" / quay lại khi có thay đổi chưa lưu → hộp "Bỏ thay đổi?" ("Bỏ" / "Ở lại").

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Ảnh đại diện | Ảnh hiện tại trong khung đang trang bị; nút "Đổi ảnh", "Xóa ảnh" | BR-98; US-07.03 |
| Chọn ảnh | Thư viện / máy ảnh; quyền chỉ xin khi bấm "Đổi ảnh" | NFR-P01 |
| Cắt vuông | Khung cắt 1:1 trước khi tải | BR-98 |
| Ô "Tên hiển thị" | Văn bản 1 dòng; bộ đếm "n/30" | BR-97: 2–30 ký tự sau khi cắt khoảng trắng (đề xuất Q-126) |
| Ô "Email" | Chỉ đọc, chú thích "Chỉ bạn và quản trị thấy email." | US-01.03 ghi chú, 04 §3 |
| Khối "Ai thấy gì" | "Người cùng nhóm (kể cả chủ nhóm) thấy tên, ảnh, khung và hình nền bạn đang dùng." | BR-99 |
| Nút "Lưu" | Đen viên thuốc; khóa khi không có thay đổi hoặc có lỗi | — |

API: `PATCH /me/profile {display_name}`; ảnh: `POST /me/avatar/upload-url` → tải lên S3 → `POST /me/avatar/confirm` (BR-98).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Giá trị hiện tại |
| Tên rỗng / < 2 ký tự | Dưới ô (`#BA1A1A`): "Tên cần từ 2 đến 30 ký tự." — giữ tên cũ trên server (AC-01.03.2) |
| Tên 30 ký tự | Chấp nhận; 31 ký tự → không gõ thêm được và báo lỗi nếu dán vào (AC-01.03.4) |
| Ký tự điều khiển | "Tên có ký tự không hợp lệ." (BR-97) |
| Ảnh sai định dạng | "Chỉ nhận ảnh JPG, PNG hoặc WebP." — chặn trước khi tải; ảnh cũ giữ nguyên |
| Ảnh quá dung lượng | "Ảnh tối đa 5 MB." (đúng 5 MB nhận; vượt 1 byte từ chối) |
| Đang tải ảnh | Thanh tiến độ tĩnh theo phần trăm; nút "Lưu" khóa |
| Tải ảnh lỗi / URL hết hạn | "Chưa tải được ảnh." + "Thử lại"; ảnh cũ giữ nguyên |
| Mất mạng | Nút "Lưu" khóa; dải "Không có kết nối — chưa lưu được." |
| Đang tải màn | Khung xương |
| Rỗng | Chưa có ảnh: avatar mặc định (chữ cái đầu tên) |

## Câu chữ chính
- "Tên hiển thị" · "Tên cần từ 2 đến 30 ký tự."
- "Chỉ nhận ảnh JPG, PNG hoặc WebP, tối đa 5 MB."
- "Người cùng nhóm (kể cả chủ nhóm) thấy tên, ảnh, khung và hình nền bạn đang dùng."
- "Chỉ bạn và quản trị thấy email."
- "Đã lưu hồ sơ."

## Điều cấm
- Không trường chức danh, phòng ban, công ty, số điện thoại (D-10; không thu dữ liệu thừa).
- Không đọc danh bạ, không liên kết Google/Slack (T-BA-117, GĐ1 §6).
- Không giữ vị trí trong ảnh: server xóa EXIF (BR-98) — màn không hiện vị trí ảnh.
- Không cho xem/sửa hồ sơ người khác (AC-01.03.3).
- Không đổi tên/ảnh dẫn đến sửa báo cáo đã tạo (báo cáo giữ tên cũ, BR-97).

## AC liên quan
AC-01.03.1, .2, .3, .4; AC-07.03.1–.6 (khi US-07.03 trong phạm vi).

Ghi chú: giới hạn tên/ảnh EP-01 và EP-07 còn lệch → theo BR-97/BR-98 (Q-126 chờ). US-01.03 Must gồm tải ảnh; US-07.03 (Should) chi tiết hóa — cần điều phối viên xác nhận phần ảnh thuộc story nào khi xếp sprint.
