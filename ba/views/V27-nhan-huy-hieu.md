# V-27 Nhận huy hiệu (thông báo trong app)

Story: US-05.05 (Must) · Quy tắc: BR-31, BR-52, BR-89, BR-90, BR-91, BR-99 · Q: Q-95, Q-125 · Quyết định: D-01, D-03 · Token: DESIGN.md

## Mục đích
Báo cho người dùng biết vừa đạt huy hiệu, như một ghi nhận tích cực, không cộng Coins.

## Vai trò
Người dùng (chính mình).

## Lối vào / lối ra
- Vào: sau màn kết quả (V-12/V-14) khi phiên đó làm đạt mốc; hoặc lần mở app kế tiếp nếu lúc cấp người dùng không mở app (VQ-07); hoặc khi job hằng ngày cấp hồi tố (BR-90). Mục tương ứng có trong V-16.
- **Không** hiện trong lúc có trạng thái chưa kết thúc trong phiên (BR-91).
- Ra: "Tuyệt" → màn trước / V-03; "Xem thành tích" → V-26.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Tấm dưới (bottom sheet) | Thẻ trắng bo 24px trên nền mờ; không pháo hoa động liên tục (chỉ hình tĩnh) | DESIGN.md |
| Hình huy hiệu | Ảnh tĩnh, có nhãn đọc màn hình là tên huy hiệu | NFR-20 |
| Tiêu đề | "Bạn nhận huy hiệu ‹Tên›" | AC-05.05.1 |
| Mô tả mốc | "Chuỗi 7 ngày" / "10 phiên có thưởng" / "10 giờ tập trung" | BR-52 |
| Ngày đạt | "Đạt lúc ‹hh:mm dd/mm›" | `awarded_at` |
| Ghi chú | "Huy hiệu là ghi nhận, không cộng Coins." | US-05.05 ghi chú |
| Nhiều huy hiệu cùng lúc | Danh sách các huy hiệu trong cùng tấm (AC-05.05.7) | — |
| Dòng hiển thị | "Huy hiệu đang ẩn với nhóm. Bạn có thể bật trong Huy hiệu." (liên kết V-28 khi US-05.06 trong phạm vi) | BR-99 (mặc định ẩn, Q-94) |
| Nút | "Tuyệt" (đen); "Xem thành tích" (chữ) | — |

API: `GET /me/badges?unseen=true`, `POST /me/badges/seen`.

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Tấm như trên, một lần cho mỗi huy hiệu (đánh dấu đã xem) |
| Cấp hồi tố do đổi mốc | Như bình thường, thêm dòng "Mốc mới được cập nhật." (BR-90, đề xuất Q-125) |
| Đang tải / rỗng | Không hiện tấm |
| Lỗi tải | Không hiện tấm; mục vẫn có ở V-16 và V-26 |
| Mất mạng | Không hiện; hiện khi có mạng lại |
| Gửi trùng sự kiện | Không cấp/hiện hai lần (AC-05.05.5) |

## Câu chữ chính
- "Bạn nhận huy hiệu ‹Tên›"
- "Huy hiệu là ghi nhận, không cộng Coins."
- "Huy hiệu đang ẩn với nhóm."

## Điều cấm
- Không push hệ thống (Q-95); không hiện trong phiên (BR-91).
- Không "+Coins", "+XP", Level (D-01, D-03).
- Không nút "Khoe với nhóm" / chia sẻ tự động (EP-10 ngoài MVP, BR-120).
- Không cấp lại huy hiệu đã có khi chuỗi đạt lại mốc (AC-05.05.4).
- Không hiện "x người đã có huy hiệu này".

## AC liên quan
AC-05.05.1, .2, .3, .4, .5, .6, .7, .8.
