# V-21 Rời nhóm / rút đồng ý

Story: US-01.07 (Must) · Quy tắc: BR-26, BR-36, BR-37, BR-48, BR-59, BR-74, BR-76, §3 #15, #26, #26b · Quyết định: D-05, D-14, D-21, D-23 · NFR: 04 §2 "Rút lại đồng ý", NFR-P18 · Token: DESIGN.md

## Mục đích
Cho thành viên rút đồng ý (= rời nhóm) bất cứ lúc nào, hai bước xác nhận, nói rõ hệ quả trước khi xác nhận — kể cả khi đang trong phiên.

## Vai trò
Thành viên nhóm G. Chủ nhóm không có màn này (AC-01.07.3).

## Lối vào / lối ra
- Vào: V-20 "Cài đặt nhóm" → "Rời nhóm / Rút đồng ý"; từ V-08 liên kết "Rút đồng ý và rời nhóm" **(đề xuất, VQ-04)** — điều hướng trong app, không rời app.
- Ra: xác nhận xong → V-19 (trạng thái trống) với toast "Bạn đã rời ‹Tên nhóm›."; hủy ở bất kỳ bước → về màn trước, không đổi gì (AC-01.07.4).

## Thành phần

### Bước 1 — Hệ quả

| Phần tử | Dữ liệu | Nguồn BR |
| --- | --- | --- |
| Tiêu đề | "Rút đồng ý và rời ‹Tên nhóm›" | — |
| Danh sách hệ quả | Xem "Câu chữ chính — bước 1" | BR-26, BR-59, 04 §2 |
| Khối theo ngữ cảnh phiên | Chỉ hiện khi đang có trạng thái chưa kết thúc trong phiên của G (bảng dưới) | BR-26, BR-37, D-23 |
| Nút | "Tiếp tục" (đen), "Hủy" | — |

| Ngữ cảnh | Câu trong khối |
| --- | --- |
| Không trong phiên | (không hiện khối) |
| Đang trong phiên, phiên **chưa** mất thưởng | "Bạn đang trong phiên ‹Tên lịch›. Rút đồng ý sẽ dừng ghi ngay. Lần này **không** tính là rời app, không ai nhận thông báo, phiên của nhóm không bị ảnh hưởng. Bạn không nhận Coins phiên này." |
| Đang trong phiên, phiên **đã** mất thưởng tập thể | "Phiên ‹Tên lịch› đã mất thưởng tập thể. Rút đồng ý bây giờ vẫn ngắt chuỗi của bạn và bạn không nhận Coins phiên này." (D-23) |

### Bước 2 — Xác nhận

| Phần tử | Dữ liệu | Nguồn |
| --- | --- | --- |
| Câu hỏi | "Bạn chắc chắn rời ‹Tên nhóm›?" | 04 §2 "2 bước xác nhận" |
| Nút | "Rời nhóm" (nút đen `#1C1C1E`, chữ trắng; không dùng đỏ vì đỏ chỉ dành cho lỗi/cảnh báo thoát) · "Hủy" (nút trắng) | DESIGN.md |

API: `POST /groups/{id}/withdraw` → server trả trạng thái mới (WITHDRAWN nếu đang trong phiên).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Bước 1 → Bước 2 → V-19 |
| Đang gửi | Nút "Đang xử lý…" khóa |
| Lỗi mạng | "Chưa rút được đồng ý. Bạn vẫn là thành viên." + "Thử lại" — không đổi trạng thái cục bộ |
| Phiên vừa đổi trạng thái giữa bước 1 và 2 (vd. vừa `forfeited`) | Server trả hệ quả mới; app hiện lại bước 1 với khối cập nhật trước khi cho xác nhận **(giả định)** |
| Sĩ số rơi dưới sàn | Không ảnh hưởng người rời; vẫn cho rút (AC-01.07.6) |
| Đang tải / rỗng | Không áp dụng |

## Câu chữ chính — bước 1
- "Từ lúc này, DropIt! ngừng ghi dữ liệu phiên của bạn trong nhóm này."
- "Chủ nhóm chỉ nhận thông báo '‹Tên bạn› đã rời nhóm', không kèm lý do."
- "Coins, đồ đã mua, chuỗi, huy hiệu, hồ sơ và nhật ký vẫn là của bạn."
- "Số liệu phiên đến hôm nay vẫn nằm trong báo cáo tháng của nhóm. Bạn vẫn xem được phần của mình ở Dữ liệu của tôi."
- "Muốn quay lại, bạn cần được mời lại và đồng ý lại."
- "Sau khi rời, bạn có thể tham gia nhóm khác."

## Điều cấm
- Không yêu cầu nhập lý do; không gửi lý do cho chủ nhóm.
- Không gọi việc rút đồng ý là "thoát phiên" hay "bỏ cuộc"; không gửi `MEMBER_EXITED` (AC-01.07.2).
- Không màn này cho chủ nhóm (chỉ "Giải tán nhóm", Should).
- Không ô đánh dấu sẵn; không làm nút "Rời nhóm" khó tìm hơn nút "Hủy" (R-P01).
- Không xóa sự kiện cũ khi rời (NFR-P13).

## AC liên quan
AC-01.07.1, .2, .3, .4, .5, .6, .7.
