# V-46 Chi tiết phiên của nhóm (chủ nhóm)

Story: US-08.10 (Must), US-04.06 (Must, phần hiện giải trình) · Quy tắc: BR-23, BR-28, BR-29, BR-32, BR-34, BR-38, BR-39, BR-53, BR-61, BR-73, BR-85, BR-87, BR-115, BR-116 · Quyết định: D-03, D-10, D-12, D-19, D-20, D-22, D-25, D-28 · NFR: NFR-11, NFR-P02, NFR-P19, NFR-P06, NFR-P07, NFR-P10, NFR-P18 · Token: DESIGN.md
Thắng `mockup/t_07_xem_l_i_v_x_c_nh_n_phi_n` khi lệch (T-BA-91, T-BA-105).

## Mục đích
Cho chủ nhóm biết ai đã rời app, lúc nào, giải trình gì, sau khi sự kiện đã được server ghi. Màn **chỉ đọc**, **không thời gian thực**, **không** có thao tác can thiệp phiên.

## Vai trò
Chủ nhóm hiện tại của nhóm có phiên. Thành viên, chủ nhóm nhóm khác, quản trị: không có màn này (403, AC-08.10.7).

## Lối vào / lối ra
- Vào: chạm thông báo `MEMBER_EXITED` ở V-16; chạm phiên ở V-40 (danh sách phiên của nhóm); chạm phiên ở V-48 / V-49 (AC-08.02.9).
- Ra: chạm dòng rời app → V-47; phiên SCHEDULED → "Sửa / hủy lịch" → V-45; nút quay lại → màn trước.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Đầu màn | Tên lịch · ngày · giờ bắt đầu–kết thúc (giờ server) · thời lượng 25/50 phút · nhãn trạng thái phiên (Đã lên lịch / Đang đếm ngược / Đang diễn ra / Đã kết thúc / Đã hủy) | BR-116 |
| Dòng mất thưởng | Khi `forfeited = true`: "Phiên mất thưởng tập thể do ‹Tên› rời phiên". Khi false và đã kết thúc: "Phiên không mất thưởng" | BR-38, BR-39, BR-87 |
| Khối "Rời app" | Mỗi EXITED đã xác nhận: tên · giờ rời (giờ server, hh:mm:ss) · giải trình rút gọn hoặc "Chưa có giải trình" · nhãn "đã sửa lúc …" nếu có · nhãn "Đã miễn trừ" (chỉ khi US-04.08 trong phạm vi). Sắp theo giờ server tăng dần | BR-61, BR-85, NFR-P10, AC-08.10.1, AC-04.06.6 |
| Khối "Thành viên trong phiên" (chỉ khi phiên đã kết thúc) | Mỗi dòng: tên + trạng thái kết thúc (Hoàn thành / Rời app / Mất kết nối / Vắng / Đã rời nhóm / Không tính). Sắp theo tên A→Z | BR-32, BR-115, BR-116, AC-08.10.2 |
| Cờ vào muộn, số lần tạm dừng + lý do | Chỉ khi US-03.11 / US-03.06 (Should) trong phạm vi | BR-116, 04 §2 mục 2 |
| Dòng chú thích cuối | "Bạn chỉ xem được sự kiện đã ghi. Bạn không tham gia và không điều khiển phiên." | D-25, BR-116 |

API: `GET /groups/{gid}/sessions/{sid}` — chỉ chủ nhóm hiện tại của `gid`; mỗi lần gọi ghi nhật ký truy cập (BR-73, AC-08.10.3). Phản hồi **không** có trường trạng thái tức thời, heartbeat, Coins, chuỗi.

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường — đã kết thúc | Đầu màn + dòng mất thưởng + khối Rời app + khối Thành viên |
| Phiên SCHEDULED | Đầu màn + "Phiên chưa bắt đầu." + nút "Sửa / hủy lịch" (→ V-45). Không danh sách thành viên |
| Phiên COUNTDOWN / ACTIVE | "Phiên đang diễn ra — kết quả có sau khi kết thúc." + khối Rời app chỉ gồm EXITED đã xác nhận. **Không** khối Thành viên, không đồng hồ, không tự làm mới theo giây (AC-08.10.4) |
| Rỗng — không ai rời app | "Không có ai rời app." (AC-08.10.8); người LOST chỉ ở khối Thành viên với "Mất kết nối" |
| Phiên CANCELLED | "Phiên đã hủy lúc hh:mm." Không danh sách, không sự kiện (AC-08.10.10) |
| Biên — nhóm đầy, cả 10 EXITED | Khối Rời app 10 dòng theo giờ; khối Thành viên 10 dòng theo tên; không dòng chủ nhóm (AC-08.10.9) |
| Đang tải | Khung xương |
| Lỗi tải | "Chưa tải được chi tiết phiên." + "Thử lại" |
| Lỗi quyền (403) | "Bạn không có quyền xem phiên này." Không lộ tên, không lộ giải trình (AC-08.10.7) |
| Mất mạng | Bản đã lưu (nếu có) + "Chưa cập nhật — đang ngoại tuyến"; không có bản lưu → "Cần kết nối mạng để xem." |
| Có sự kiện mới khi đang mở | Không tự đẩy theo thời gian thực, không tự làm mới định kỳ; **chỉ** kéo xuống để làm mới (D-28) |

## Câu chữ chính
- "Phiên mất thưởng tập thể do ‹Tên› rời phiên"
- "‹Tên› — 09:10:03 — ‹giải trình›" / "‹Tên› — 09:15:40 — Chưa có giải trình"
- "Phiên đang diễn ra — kết quả có sau khi kết thúc."
- "Không có ai rời app."
- "Phiên đã hủy lúc hh:mm."

## Điều cấm
- Không nút Nhắc, Rung, Tạm dừng, Kết thúc sớm, Kéo dài, Đuổi người, Duyệt/Hoàn tất phiên, Bảo lưu chuỗi, nhắn vào phiên; các đường dẫn API đó trả 404 (AC-08.10.5, BR-116).
- Không trạng thái tức thời từng người: FOCUSING, GRACE, PAUSED, DISCONNECTED, online/offline, "đang rời app", heartbeat, đồng hồ đếm từng người (AC-08.10.4, BR-28, NFR-P02).
- Không Coins, chuỗi, điểm, hạng, tên app, nội dung máy, vị trí, số lần thoát tích lũy (AC-08.10.6, BR-34, BR-53).
- Không "thời lượng ngoài app" (VQ-08).
- Không sắp theo trạng thái/chỉ số; không tô "tốt nhất/tệ nhất" (BR-115).
- Không nút sửa/xóa giải trình hay sự kiện (AC-04.06.5, BR-32).

## AC liên quan
AC-08.10.1 … .11; AC-04.06.1, .5, .6; AC-08.02.9.
