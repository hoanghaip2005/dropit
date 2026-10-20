# V-14 Kết quả phiên — các biến thể

Story: US-03.10 (Must), US-03.08 (Must), US-03.07 (Must), US-06.01 · Quy tắc: BR-08, BR-21, BR-23, BR-24, BR-37, BR-38, BR-41, BR-43, BR-46, BR-47, BR-48, BR-91, BR-22/BR-68 (Should) · Quyết định: D-05, D-09, D-11, D-19, D-22 · Token: DESIGN.md

Bổ sung cho V-12 (`mockup/session_success_reward`, `success_reward` — hoàn thành có thưởng) và V-13 (`mockup/n_09` — bạn đã rời phiên). Cùng bố cục, chỉ khác khối kết quả.

## Mục đích
Sau `ends_at`, cho mỗi thành viên biết **kết quả của chính mình** và vì sao nhận / không nhận Coins, điểm danh, chuỗi.

## Vai trò
Thành viên có trạng thái trong phiên. Chủ nhóm không có màn kết quả (D-25); họ xem V-46.

## Lối vào / lối ra
- Vào: tự mở khi server gửi `SESSION_RESULT` (BR-91) nếu app đang mở; nếu không, khi mở app lần kế tiếp; từ V-16, V-25, V-17 (Should).
- Ra: "Xong" → V-03; nếu có huy hiệu mới → V-27 trước rồi V-03; "Xem lịch sử Coins" → V-29.

## Bố cục chung

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Nền | `background #F4F5F7`, thẻ trắng bo 24px, bóng chuẩn | DESIGN.md |
| Đầu thẻ | Tên lịch · nhóm · ngày · giờ bắt đầu–kết thúc · 25/50 phút | `GET /me/sessions/{id}/result` |
| Nhãn kết quả | Chữ + biểu tượng (không chỉ màu, NFR-20) | §2.2 trạng thái cuối |
| Phút tập trung | Số phút, chữ số dạng bảng | BR-23 |
| Coins | Chip `#FFF1EC` chữ `#B02F00`: "+N Coins" hoặc "0 Coins" | BR-40, BR-41, BR-43 |
| Coins hôm nay | "Hôm nay: x/100" | BR-43, D-09 |
| Điểm danh | "Hôm nay đã điểm danh" / "Phiên này không tính điểm danh" | BR-46 |
| Chuỗi | "Chuỗi: N ngày" / "Chuỗi bị ngắt — còn 0 ngày" / "Chuỗi giữ nguyên" | BR-47, BR-48, BR-49 |
| Lý do (nếu có) | Một câu, xem từng biến thể | BR-38, BR-41 |
| Nút chính | "Xong" (đen `#1C1C1E`, viên thuốc) | DESIGN.md |

## Các biến thể

