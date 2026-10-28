# 12 — Quản lý nhóm/lịch theo yêu cầu mới

28/10/2026. Ownership group_management: group_screens.dart, membership_screens.dart, tests riêng. Root sở hữu API/models/providers/dependencies. Không sửa file ngoài phạm vi hoặc hoàn tác đồng đội.

## Audit nguồn và phân xử trước triển khai

- Nguồn ưu tiên: yêu cầu9 mục người dùng 28/10 và ảnh chi tiết nhóm đính kèm. Reuse decision owner canvas xám/card trắng không viền, nút đen/chữ trắng; không redesign nguyên view. Audit mã nguồn: OwnerSessions đang tải/hiện toàn bộ7 ngày + tương lai; không phân trang. CreateGroup đưa thẳng invite; invite chỉ mã chữ. Duration chỉ25/50. Owner thiếu xóa nhóm.
- SỬA lịch phiên: mỗi trang5 mục, điều khiển Trước/Sau và số trang; phân trang server bằng cursor, giữ lỗi/retry/empty rõ ràng, không giả danh sách client.
- SỬA tạo nhóm: thành công về chi tiết nhóm; mã mời là hành động riêng.
- THÍCH NGHI mã mời: thêm QR đen/trắng trỏ consent URL cùng mã; mã chữ/copy vẫn có để accessibility, không dùng dịch vụ QR bên ngoài.
- SỬA thời lượng: nhận số phút nguyên1..240 theo giới hạn server; giữ25/50 là shortcut, thêm input trực tiếp cả tạo/sửa. Coins không hứa thưởng mới ngoài contract root/backend.
- THÍCH NGHI xóa nhóm: chỉ owner, xác nhận rõ nhóm bị lưu trữ, thành viên mất truy cập, lịch chưa diễn ra bị hủy; lịch sử/kết quả được giữ. Server chặn khi đang có phiên. UI không tự xóa bản ghi hoặc sửa phiên thật để chụp.
- GIỮ riêng owner/member permissions, member không có nút xóa. Không suy khác mockup là lỗi.

## Tiêu chí/kiểm tra

Test navigation sau create, cursor next/previous không quá5 mục, QR có payload đúng mã, input duration ngoài khoảng bị chặn, xóa cần xác nhận + lỗi không mất context. Root/verifier khác implementer kiểm lại. CHƯA XÁC MINH HÌNH ẢNH build mới; không đánh dấu visual PASS từ tests.
