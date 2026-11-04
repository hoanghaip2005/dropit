# 16 — Mời thành viên từ màn nhóm

Ngày: 28/10/2026. Phạm vi: `GroupDetailScreen` thành viên và `InviteScreen`; source audit theo yêu cầu hiện tại + quyết định D01/D10.

## Phân xử

- **SỬA:** thành viên thấy CTA Mời thành viên trong chi tiết nhóm; dùng cùng mã, link consent và QR đã có. Thành viên chỉ đọc/chia sẻ, không được đổi mã.
- **GIỮ:** consent vẫn bắt buộc ở người nhận; không thêm quyền mời/xem dữ liệu ngoài mã công khai.
- **CHƯA XÁC MINH HÌNH ẢNH:** chưa có ảnh runtime đúng build/role/viewport.

## Kiểm thử

`flutter test test/member_invite_test.dart`: 3 đạt.

## Bổ sung — nội dung clipboard “Chép mã” — 05/11/2026

- **Yêu cầu:** bấm “Chép mã” sao chép chính xác mã mời 8 ký tự, không kèm câu dẫn.
- **Audit nguồn/app:** nút trước đây sao chép `Tham gia nhóm trên DropIt! bằng mã: <code>`; assertion test `contains` nên không bắt được lỗi. “Chép link nhóm” đã sao chép URL riêng.
- **Phân xử:** SỬA hành vi clipboard của “Chép mã”; GIỮ nguyên “Chép link nhóm”, QR, quyền đổi mã và giao diện.
- **Triển khai:** `group_screens.dart` sao chép `c` trực tiếp; `member_invite_test.dart` so sánh clipboard bằng đúng `ABCDEFGH`.
- **Kiểm tra:** kiểm thử mục tiêu `member_invite_test.dart`; diff whitespace `git diff --check`.
- **Ảnh/build:** không yêu cầu thay đổi hình ảnh; thay đổi chỉ ở clipboard. **CHƯA XÁC MINH HÌNH ẢNH**. Screenshot người dùng cung cấp là trạng thái trước thay đổi, không chứng minh hành vi sau.
- **Kiểm tra độc lập:** audit nguồn reference, app và phân xử hoàn tất; chưa có ảnh/runtime sau thay đổi để nghiệm thu hình ảnh.
