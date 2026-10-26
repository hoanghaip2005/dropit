# Chủ nhóm — kế hoạch theo từng view

Chuẩn: `design-system.html` và `STITCH_DESIGN_SYSTEM.md`. Không thêm màu, outline, gradient hoặc bóng mới ngoài đặc tả. Nội dung và quyền hiện hành được giữ.

| Thứ tự | View | Phạm vi |
|---|---|---|
| 1 | Danh sách Nhóm | Canvas #F4F5F7, header, CTA, card trắng không viền, inset #F8F9FA, role, progress, navigation |
| 2 | Chi tiết nhóm | Header, tab, thành viên, trạng thái, lịch phiên và thao tác quản lý |
| 3 | Tạo nhóm / mời thành viên | Input, helper/error, mã mời, loading, xác nhận |
| 4 | Lịch phiên / đặt lịch / sửa lịch | Card lịch, bộ chọn thời gian, thời lượng, validation và cancel |
| 5 | Chi tiết phiên | Trạng thái, người tham gia, kết quả, hành động theo vòng đời phiên |
| 6 | Báo cáo / báo cáo thành viên | Bộ lọc nhóm–tháng, chỉ số riêng nhóm, bảng/danh sách, giải trình |
| 7 | Hồ sơ / thông báo / khiếu nại | Card hồ sơ, setting, trạng thái đọc, dialog và quyền riêng tư |

Mỗi đợt chỉ sửa view được chọn và component thật sự cần cho view đó. Đối chiếu màu nền toàn màn và inset riêng; không chỉ đổi token. Kiểm tra 320px, 390px, 768px, tên dài, tỷ lệ null, chưa có lịch, trạng thái tạm ngưng, loading/error/empty. Chạy analyze và kiểm thử liên quan, build web, gửi URL phiên bản mới. Không tự chuyển sang view tiếp theo trước khi người dùng phản hồi view hiện tại.

View 1 đã triển khai; tiếp tục View 2 theo yêu cầu “làm đi”. View 2 bổ sung summary nhóm, trạng thái, thao tác mời/đặt lịch, card lịch và card thành viên bo 32 không viền. Kiểm thử 320/390/768px với tên dài, tạm ngưng lịch và lịch trống. Các view 3–7 chưa được coi là hoàn thiện dù đang kế thừa theme chủ nhóm.

Ưu tiên mới: Hồ sơ chủ nhóm theo phản hồi “view hồ sơ chưa được”. Card hero trắng thay CosmeticSurface mặc định; avatar và nút đổi ảnh 44px, tên/vai trò, sửa hồ sơ. Quản lý tách khỏi cá nhân; thêm lối tắt lịch phiên. Không tải Shop khi là chủ nhóm; không hiện email/Coins/chuỗi/huy hiệu. Giữ khóa đăng xuất khi đang trong phiên và xác nhận đăng xuất.

Ưu tiên tiếp: Báo cáo theo phản hồi “lược bớt, mục đích sử dụng không cần show”. Bỏ PurposeCard khỏi các view báo cáo, giữ trường dữ liệu và luồng đồng ý hiện hành. Chủ nhóm còn nhãn kỳ, bốn card số liệu bo 32, bảng tên A–Z và ngày cập nhật nhỏ. Bỏ ghi chú email, giải thích dài dưới chỉ số; bảng có divider trung tính. Không thêm PDF/biểu đồ không có dữ liệu backend.
