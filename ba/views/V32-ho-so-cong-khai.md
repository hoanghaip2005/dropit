# V-32 Hồ sơ công khai của người cùng nhóm

Story: US-07.04 (Must — góc nhìn người cùng nhóm, AC-07.04.1); US-07.06 (Should — màn đầy đủ) · Quy tắc: BR-95, BR-96, BR-99, BR-73 (không ghi) · Quyết định: D-03, D-12 · Q: Q-94, Q-104, Q-106 · NFR: NFR-11, 04 §3 · Token: DESIGN.md

## Mục đích
Cho người cùng nhóm (kể cả chủ nhóm) thấy phần công khai của một người: tên, avatar, khung và hình nền đang trang bị, và huy hiệu/chuỗi nếu người đó tự bật.

## Vai trò
Thành viên hoặc chủ nhóm của **cùng nhóm** với người được xem.

## Lối vào / lối ra
- Vào: V-20 chạm một người.
- Ra: quay lại V-20. Không có lối sang dữ liệu phiên.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Hình nền đầu hồ sơ | Hình nền đang trang bị; mặc định nếu không có hoặc tải lỗi | BR-95, AC-07.04.3 |
| Avatar + khung | Avatar trong khung đang trang bị | BR-95, BR-96 |
| Tên hiển thị | `headline-md` | BR-97 |
| Vai trò trong nhóm | Chip "Chủ nhóm" / "Thành viên" | D-10 |
| Huy hiệu trưng bày | Tối đa 3, **chỉ** khi người đó bật | BR-99 (`showcase_max_badges = 3`) |
| Chuỗi | **Chỉ** khi người đó bật | BR-99, D-12 |
| Không có gì bật | Không hiện khối thành tích (không ghi "đã ẩn") **(giả định)** | — |

API: `GET /groups/{gid}/members/{uid}/profile` — 403 nếu người xem không cùng nhóm (AC-06.05.6). Không ghi nhật ký truy cập (BR-73, đề xuất Q-106).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Như trên |
| Ảnh khung/hình nền lỗi | Hiện mặc định, không lỗi màn (AC-07.04.3) |
| Món đã bị ẩn khỏi Shop | Vẫn hiện bình thường (AC-07.04.4) |
| Đang tải | Khung xương |
| Lỗi / 403 | "Không xem được hồ sơ này." |
| Mất mạng | Bản đã lưu (nếu có) + "Chưa cập nhật" |
| Rỗng | Người chưa có ảnh/đồ: avatar chữ cái đầu, khung + hình nền mặc định |

## Câu chữ chính
- "Chủ nhóm" / "Thành viên"
- "Không xem được hồ sơ này."

## Điều cấm
- Không Coins, số dư, danh sách đồ đã mua, giá (AC-06.05.5, BR-99).
- Không số lần thoát, kết quả phiên, điểm danh, phút tập trung — kể cả khi người xem là chủ nhóm (04 §3: dữ liệu phiên không xem qua hồ sơ).
- Không email.
- Không nút nhắn tin, kết bạn, theo dõi (EP-10 ngoài MVP).
- Không xếp hạng, Level, chức danh.

## AC liên quan
AC-07.04.1, .3, .4; AC-06.05.5, .6; AC-02.06.2.
