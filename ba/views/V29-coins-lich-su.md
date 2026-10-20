# V-29 Coins của tôi và lịch sử

Story: US-06.02 (Must) · Quy tắc: BR-40, BR-41, BR-43, BR-44, BR-45, BR-53, BR-107 · Quyết định: D-09 · Q: Q-23, Q-101 · NFR: NFR-21, 04 §3 dòng Coins · Token: DESIGN.md

## Mục đích
Cho người dùng biết số dư, Coins đã nhận hôm nay so với trần, và từng lần cộng/trừ.

## Vai trò
Người dùng (chính mình). Chủ nhóm không có chỗ xem Coins của thành viên (AC-06.02.4).

## Lối vào / lối ra
- Vào: chip Coins ở V-03 / V-22; "Xem lịch sử Coins" ở V-12.
- Ra: "Đến Shop" → V-30; chạm dòng thưởng phiên → màn kết quả phiên đó (V-12).

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Số dư | Số lớn `headline-xl`, màu `#B02F00`, số bảng; nhãn "Coins" | BR-44 (tổng `amount`); `GET /me/coins` |
| Hôm nay | Chip `#FFF1EC` chữ `#B02F00`: "Hôm nay: 35/100" | BR-43; tổng `SESSION_REWARD` có `reward_date` = hôm nay (UTC+7) |
| Cách nhận | "Phiên 25 phút: +10 · Phiên 50 phút: +25 · Tối đa 100 Coins mỗi ngày. Chỉ phiên hoàn thành có thưởng mới có Coins." | D-09, BR-40 — số lấy từ cấu hình, không viết cứng |
| Danh sách lịch sử | Mới nhất trước; mỗi dòng: thời điểm (UTC+7), "+10" / "−80" (số bảng), loại, mô tả | AC-06.02.2; `GET /me/coins/ledger?cursor=` |
| Loại | "Thưởng phiên" · "Mua đồ" · "Điều chỉnh" | `type` BR-44 |
| Mô tả | Thưởng phiên: tên nhóm + 25/50 phút (+ "đạt trần" nếu bị cắt). Mua đồ: tên món. Điều chỉnh: lý do quản trị nhập | BR-43, BR-45, BR-107 |
| Màu số | Cộng: `#1B7F3B`; trừ: `#111111` (không dùng đỏ — mua đồ không phải lỗi) | DESIGN.md |
| Chú thích cuối | "Phiên 0 Coins (mất thưởng tập thể, mất kết nối, vắng) không có dòng ở đây. Xem lý do ở kết quả phiên." | BR-41, đề xuất Q-101 |
| Nút | "Đến Shop" (đen) | — |

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Như trên |
| Đạt trần | "Hôm nay: 100/100 — đã đạt trần, phiên tiếp theo hôm nay không cộng Coins." (AC-06.02.6) |
| Tài khoản mới | Số dư 0; lịch sử: "Chưa có giao dịch. Hoàn thành phiên để nhận Coins." (AC-06.02.3) |
| Đang tải | Khung xương; không hiện 0 tạm |
| Lỗi | "Chưa tải được Coins." + "Thử lại" |
| Lỗi tải trang kế | Dòng đã tải giữ nguyên; cuối danh sách "Thử lại" |
| Mất mạng | Số dư lần tải gần nhất + nhãn "Có thể chưa cập nhật"; nút "Đến Shop" vẫn mở nhưng mua bị khóa ở V-31 (AC-06.02.5) |

## Câu chữ chính
- "Hôm nay: ‹x›/100"
- "Đã đạt trần, phiên tiếp theo hôm nay không cộng Coins."
- "Chỉ phiên hoàn thành có thưởng mới có Coins."
- "Phiên 0 Coins không có dòng ở đây. Xem lý do ở kết quả phiên."

## Điều cấm
- Không nạp tiền, không mua Coins, không quy đổi ra tiền/quà thật (D-03).
- Không chuyển/tặng Coins cho người khác (BR-44; T-BA-118).
- Không "Double Coin", hệ số, thưởng chuỗi (D-09, BR-51).
- Không dòng "0 Coins" ghi vào sổ cái (BR-41).
- Không so Coins với người khác; không hiện Coins trên hồ sơ công khai (BR-99).
- Không sửa/xóa dòng lịch sử (BR-44 bất biến).

## AC liên quan
AC-06.02.1, .2, .3, .4, .5, .6, .7.
