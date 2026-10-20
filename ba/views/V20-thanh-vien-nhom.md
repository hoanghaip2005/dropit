# V-20 Thành viên nhóm (+ xóa thành viên cho chủ nhóm)

Story: US-02.06 (Must), US-02.08 (Must) · Quy tắc: BR-32, BR-59, BR-74, BR-77, BR-99, BR-115, §3 #34 · Quyết định: D-03, D-10, D-12, D-25 · NFR: NFR-11, NFR-P06 · Token: DESIGN.md

## Mục đích
Thành viên: biết trong nhóm có ai, ai là chủ nhóm. Chủ nhóm: quản lý danh sách, xóa thành viên khi cần.

## Vai trò
- Thành viên nhóm G: chế độ chỉ xem.
- Chủ nhóm G: thêm nút "Mời thành viên", "Xóa khỏi nhóm".

## Lối vào / lối ra
- Vào: V-19 / V-41 chạm nhóm.
- Ra: chạm một người → V-32 (hồ sơ công khai); "Mời thành viên" → V-43 (chủ nhóm); "Cài đặt nhóm" → V-21 (thành viên).

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Đầu màn | Tên nhóm · sĩ số "7/10 thành viên" (không gồm chủ nhóm) | BR-74 (đề xuất Q-141) |
| Dòng chủ nhóm | Đứng đầu; avatar + khung, tên, nhãn "Chủ nhóm", chú thích "Không tham gia phiên" | AC-02.06.7, D-25 |
| Dòng thành viên | Avatar + khung đang trang bị, tên hiển thị; huy hiệu/chuỗi **chỉ** khi người đó tự bật | BR-99, AC-02.06.2 |
| Thứ tự | Sau chủ nhóm: tên A→Z (không phân biệt hoa/thường, thứ tự chữ Việt), trùng tên theo thời điểm vào nhóm (sớm trước), rồi `user_id` | BR-115 |
| Cảnh báo sàn (chủ nhóm) | "Nhóm dưới 4 người — mời thêm" khi sĩ số < 4 | BR-74 |
| Nút "Mời thành viên" (chủ nhóm) | → V-43 | US-02.03 |
| Menu dòng (chủ nhóm) | "Xóa khỏi nhóm" | US-02.08 |
| Hộp xác nhận xóa | Tiêu đề "Xóa ‹Tên› khỏi nhóm?"; nội dung (xem Câu chữ); nút "Xóa" (chữ `#BA1A1A`), "Hủy" | BR-77, BR-59 |
| Cài đặt nhóm (thành viên) | "Rời nhóm / Rút đồng ý" → V-21 | US-01.07 |

API: `GET /groups/{id}/members` (403 nếu không thuộc nhóm, AC-02.06.3); `DELETE /groups/{id}/members/{user_id}` (chỉ chủ nhóm, AC-02.08.2).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Danh sách |
| Rỗng (chủ nhóm, CN + 0 TV) | "Nhóm chưa có thành viên." + "Mời thành viên" + cảnh báo sàn |
| Đang tải | Khung xương |
| Lỗi tải | "Chưa tải được danh sách." + "Thử lại" |
| Mất mạng | Bản đã lưu + "Chưa cập nhật"; nút xóa/mời khóa |
| Xóa — người đó đang trong phiên COUNTDOWN/ACTIVE | Hộp xác nhận thêm dòng: "‹Tên› đang trong phiên. Việc xóa có hiệu lực sau khi phiên kết thúc lúc ‹hh:mm›. Kết quả phiên không đổi." Sau khi xác nhận, dòng có nhãn "Sẽ rời nhóm lúc ‹hh:mm›" (AC-02.08.4) |
| Xóa thành công | Toast "Đã xóa ‹Tên› khỏi nhóm."; dòng biến mất; nếu sĩ số < 4 hiện cảnh báo sàn (AC-02.08.6) |
| Xóa chính mình | Không có mục "Xóa" ở dòng chủ nhóm; nếu gọi API: "Chủ nhóm không tự xóa được. Dùng Giải tán nhóm." (AC-02.08.3; Giải tán là US-02.09 Should) |
| Lỗi xóa | 403/lỗi mạng: "Chưa xóa được. Thử lại sau." |

## Câu chữ chính
- "7/10 thành viên"
- "Chủ nhóm · Không tham gia phiên"
- Xác nhận xóa: "‹Tên› sẽ không còn trong nhóm và nhận thông báo 'Bạn không còn trong nhóm ‹Tên nhóm›'. Số liệu đến hôm nay vẫn giữ trong báo cáo. Sự kiện rời app đã ghi không bị xóa."
- "Nhóm dưới 4 người — mời thêm"

## Điều cấm
- Không số lần thoát, Coins, chuỗi (trừ phần tự bật), điểm, xếp hạng, trạng thái online/offline, "đang trong phiên" của từng người (AC-02.06.2, NFR-P06, BR-116).
- Không sắp/lọc theo chỉ số hay hoạt động; không tô "cao nhất/thấp nhất" (BR-115).
- Chạm một người **không** mở dữ liệu phiên (04 §3: hồ sơ chỉ phần công khai); dữ liệu phiên xem qua V-46 / V-48 / V-49.
- Không nút nhắn tin, "nhắc", "rung" (BR-116).
- Không sửa/xóa sự kiện EXITED cũ của người bị xóa (AC-02.08.5).
- Không email của thành viên (chỉ quản trị thấy, US-01.03 ghi chú).

## AC liên quan
AC-02.06.2, .3, .7; AC-02.08.1, .2, .3, .4, .5, .6.
