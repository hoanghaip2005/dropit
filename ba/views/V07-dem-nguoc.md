# V-07 Đếm ngược 5 giây

Story: US-03.02 (Must) · Quy tắc: BR-03, BR-04, BR-05, BR-07, BR-22, BR-33, BR-64, BR-65 · NFR: NFR-P02, NFR-P08, NFR-20 · Token: `mockup/dropit/DESIGN.md`

## Mục đích
Cho mọi thành viên trong phòng chờ cùng thấy một đếm ngược 5→1 theo giờ server, rồi vào phiên đúng `started_at`. Báo rõ: **chưa ghi** trong lúc đếm.

## Vai trò
Thành viên có trạng thái WAITING trong phiên. Chủ nhóm không bao giờ thấy màn này (BR-114).

## Lối vào / lối ra
- Vào: từ V-06 khi server báo phiên → COUNTDOWN (lúc `started_at − countdown_s`). Vào phòng chờ trong lúc đang đếm (AC-03.02.6) → mở thẳng V-07 với số giây còn lại.
- Ra:
  - Đến `started_at` → V-08 (FOCUSING).
  - Sự cố server (BR-22) → V-14 biến thể "Phiên bị hủy" *(chỉ khi US-03.12 trong phạm vi)*.
  - Không có nút quay lại / thoát trên màn.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Nền | Đen tĩnh `lockdown-bg #000000`; không glow, không pulse, không vòng tiến độ chạy | DESIGN.md "Dark Contexts" |
| Số đếm | 5, 4, 3, 2, 1 — chữ trắng, `headline-xl` 36px, số dạng bảng (tabular). Chỉ đổi mỗi giây | BR-04; tính từ `started_at` server gửi, không theo đồng hồ máy (BR-03) |
| Dòng phụ | Tên lịch · thời lượng (25/50 phút) · "Bắt đầu lúc 09:00:00" | `GET /sessions/{id}` → `title`, `duration`, `started_at` |
| Chỉ báo ghi | "Chưa ghi — bắt đầu ghi lúc 09:00:00" (`lockdown-text-secondary #A1A1A6`, `body-md`) | BR-05, NFR-P08: chỉ báo "Phiên đang được ghi" **không** hiện ở màn này |
| Nhắc luật | "Ở lại trong app. Rời app sau khi bắt đầu sẽ báo tên bạn cho cả nhóm và làm cả phiên mất thưởng." | D-05, D-22, BR-64 |
| Nhắc úp máy | "Bạn có thể khóa hoặc úp máy — khóa màn hình không tính là rời app." | D-08, BR-15 |
| Số người sẵn sàng | "5 người đã sẵn sàng" (chỉ số đếm) **(đề xuất, VQ-02)** | Không tên, không trạng thái từng người (NFR-P06) |
| Nhãn đọc màn hình | Đọc "Còn N giây" mỗi giây; không phát âm thanh | NFR-20 |

Kênh dữ liệu: socket phiên gửi sự kiện `countdown_started { started_at, server_now }`. Client tính độ lệch = `server_now − giờ máy`, hiển thị theo giờ server. Mốc bắt đầu lệch ≤ 1 giây so với `started_at` (AC-03.02.3).

## Trạng thái

| Trạng thái | Hiển thị | Ghi chú |
| --- | --- | --- |
| Bình thường | Đếm 5→1, rồi chuyển V-08 đúng `started_at` | AC-03.02.1, AC-03.02.2 |
| Vào giữa chừng | Hiện số giây còn lại (vd. 3); không gắn "vào muộn" | AC-03.02.6, BR-07 |
| Đang tải | Chưa nhận `started_at` từ server: hiện "Đang đồng bộ giờ…", không hiện số | Không tự đếm theo đồng hồ máy |
| Rỗng | Không áp dụng (đã có ≥1 người WAITING) | — |
| Lỗi — sự cố server | "Phiên đã hủy do sự cố hệ thống. Kết quả của bạn không bị tính." → nút "Về trang chủ" | AC-03.02.5, `SESSION_CANCELLED_OUTAGE` *(US-03.12, Should)* |
| Mất mạng | Giữ số đếm theo mốc đã nhận; dòng phụ "Đang kết nối lại…". Chưa ghi nên không tính DISCONNECTED/LOST trong COUNTDOWN | BR-05, BR-19 (chỉ áp từ ACTIVE). Nếu đến `started_at` vẫn mất mạng: theo V-10 |
| Rời app trong lúc đếm | Không ghi, không GRACE. Khi quay lại trước `started_at`: tiếp tục đếm. Không quay lại trước `started_at`: server đặt GRACE từ `started_at`, trừ lượt khoan hồng → khi mở app thấy V-09 | AC-03.02.4, BR-64 (đề xuất, Q-84) |
| Gói gửi sớm do đồng hồ máy nhanh | Không hiển thị gì khác; server bỏ qua gói | AC-03.02.7 |

## Câu chữ chính
- Tiêu đề (đọc màn hình): "Phiên sắp bắt đầu"
- "Chưa ghi — bắt đầu ghi lúc ‹hh:mm:ss›"
- "Ở lại trong app. Rời app sau khi bắt đầu sẽ báo tên bạn cho cả nhóm và làm cả phiên mất thưởng."
- "Bạn có thể khóa hoặc úp máy — khóa màn hình không tính là rời app."
- "Đang đồng bộ giờ…" / "Đang kết nối lại…"

## Điều cấm
- Không hiện "Phiên đang được ghi" trước `started_at` (NFR-P08 "khi và chỉ khi").
- Không đếm theo đồng hồ máy (BR-03).
- Không hiệu ứng động ngoài việc đổi số (DESIGN.md).
- Không danh sách tên/trạng thái người khác; không nút "Sẵn sàng" lặp lại (chờ T-BA-96).
- Không nút hủy/thoát; nút "Rời phiên" (D-29, BR-118) có ở V-06 (WAITING → ABSENT) và V-08 (ACTIVE/GRACE/PAUSED → EXITED), không có trên màn đếm ngược 5s; rời app ở đây theo BR-64 (AC-03.04.10 (b)); không Coins "at risk", không cược (D-01).
- Không âm thanh, không rung (tránh dụ cầm máy).

## AC liên quan
AC-03.02.1, .2, .3, .4, .5 (Should), .6, .7.
