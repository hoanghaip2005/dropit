# V-24 Đăng xuất (xác nhận / bị chặn)

Story: US-01.02 (Must) · Quy tắc: BR-70, §3 #36 · Q: Q-66 · NFR: NFR-10 · Token: DESIGN.md

## Mục đích
Cho người dùng đăng xuất an toàn; chặn đăng xuất khi đang trong phiên để không tạo cách thoát không bị ghi.

## Vai trò
Người dùng đã đăng nhập.

## Lối vào / lối ra
- Vào: V-22 nút "Đăng xuất" (cuối màn).
- Ra: xác nhận → V-02; hủy → V-22.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Hộp xác nhận | "Đăng xuất khỏi DropIt! trên máy này?" · "Bạn sẽ không nhận thông báo của nhóm trên máy này cho đến khi đăng nhập lại." | AC-01.02.1 |
| Nút | "Đăng xuất" (đen), "Hủy" (trắng) | DESIGN.md |
| Hộp chặn (đang trong phiên) | "Bạn đang trong phiên ‹Tên lịch›. Không đăng xuất được cho đến khi phiên của bạn kết thúc lúc ‹hh:mm›." Nút "Đã hiểu" | BR-70, AC-01.02.3 |
| Nút "Đăng xuất" ở V-22 khi đang trong phiên | Khóa (xám), chú thích "Không đăng xuất được khi đang trong phiên" | mockup/user_profile (đợt 3) |

API: `POST /auth/logout` (thu hồi refresh token, hủy đăng ký push của máy).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Hộp xác nhận → V-02 |
| Đang trong phiên (WAITING/FOCUSING/GRACE/PAUSED/DISCONNECTED) | Hộp chặn |
| Đang xử lý | "Đang đăng xuất…" |
| Mất mạng | Vẫn xóa token cục bộ, về V-02; thu hồi phía server khi có mạng (AC-01.02.2, giả định) |
| Lỗi server | Như mất mạng |
| Đang tải / rỗng | Không áp dụng |

## Câu chữ chính
- "Đăng xuất khỏi DropIt! trên máy này?"
- "Không đăng xuất được khi đang trong phiên."

## Điều cấm
- Không cho đăng xuất trong phiên (BR-70); không coi đăng xuất là cách rời phiên hợp lệ.
- Không giữ token push sau khi đăng xuất (không nhận `MEMBER_EXITED` của nhóm trên máy đã đăng xuất, VQ-10).

## AC liên quan
AC-01.02.1, .2, .3.
