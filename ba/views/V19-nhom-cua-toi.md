# V-19 Nhóm của tôi (vai trò theo nhóm)

Story: US-01.04 (Must), US-02.06 (Must) · Quy tắc: BR-74, BR-75, BR-114, BR-115, BR-117, §Trạng thái nhóm · Quyết định: D-10, D-21, D-25 · NFR: NFR-11, NFR-P06 · Token: DESIGN.md

## Mục đích
Cho người dùng thấy nhóm mình là **thành viên** (tối đa 1, D-21) và các nhóm mình là **chủ nhóm**, với nhãn vai trò rõ ràng; chức năng quản lý chỉ hiện ở nhóm mình làm chủ.

## Vai trò
Mọi người dùng đã đăng nhập.

## Lối vào / lối ra
- Vào: tab "Nhóm" trên thanh điều hướng; sau khi rời nhóm (V-21) hoặc bị xóa.
- Ra:
  - Chạm nhóm "Thành viên" → V-20 (chế độ thành viên).
  - Chạm nhóm "Chủ nhóm" → V-41 / V-20 (chế độ chủ nhóm).
  - "Báo cáo của tôi" → V-34.
  - Trạng thái trống → "Nhập mã" (V-04) / "Tạo nhóm" (V-42).

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Khối "Nhóm tôi tham gia" | 0 hoặc 1 thẻ: tên nhóm, nhãn "Thành viên", tên chủ nhóm, sĩ số "7/10", phiên kế tiếp | `GET /me/groups` → `role = member`; BR-75 a |
| Câu chú thích | "Bạn chỉ thuộc một nhóm tại một thời điểm." | D-21 |
| Khối "Nhóm tôi quản lý" | 0…N thẻ: tên nhóm, nhãn "Chủ nhóm", trạng thái nhóm (nếu khác HOẠT ĐỘNG), sĩ số, phiên kế tiếp | `role = owner`; BR-75 b |
| Câu chú thích | "Chủ nhóm chỉ quản lý, không tham gia phiên của nhóm mình." | D-25, BR-114 |
| Nhãn vai trò | Chip viên thuốc: "Thành viên" (nền trắng viền) / "Chủ nhóm" (nền đen chữ trắng) — chữ, không chỉ màu | NFR-20 |
| Trạng thái nhóm | Chỉ hiện khi khác HOẠT ĐỘNG: "TẠM NGƯNG LỊCH", "CHỜ GIẢI TÁN" | AC-02.06.1 |
| Cảnh báo sàn | Trên thẻ chủ nhóm khi sĩ số < 4: "Nhóm dưới 4 người — mời thêm" | BR-74 |
| Thứ tự | Nhóm tôi quản lý sắp theo **tên nhóm** A→Z | BR-117 |
| Nút | "Tạo nhóm" (luôn có, trừ khi đạt `max_groups_owned`); "Nhập mã" (chỉ khi chưa là thành viên nhóm nào) | BR-75 |
| Lối vào báo cáo | "Báo cáo của tôi" (khi đang/đã là thành viên) | US-08.03 |

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Hai khối như trên; khối rỗng thì ẩn |
| Rỗng (không nhóm nào) | "Bạn chưa ở nhóm nào." + "Nhập mã" + "Tạo nhóm" (AC-02.06.4) |
| Đạt giới hạn sở hữu | Nút "Tạo nhóm" khóa, chú thích "Bạn đã quản lý 10 nhóm — tối đa 10." (BR-75 b, Q-71) |
| Nhóm thành viên ĐÃ GIẢI TÁN | Không còn trong khối; dữ liệu cũ xem ở V-25 (AC-02.06.5) |
| Đang tải | Khung xương 2 thẻ |
| Lỗi | "Chưa tải được nhóm của bạn." + "Thử lại" |
| Mất mạng | Bản đã lưu + "Chưa cập nhật"; các nút tạo/nhập mã khóa |

## Câu chữ chính
- "Nhóm tôi tham gia" / "Nhóm tôi quản lý"
- "Bạn chỉ thuộc một nhóm tại một thời điểm."
- "Chủ nhóm chỉ quản lý, không tham gia phiên của nhóm mình."
- "Bạn chưa ở nhóm nào."

## Điều cấm
- Không chỉ số cộng dồn nhiều nhóm (tổng phiên, tổng lần thoát, tỉ lệ chung); không so sánh/xếp nhóm theo chỉ số (AC-02.06.6, BR-117).
- Không chuỗi, Coins của ai trên màn này.
- Không hiện cho chủ nhóm A biết thành viên của A đang làm chủ nhóm nào khác (US-02.06 ghi chú).
- Không chức năng quản lý (mời, lịch, xóa, báo cáo nhóm) ở thẻ vai trò "Thành viên" (AC-01.04.2, AC-01.04.3).
- Không nút "Gán chủ nhóm", không chủ nhóm thứ hai (AC-01.04.5).

## AC liên quan
AC-01.04.1, .2, .3, .5; AC-02.06.1, .4, .5, .6; AC-02.01.6.
