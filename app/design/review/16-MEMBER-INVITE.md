# 16 — Mời thành viên từ màn nhóm

Ngày: 28/10/2026. Phạm vi: `GroupDetailScreen` thành viên và `InviteScreen`; source audit theo yêu cầu hiện tại + quyết định D01/D10.

## Phân xử

- **SỬA:** thành viên thấy CTA Mời thành viên trong chi tiết nhóm; dùng cùng mã, link consent và QR đã có. Thành viên chỉ đọc/chia sẻ, không được đổi mã.
- **GIỮ:** consent vẫn bắt buộc ở người nhận; không thêm quyền mời/xem dữ liệu ngoài mã công khai.
- **CHƯA XÁC MINH HÌNH ẢNH:** chưa có ảnh runtime đúng build/role/viewport.

## Kiểm thử

`flutter test test/member_invite_test.dart`: 3 đạt.
