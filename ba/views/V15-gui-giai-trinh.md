# V-15 Gửi / sửa giải trình

Story: US-04.05 (Must) · Quy tắc: BR-32, BR-54, BR-65, BR-85, BR-102 · Quyết định: D-22 · NFR: NFR-P10, NFR-P13, NFR-P18 · Token: DESIGN.md

## Mục đích
Cho người có sự kiện rời app (EXITED) ghi bối cảnh cho chủ nhóm. Nói rõ trước khi gửi: giải trình **không** đổi kết quả, không hoàn Coins, không khôi phục chuỗi.

## Vai trò
Thành viên có EXITED của chính mình. (LOST, ABSENT, COMPLETED, WITHDRAWN không có màn này — BR-85.)

## Lối vào / lối ra
- Vào: V-13 "Gửi giải trình"; V-25 (mục Sự kiện rời app); V-17 (Should); thông báo "Bạn có thể gửi giải trình" ở V-16 **(giả định)**.
- Có thể vào ngay sau EXITED, khi phiên còn ACTIVE (AC-04.05.6).
- Ra: "Gửi" thành công → về màn trước, có thông báo "Đã gửi giải trình". "Hủy" → về màn trước, không lưu.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Đầu màn | "Giải trình lần rời app" · tên lịch · ngày · "Rời app lúc 09:10:03" (giờ server) | `GET /me/exits/{event_id}` |
| Khối điều cần biết (thẻ `#FFF1EC`, chữ `#111111`) | 3 dòng, xem "Câu chữ chính" | BR-54, NFR-P18, BR-85 |
| Ô nhập | Nhiều dòng, nền trắng, nhãn "Nội dung giải trình" | BR-85 |
| Bộ đếm | "0/500" dưới ô; chữ số dạng bảng | `explanation_max_chars = 500` |
| Hạn gửi | "Gửi được đến ‹hh:mm dd/mm›" = `ends_at + 7 ngày` | `explanation_submit_days = 7` |
| Hạn sửa (sau khi gửi) | "Sửa được đến ‹hh:mm dd/mm›" = lần gửi đầu + 24 giờ | `explanation_edit_h = 24` |
| Nút "Gửi" / "Lưu thay đổi" | Đen viên thuốc; khóa khi ô rỗng hoặc chỉ khoảng trắng, hoặc > 500 | AC-04.05.4, AC-04.05.8 |
| Lịch sử bản cũ | "Đã sửa lúc …" + danh sách bản cũ (chỉ người viết xem) | BR-85 |
| Trạng thái đã đọc | "Chủ nhóm đã xem lúc …" *(chỉ khi US-01.11 trong phạm vi — Should)* | BR-73, Q-21 |

API: `POST /me/exits/{event_id}/explanation`, `PUT …` (sửa). Server kiểm tra loại sự kiện = EXITED (400) và chủ sở hữu (403) (AC-04.05.3).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường — chưa gửi | Ô trống, nút "Gửi" khóa đến khi có nội dung |
| Bình thường — đã gửi, còn hạn sửa | Nội dung đã gửi, nút "Sửa" |
| Hết hạn sửa | Chỉ xem; "Đã hết hạn sửa" (mốc nửa mở: đúng `T + 24h` là hết, AC-04.05.5) |
| Hết hạn gửi (chưa từng gửi) | "Đã hết hạn gửi giải trình cho lần rời app này." Không có ô nhập |
| Đang gửi | Nút "Đang gửi…" khóa; chống bấm hai lần (một giải trình/sự kiện) |
| Lỗi — rỗng | Dưới ô: "Vui lòng nhập nội dung" (`#BA1A1A`) |
| Lỗi — quá dài | "Tối đa 500 ký tự" (`#BA1A1A`); không lưu (501 ký tự bị từ chối) |
| Lỗi — mất mạng | "Chưa gửi được. Nội dung vẫn còn trên máy." + "Thử lại"; giữ nội dung đã gõ |
| Lỗi — server từ chối | 400/403: "Không thể gửi giải trình cho sự kiện này." |
| Rỗng | Không áp dụng |

## Câu chữ chính
- Tiêu đề: "Giải trình lần rời app"
- "Giải trình không thay đổi kết quả phiên, không hoàn Coins và không khôi phục chuỗi cho ai."
- "Chỉ bạn và chủ nhóm thấy giải trình. Các thành viên khác không thấy."
- "Bạn chỉ gửi được một giải trình cho mỗi lần rời app; sửa được trong 24 giờ sau khi gửi."
- "Không xóa được sự kiện rời app. Nếu ghi nhầm, hãy giải trình." (NFR-P13)
- Thành công: "Đã gửi giải trình. Chủ nhóm sẽ thấy trong app."

## Điều cấm
- Không nút xóa sự kiện thoát (AC-04.05.7).
- Không chip lý do chọn sẵn cho đến khi chốt T-BA-101 / Q-90 (chưa có trong BR-85).
- Không đính kèm ảnh/tệp; không chia sẻ cho thành viên khác.
- Không hứa "hoàn Coins" hay "có thể được miễn trừ" (khiếu nại là US-04.07, Should — chỉ hiện liên kết khi trong phạm vi).
- Không đọc/gợi ý nội dung máy (tên app đã mở) để điền sẵn (BR-34).

## AC liên quan
AC-04.05.1, .2, .3, .4, .5, .6, .7, .8; AC-04.06.2 (thông báo tới chủ nhóm, xem V-16).
