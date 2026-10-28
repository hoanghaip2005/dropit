# 15B — Chủ nhóm sửa lịch từ tab Lịch

Ngày: 28/10/2026. Phạm vi: `/owner/schedule`; file sở hữu `app/lib/features/reports/report_screens.dart`. Không đổi màn sửa lịch hoặc nhóm.

## Nguồn và quyết định

- Nguồn ưu tiên: yêu cầu người dùng 28/10: tab Lịch phải sửa phiên trực tiếp, không đi vòng qua tab Nhóm.
- Audit nguồn trước: `_GroupSchedules` hiển thị ListRow chỉ có StatusBadge, không có `onTap` hoặc nút sửa. Đây là thiếu hành động, không phải API cấm sửa.
- SỬA: mỗi phiên SCHEDULED còn ở tương lai có nút “Sửa” kèm icon; chạm dòng cũng mở route sửa hiện có `/owner/sessions/:id/edit`.
- GIỮ: không cho sửa phiên đã bắt đầu; quyền thực vẫn do API xác minh. Không đổi token toàn app.
- SỬA: quay lại từ sửa lịch và kéo làm mới tab phải tải lại lịch từng nhóm quản lý, tránh danh sách cũ.

## Kiểm tra

- `flutter test test/owner_schedule_hub_test.dart`: 2/2 đạt; rộng 320 và 390, bấm nút đến đúng route, quay về tải lại lịch; không overflow.
- Test không thay thế ảnh runtime. **CHƯA XÁC MINH HÌNH ẢNH**: chưa có ảnh production đúng build/trạng thái; chờ verifier khác triển khai kiểm lại.
- Diff: thêm hành động sửa tại dòng, refresh schedule providers khi trở lại và pull-to-refresh.

Trạng thái: CHỜ VERIFIER. Không dùng dữ liệu thật để làm ảnh, không ghi khóa truy cập.