| Biến thể | Điều kiện | Nhãn kết quả | Coins | Điểm danh | Chuỗi | Câu lý do |
| --- | --- | --- | --- | --- | --- | --- |
| A. Hoàn thành nhưng mất thưởng | COMPLETED, `forfeited = true`, người khác khởi phát | "Hoàn thành" (biểu tượng tích, chữ `#1B7F3B`) | 0 Coins | Có | Bị ngắt → 0 | "Phiên đã mất thưởng tập thể do ‹Tên A› rời phiên lúc hh:mm:ss. Bạn vẫn hoàn thành phiên." |
| B. Mất kết nối | LOST, `forfeited = false` | "Mất kết nối" (biểu tượng mạng, chữ `#6C6C70`) | 0 Coins | Không | Giữ nguyên **(đề xuất, Q-27)** | "Bạn mất kết nối quá lâu nên phiên của bạn kết thúc sớm. Cả nhóm không bị ảnh hưởng." |
| B2. Mất kết nối trong phiên mất thưởng | LOST, `forfeited = true` | "Mất kết nối" | 0 Coins | Không | Bị ngắt **(đề xuất, Q-27)** | Câu B + "Phiên cũng đã mất thưởng tập thể do ‹Tên A› rời phiên." |
| C. Vắng | ABSENT | "Vắng" | 0 Coins | Không | Giữ nguyên | "Bạn chưa vào phiên trước giờ bắt đầu. Vắng không phải là rời app và không ai nhận thông báo." |
| D. Hoàn thành có thưởng, đạt trần | COMPLETED, không `forfeited`, đã đủ 100 hôm nay | "Hoàn thành có thưởng" | "+N Coins (đã đạt trần ngày)" hoặc "0 Coins — đã đạt trần 100 Coins hôm nay" | Có | +1 nếu chưa cộng hôm nay | "Trần Coins mỗi ngày là 100." |
| E. Phiên bị hủy do sự cố *(US-03.12, Should)* | VOID | "Phiên bị hủy — không tính" | 0 Coins | Không | Giữ nguyên | "Phiên đã hủy do sự cố hệ thống. Kết quả của bạn không bị tính." |
| E2. Đã rời app trước sự cố *(Should)* | EXITED + phiên CANCELLED do sự cố | "Rời app" | 0 Coins | Không | Bị ngắt | Câu `SESSION_CANCELLED_OUTAGE_EXITED` (BR-68), nút "Khiếu nại" chỉ khi US-04.07 trong phạm vi |
| F. Rút đồng ý trong phiên | WITHDRAWN | "Đã rời nhóm" | 0 Coins | Không | Giữ nguyên nếu trước `forfeited_at`; bị ngắt nếu sau (D-23) | Hiện ở V-25 thay vì tự mở (người đó đã rời nhóm) |

Biến thể A là ca "hoàn thành nhưng mất thưởng" còn thiếu ở §4 `mockup-tong-hop.md`. Hoàn thành có thưởng thường: V-12. Bản thân là người thoát: V-13.

Ở biến thể D, `+N` là phần còn lại đến trần (BR-43): vd. đã có 90, phiên 25 phút → "+10 Coins"; đã có 90, phiên 50 phút → "+10 Coins (đã đạt trần ngày)"; đã có 100 → "0 Coins — đã đạt trần".

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Như biến thể |
| Đang tải | Khung xương thẻ; không hiện số tạm |
| Chưa chốt (mở app trước khi server chốt) | "Đang chốt kết quả…"; không hiện Coins dự đoán |
| Lỗi tải | "Chưa tải được kết quả." + "Thử lại"; không hiện 0 sai |
| Mất mạng | Bản đã lưu (nếu có) + nhãn "Chưa cập nhật"; nếu chưa có thì lỗi + "Thử lại" |
| Rỗng | Không áp dụng |

## Câu chữ chính
- "Hoàn thành — 0 Coins"
- "Phiên đã mất thưởng tập thể do ‹Tên› rời phiên lúc ‹hh:mm:ss›. Bạn vẫn hoàn thành phiên."
- "Hôm nay đã điểm danh."
- "Chuỗi bị ngắt — còn 0 ngày. Chuỗi dài nhất của bạn không đổi."
- "Mất kết nối — 0 Coins. Cả nhóm không bị ảnh hưởng."
- "Vắng — 0 Coins."
- "Đã đạt trần 100 Coins hôm nay."

## Điều cấm
- Không hiện kết quả từng người khác (ai hoàn thành, ai mất kết nối, phút của ai); chỉ tên người khởi phát ở phiên `forfeited` (04 §3 dòng "Kết quả phiên", BR-119).
- Không xếp hạng, không "bạn đứng thứ…", không điểm/Level/XP (D-03).
- Không thưởng chuỗi bằng Coins (BR-51), không "Bonus Streak".
- Không câu phán xét người thoát; không nút "báo cáo"/"nhắn" người thoát.
- Không dòng "0 Coins" trong sổ cái (BR-41) — màn chỉ giải thích.
- Không gợi ý "mua lại chuỗi" hay bất kỳ cách đổi Coins lấy kết quả (D-01).

## AC liên quan
AC-03.10.1, .2, .3, .6, .7; AC-03.09.7; AC-03.08.8; AC-03.07.3, .8, .10; AC-06.02.6 (trần); AC-03.12.1, .2, .6 (Should).
