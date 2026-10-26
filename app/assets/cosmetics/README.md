# DropIt! — bộ vật phẩm

## Khung avatar 3D

Ba khung `frame_leaf.png`, `frame_sunset.png`, `frame_galaxy.png` được render bằng Blender Cycles, 768×768 RGBA, tâm trong suốt. Chất liệu lần lượt là lá ngọc/vàng, vàng/hổ phách, bạch kim/thạch anh tím. App dùng PNG ở Shop, xem thử và hồ sơ; SVG cũ giữ làm nguồn tham khảo.

Scene: `app/design/avatar_frames.blend`. Script tái tạo: `app/scripts/render_blender_frames.py`, chạy trong Blender qua MCP `execute_code`. Script tạo scene riêng, giữ scene ban đầu. Avatar chiếm 62% chiều rộng artwork.

## Artwork vector còn lại

## Bộ mở rộng 3D

`render_cosmetics_expansion.py` dựng 6 khung (frost, phoenix, tidal, cyber, sakura, royal) và 4 biểu tượng danh hiệu (ice_guardian, flame_keeper, ocean_soul, crowned). PNG RGBA 768×768; khung giữ cùng kích thước lỗ avatar. Scene lưu tại `app/design/cosmetics_expansion.blend`. Danh mục và giá nằm trong `backend/db/seed-cosmetics.sql`, áp dụng qua `npm run db:seed` hoặc khi khởi tạo DB mới. Không tự cấp quyền sở hữu, không thay số dư Coins.

Thiết kế gốc bằng SVG; không dùng ảnh người mẫu hoặc ảnh render opaque làm khung.

- frame_leaf: vòng nguyệt quế xanh, huy chương lá.
- frame_sunset: tia nắng vàng đồng, huy chương mặt trời.
- frame_galaxy: quỹ đạo tím, sao và hành tinh.
- bg_library: tủ sách, sách mở, ánh sáng ấm.
- bg_night_sea: trăng, sao, sóng biển, thuyền buồm.
- bg_misty_forest: rừng thông, mặt trời, dải sương.
- title_night_owl: khiên cú đêm, ruy băng tím.
- title_early_bird: khiên bình minh, ruy băng đồng.

Khung viewBox 200×200, tâm trống; avatar nằm từ 29 đến 171. Nền 600×360 có màu nhẹ để chữ hồ sơ giữ tương phản. Danh hiệu gồm huy hiệu SVG và nhãn live text để đọc được bằng trình đọc màn hình.

Nguồn tái tạo: app/scripts/generate_cosmetics.py. Không animation trong Lockdown.

## Huy hiệu thành tích

13 SVG `badge_*.svg`: STREAK (3/7/14/30/60/100), SESS (10/50/100/500), HOURS (10/50/100). Ba họa tiết: lửa, dấu hoàn thành, đồng hồ cát. Mốc cao có thêm nguyệt quế và sao. Số mốc là live text, không phụ thuộc font trong SVG. Chưa đạt được chuyển xám ở renderer; điều kiện mở khóa và quyền trưng bày tối đa 3 giữ theo backend.
