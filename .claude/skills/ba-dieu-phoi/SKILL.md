---
name: ba-dieu-phoi
description: Chạy một vòng điều phối BA cho DropIt! — chọn việc Sẵn sàng trong ba/01-viec-ba.md, giao cho agent ba-* song song, cập nhật trạng thái và sổ quyết định. Gọi khi người dùng nói "chạy BA", "điều phối BA", "/ba-dieu-phoi [đợt|mã việc]".
---

1. Đọc `CLAUDE.md`, `ba/00-dieu-phoi.md`, `ba/01-viec-ba.md`, `ba/02-so-quyet-dinh.md`.
2. Xác định việc cần chạy: theo đối số (mã `T-BA-xx` hoặc `dot-1/2/3`); nếu không có, lấy mọi việc `Sẵn sàng`. Việc có phụ thuộc chưa `Xong` thì bỏ qua và báo lại.
3. Giao song song cho agent ghi ở cột Agent (mỗi việc một agent), dùng mẫu câu giao việc ở `00-dieu-phoi.md` §4. Việc của “điều phối” thì tự làm.
4. Nhận kết quả: đổi trạng thái sang `Review`; mở khóa các việc phụ thuộc (`Chặn` → `Sẵn sàng`); thêm Q- mới vào sổ; ghi BR còn thiếu thành việc mới.
5. Nếu vừa xong một đợt: chạy `ba-reviewer`, chuyển lỗi Cao thành việc mới.
6. Báo người dùng: việc đã xong, câu hỏi Q- cần họ chốt, việc kế tiếp.

Không bao giờ tự chốt Q- thành D-; chỉ người dùng chốt.
