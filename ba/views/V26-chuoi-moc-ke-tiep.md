# V-26 Thành tích: chuỗi và mốc kế tiếp

Story: US-05.04 (Must); liên quan US-05.06 (Should, V-28) · Quy tắc: BR-46, BR-47, BR-49, BR-51, BR-52, BR-53, BR-89, BR-99 · Quyết định: D-03, D-12 · Q: Q-17, Q-127, Q-132 · NFR: NFR-P06, NFR-P17 · Token: DESIGN.md

## Mục đích
Cho người dùng thấy chuỗi hiện tại, chuỗi dài nhất và còn bao nhiêu đến huy hiệu kế tiếp, để có động lực — không so với ai.

## Vai trò
Người dùng (chính mình). Chủ nhóm không có màn/API tương đương (BR-53 b).

## Lối vào / lối ra
- Vào: V-22 "Thành tích"; thẻ chuỗi ở V-03; V-27 "Xem thành tích".
- Ra: "Tất cả huy hiệu" → V-28 (Should); quay lại.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Thẻ chuỗi | Số lớn "5 ngày" (`headline-xl`, số bảng), nhãn "Chuỗi hiện tại"; dòng phụ "Chuỗi dài nhất: 12 ngày" | `GET /me/achievements` → `current_streak`, `longest_streak`; BR-51 |
| Trạng thái hôm nay | "Hôm nay đã cộng chuỗi" / "Hôm nay chưa cộng chuỗi" / "Hôm nay không có lịch — chuỗi giữ nguyên" | BR-49 (đề xuất Q-17), AC-05.04.2 |
| Cách tính (chạm "?") | "Chuỗi +1 khi bạn hoàn thành có thưởng ít nhất một phiên trong ngày. Chuỗi về 0 khi bạn rời app, hoặc khi phiên bạn tham gia mất thưởng tập thể. Vắng hoặc ngày không có lịch không làm mất chuỗi. Chuỗi không cộng Coins." | BR-47, BR-48, BR-49, BR-51 |
| Mốc chuỗi kế tiếp | "Huy hiệu Chuỗi 7 ngày — còn 2 ngày"; thanh tiến độ tĩnh 5/7 | BR-52 (mốc 3/7/14/30/60/100, đề xuất Q-132) |
| Mốc phiên kế tiếp | "Huy hiệu 10 phiên có thưởng — còn 3 phiên" | BR-52 (10/50/100/500) |
| Mốc giờ kế tiếp | "Huy hiệu 10 giờ tập trung — còn 2 giờ 15 phút" — nhãn chỉ số: **"Giờ tập trung (huy hiệu)"** | BR-89 (tên khác chỉ số báo cáo, Q-127) |
| Huy hiệu gần đây | Tối đa 3 huy hiệu đã đạt gần nhất, có ngày đạt | BR-52 |
| Dòng hiển thị công khai | "Chuỗi và huy hiệu đang: Ẩn với nhóm" + liên kết "Đổi" → V-28 (Should) | BR-99, NFR-P17 |

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Như trên |
| Chuỗi vừa bị ngắt | "Chuỗi hiện tại: 0 ngày"; "Chuỗi dài nhất" không giảm (AC-05.04.4) |
| Đã đạt mốc chuỗi cao nhất | Thay mốc kế tiếp bằng "Bạn đã đạt mọi mốc chuỗi." (AC-05.04.5); tương tự cho mốc phiên/giờ |
| Người dùng mới | "Chuỗi hiện tại: 0 ngày" · mốc kế tiếp "Chuỗi 3 ngày — còn 3 ngày" · "Chưa có huy hiệu" |
| Đang tải | Khung xương; **không** hiện 0 tạm |
| Lỗi | "Chưa tải được thành tích." + "Thử lại"; không hiện 0 sai (AC-05.04.3) |
| Mất mạng | Bản đã lưu + "Chưa cập nhật" |

## Câu chữ chính
- "Chuỗi hiện tại" · "Chuỗi dài nhất"
- "Hôm nay chưa cộng chuỗi" (không viết "đã mất")
- "Huy hiệu ‹Tên› — còn ‹N› ‹ngày/phiên/giờ›"
- "Chuỗi không cộng Coins."
- "Bạn đã đạt mọi mốc chuỗi."

## Điều cấm
- Không bảng xếp hạng chuỗi, không "bạn hơn x% đồng nghiệp", không so với nhóm (D-03, NFR-P06).
- Không thưởng Coins theo chuỗi, không hệ số (BR-51).
- Không mua/khôi phục chuỗi bằng Coins.
- Không tự công khai chuỗi; bật hiện phải qua cảnh báo NFR-P17 ở V-28.
- Không dùng tên "Tổng phút tập trung" của báo cáo cho chỉ số huy hiệu (BR-89).

## AC liên quan
AC-05.04.1, .2, .3, .4, .5.
