# 13 — Preview danh hiệu và đổi tên trong hồ sơ

28/10/2026. Phạm vi từng component: preview Shop danh hiệu/khung và popup đổi tên trên hồ sơ. Không redesign Shop/kho/theme.

## Nguồn và audit

- Yêu cầu mới người dùng mục8: xem danh hiệu với avatar đang dùng, không avatar mặc định; mục9: bỏ view sửa hồ sơ, sửa tên bằng popup ngay hồ sơ.
- Source hiện tại: Shop grid ItemPreview nhận name nhưng không nhận avatar URL; detail _TryOn có avatar URL nhưng không có khung đang dùng khi xem TITLE. Profile hero có camera riêng nhưng nút Sửa hồ sơ mở route/page khác.
- Nguồn visual giữ theo quyết định05A/05B: canvas trung tính, card trắng, artwork AI đã chấp nhận; popup theo control đen/trắng và thành viên cam/đen hiện tại. Không dùng dữ liệu mẫu làm dữ liệu thật.
- Audit mã nguồn, CHƯA XÁC MINH HÌNH ẢNH app đúng build. Không tuyên bố ảnh khớp Stitch.

## Phân xử độc lập

Root đã duyệt source arbitration: SỬA preview list/detail nhận avatar thật và khung đang trang bị; GIỮ mua và trang bị là hai thao tác riêng; mua đã refresh shop/inventory/me, không autoequip. SỬA nút Sửa hồ sơ thành Đổi tên popup 2–30 ký tự theo giới hạn UI đã thống nhất (PATCH API chấp nhận 1–40), GIỮ camera đổi avatar. Root redirect route cũ /profile/edit về /profile.

## Ownership / chấp nhận

profile_shop sở hữu profile_screens.dart, shop_screen.dart, tests liên quan; root API/router/deploy và verifier độc lập. Không hoàn tác tác vụ khác.
- Preview TITLE/AVATAR_FRAME lấy đúng avatarUrl; TITLE giữ frame theo me.frameItemId/catalog. Nếu chưa có dữ liệu không bịa ảnh mới.
- Mua không đổi trang bị; equip thay đổi phải refresh me/inventory để các preview tự cập nhật.
- Popup tên: tên hiện tại sẵn, trim, từ 2 đến 30 ký tự sau trim, loading khóa gửi lặp, lỗi API giữ popup, thành công refresh me. Camera và quyền riêng tư giữ nguyên.
- Chỉ thay cơ chế chỉnh tên, không mở rộng hồ sơ/Shop khác.

## Kiểm thử và ảnh

Đang triển khai. CHƯA XÁC MINH HÌNH ẢNH. Root thu ảnh đúng build và agent khác nghiệm thu.

### Kết quả source/test

- ShopArtworkPreview thay renderer của list FRAME/TITLE bằng avatarUrl hiện tại; TITLE giữ equippedFrameKey, detail _TryOn cũng giữ frame. BACKGROUND renderer giữ nguyên. Không tự trang bị khi mua; đường _reload sẵn có tiếp tục invalidate shop/inventory/me sau mua/trang bị.
- Profile cả hai vai trò mở popup Đổi tên trong hero; bỏ EditProfileScreen. Root sở hữu redirect route cũ. Popup 2–30 ký tự/trim, loading chặn gửi lặp, lỗi giữ input và retry; camera đổi avatar còn nguyên.
- 43 tests personalization + Shop list/detail đạt: avatar/frame resolve theo trang bị, TITLE tab truyền profile, Profile mở dialog tại chỗ, validation/loading/success/error retry, Shop responsive320/390/768 và text1.5/regression purchase idempotency.
- Chưa thu ảnh browser build mới; CHƯA XÁC MINH HÌNH ẢNH. Chờ root build/deploy và verifier khác.

