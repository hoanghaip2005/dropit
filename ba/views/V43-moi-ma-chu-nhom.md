# V-43 Mời thành viên (mã mời — phía chủ nhóm)

Story: US-02.03 (Must); US-02.04 mời email (Should) · Quy tắc: BR-74, BR-75, BR-76, BR-80, §Trạng thái nhóm · Quyết định: D-02, D-10, D-21 · Q: Q-73, Q-141 · NFR: NFR-11 · Token: DESIGN.md

## Mục đích
Cho chủ nhóm lấy mã 8 ký tự của nhóm để chia sẻ, và đổi mã khi cần. Nói rõ: nhập mã chỉ mở màn đồng ý, chưa vào nhóm.

## Vai trò
Chủ nhóm của nhóm G.

## Lối vào / lối ra
- Vào: V-42 sau khi tạo nhóm; V-20 "Mời thành viên"; V-41 menu nhóm.
- Ra: quay lại màn trước.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Đầu màn | "Mời vào ‹Tên nhóm›" · sĩ số "7/10 thành viên" | BR-74 |
| Mã mời | 8 ký tự chữ-số, chia 2 cụm 4 (vd. `K7QM 2XPA`), `headline-lg`, số bảng; không có ký tự dễ nhầm (0/O, 1/I/L) | BR-76; `GET /groups/{id}/invite-code` |
| Nút "Sao chép" | Sao chép mã; toast "Đã sao chép mã." | AC-02.03.1 |
| Nút "Chia sẻ" | Bảng chia sẻ hệ thống với câu mẫu (dưới) | AC-02.03.1; VQ-09 |
| Hiệu lực | "Mã dùng được đến khi bạn tạo mã mới." | BR-76 (đề xuất Q-73) |
| Nút "Tạo mã mới" | Chữ; mở hộp xác nhận | AC-02.03.2 |
| Hộp xác nhận | "Tạo mã mới? Mã ‹cũ› sẽ hết hiệu lực ngay. Người đang giữ mã cũ sẽ không dùng được." · "Tạo mã mới" / "Hủy" | BR-76 |
| Giải thích quy trình | "Người nhận nhập mã → đọc điều khoản minh bạch → chỉ khi bấm 'Đồng ý' mới vào nhóm. Mỗi người chỉ thuộc một nhóm." | BR-76, D-21, US-01.05 |
| Mời bằng email *(US-02.04, Should)* | Ẩn khi chưa trong phạm vi | — |

Câu mẫu chia sẻ (VQ-09): "Mời bạn vào nhóm ‹Tên nhóm› trên DropIt!. Mở app, chọn 'Nhập mã' và nhập: ‹MÃ›. Bạn sẽ đọc điều khoản trước khi đồng ý vào nhóm."

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Mã + các nút |
| Nhóm đủ 10 thành viên | Vẫn hiện mã; dải: "Nhóm đã đủ 10 thành viên — người mới sẽ bị từ chối khi đồng ý." (BR-74 kiểm lúc đồng ý; đề xuất VQ-06) |
| Nhóm dưới 4 | Dải: "Nhóm dưới 4 người — mời thêm." |
| Nhóm CHỜ GIẢI TÁN / ĐÃ GIẢI TÁN | Không hiện mã; "Nhóm đang giải tán — không nhận thành viên mới." (AC-02.03.6, BR-80) |
| Nhóm TẠM NGƯNG LỊCH | Vẫn hiện mã **(giả định)**; dải "Lịch của nhóm đang tạm ngưng." |
| Đang tạo mã mới | Nút khóa "Đang tạo…" |
| Lỗi tạo mã mới | "Chưa tạo được mã mới. Mã cũ vẫn dùng được." |
| Đang tải | Khung xương ô mã |
| Lỗi tải | "Chưa tải được mã mời." + "Thử lại" |
| Mất mạng | Hiện mã đã lưu + "Chưa cập nhật"; "Tạo mã mới" khóa |
| Rỗng | Không áp dụng (nhóm luôn có mã, AC-02.01.1) |

## Câu chữ chính
- "Mã mời của nhóm"
- "Mã dùng được đến khi bạn tạo mã mới."
- "Tạo mã mới? Mã cũ sẽ hết hiệu lực ngay."
- "Người nhận chỉ vào nhóm sau khi đọc và đồng ý điều khoản minh bạch."

## Điều cấm
- Không mã QR, không liên kết công khai "toàn văn phòng", không hạn 24 giờ (T-BA-94).
- Không "thêm thẳng" ai vào nhóm mà bỏ qua màn đồng ý (T-BA-122, NFR-P04).
- Không hiện ai đã nhập mã nhưng chưa đồng ý, ai nhập sai (tránh lộ người đang ở nhóm khác, US-02.04 ghi chú).
- Không hiện cho chủ nhóm số lần nhập sai của người khác (BR-76 khóa theo tài khoản người nhập).
- Không đổi mã làm tăng phiên bản đồng ý (BR-71).

## AC liên quan
AC-02.03.1, .2, .6; AC-02.03.3, .4, .5, .7 là phía người nhập (V-04).
