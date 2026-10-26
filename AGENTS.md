# DropIt! — công việc giao diện

Chỉ áp dụng khi thay đổi hoặc đánh giá UI/UX. Không mở rộng sang tác vụ backend không liên quan.

1. Đọc `app/design/review/README.md`, `app/design/review/DECISIONS.md`, `app/design/review/BACKLOG.md` trước khi sửa view.
2. Với mỗi đợt UI, dùng các agent đối chiếu nguồn, audit app và phân xử khác biệt theo các prompt trong `app/design/review/agents/`. Có thể tái sử dụng audit còn đúng nguồn/phiên bản; không audit lặp vô ích.
3. Chỉ một agent triển khai sở hữu mỗi file/view tại một thời điểm. Agent khác không hoàn tác thay đổi ngoài phạm vi.
4. Agent kiểm tra cuối phải khác agent triển khai. Kiểm thử qua không tương đương giao diện đạt. Thiếu ảnh app đúng build/trạng thái → ghi `CHƯA XÁC MINH HÌNH ẢNH`, không kết luận khớp design.
5. Khác Stitch không tự động là lỗi. Quyết định theo yêu cầu người dùng, domain/quyền riêng tư, dữ liệu thật, accessibility và nguồn thiết kế; ghi lý do giữ/đổi vào decision log.
6. Mỗi đợt một view hoặc một component có phạm vi rõ. Ghi ảnh, build, diff, quyết định, kiểm thử và vòng kiểm tra lại trong hồ sơ view. Không coi toàn bộ vai trò đã hoàn thiện chỉ vì đổi theme dùng chung.
7. Không đọc/in/lưu khóa truy cập vào hồ sơ audit. Không đổi dữ liệu thật để làm ảnh đẹp; dữ liệu mẫu phải được nhận diện rõ.
