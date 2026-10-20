# V-47 Giải trình của thành viên (chủ nhóm xem)

Story: US-04.06 (Must) · Quy tắc: BR-32, BR-34, BR-54, BR-73, BR-85, BR-102, BR-116 · Quyết định: D-22, D-25 · NFR: NFR-P07, NFR-P10, NFR-P18 · Token: DESIGN.md
Thắng `mockup/alert_details` khi lệch (T-BA-104).

## Mục đích
Chủ nhóm đọc đầy đủ bối cảnh một lần rời app của một thành viên. Chỉ đọc.

## Vai trò
Chủ nhóm hiện tại của nhóm. Thành viên khác cùng nhóm: 403 (AC-04.06.4). Người viết xem giải trình của mình ở V-15.

## Lối vào / lối ra
- Vào: V-46 chạm dòng rời app; V-16 chạm thông báo "‹Tên› đã gửi giải trình" (AC-04.06.2); V-49 chạm sự kiện thoát.
- Ra: quay lại màn trước; "Xem phiên" → V-46.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Đầu màn | Tên thành viên + avatar · tên lịch · ngày · "Rời app lúc hh:mm:ss" (giờ server) | BR-116, D-22 |
| Nhãn khởi phát | "Lần rời app này làm phiên mất thưởng tập thể" (chỉ khi là `forfeit_trigger_user_id`) | BR-38 |
| Nội dung giải trình | Nguyên văn, tối đa 500 ký tự | BR-85 |
| Nhãn sửa | "Đã sửa lúc hh:mm dd/mm" — chỉ hiện bản mới nhất | AC-04.06.6 |
| Nhãn thêm sau | "Thêm sau khi tạo báo cáo" khi gửi sau lúc tạo báo cáo kỳ đó | BR-102 |
| Chú thích | "Giải trình không thay đổi kết quả phiên." | BR-54 |
| Khiếu nại | Chỉ khi US-04.07 (Should) trong phạm vi: trạng thái CHỜ XỬ LÝ / ĐANG XỬ LÝ / CHUYỂN QUẢN TRỊ / MIỄN TRỪ / BÁC | BR-86 |

API: `GET /groups/{gid}/exits/{event_id}` — chỉ chủ nhóm; mỗi lần mở ghi nhật ký truy cập (AC-04.06.3, BR-73). `PUT/DELETE` → 403 (AC-04.06.5).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường — có giải trình | Như thành phần |
| Rỗng — chưa có giải trình | "‹Tên› chưa gửi giải trình. Hạn gửi đến hh:mm dd/mm." (`ends_at` + 7 ngày) |
| Rỗng — hết hạn, không gửi | "‹Tên› không gửi giải trình cho lần rời app này." |
| Đang tải | Khung xương |
| Lỗi tải | "Chưa tải được giải trình." + "Thử lại" |
| Lỗi quyền (403) | "Bạn không có quyền xem nội dung này." |
| Mất mạng | Bản đã lưu + "Chưa cập nhật"; không có bản lưu → "Cần kết nối mạng để xem." |
| Thành viên đã rời nhóm | Vẫn hiện, tên kèm "(đã rời nhóm)"; sự kiện không bị xóa (AC-02.08.5) |

## Câu chữ chính
- "‹Tên› rời app lúc 09:10:03"
- "Giải trình không thay đổi kết quả phiên."
- "‹Tên› chưa gửi giải trình."

## Điều cấm
- Không nút sửa, xóa, trả lời, "ghi nhận vi phạm", "biên bản", đánh giá (AC-04.06.5, T-BA-104).
- Không tên app đã mở, thời lượng ngoài app, nội dung máy (BR-34, VQ-08).
- Không Coins, chuỗi, số lần thoát tích lũy, điểm/hạng.
- Không chia sẻ/chuyển tiếp giải trình cho thành viên khác (NFR-P18).
- Không ô "ghi chú đánh giá của chủ nhóm" (T-BA-110).

## AC liên quan
AC-04.06.1, .2, .3, .4, .5, .6.
