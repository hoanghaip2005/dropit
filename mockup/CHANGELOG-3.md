# CHANGELOG mockup — đợt 3 (2026-10-19)

Căn cứ: `ba/review/mockup-tong-hop.md` §1–§2, `ba/02-so-quyet-dinh.md` (D-01…D-26). Nguồn token duy nhất: `dropit/DESIGN.md` (T-BA-119). Đã xóa `screen.png` của mọi màn sửa; cần chụp lại.

## Xóa

- `social_feed`, `x_01_danh_s_ch_b_n_b`, `x_03_l_i_m_i_k_t_b_n`, `x_05_t_o_b_i_vi_t`: EP-10, ngoài MVP. (T-BA-116, T-BA-117, T-BA-118)
- `dropit_clean_food_app_style`: design system bị loại; dùng `dropit/DESIGN.md`. (T-BA-119)

## Design system — `dropit/DESIGN.md` (T-BA-119)

| Token | Cũ | Mới | Tỉ lệ (WCAG) |
| --- | --- | --- | --- |
| text-secondary | `#8E8E93` (2.99:1 trên `#F4F5F7`) | `#6C6C70` | 4.79:1 trên `#F4F5F7`; 5.23:1 trên `#FFFFFF` |
| accent (Coins, chữ/biểu tượng) | `#FF5722` (3.16:1 trên trắng) | `#B02F00` | 6.46:1 trên trắng; 5.92:1 trên `#F4F5F7`; 5.86:1 trên `#FFF1EC`; chữ trắng trên nút 6.46:1 |
| accent-decor | — | `#FF5722` | chỉ dùng trang trí, không làm chữ |
| success | `#34C759` (2.22:1) | `#1B7F3B` (chữ) | 5.07:1 trắng; 4.64:1 `#F4F5F7` |
| warning | `#FF3B30` | `#BA1A1A` | chỉ cho lỗi/cảnh báo thoát; **cấm** làm màu nhấn |
| lockdown-button | `#333333` (1.66:1 so với đen) | `#5C5C5C` | 3.14:1 so với `#000000`; nhãn trắng 6.69:1 |
| lockdown-text-secondary | — | `#A1A1A6` | 8.16:1 trên đen |

- Ghi rõ: Lockdown nền đen tĩnh, **không** hiệu ứng động (không glow/pulse/chuyển động; chỉ số đếm ngược đổi mỗi giây), có chỉ báo "Phiên đang được ghi". Một thanh điều hướng. Bỏ "gamified mechanics".
- Bảng tương phản đầy đủ nằm trong §Colors của DESIGN.md.

## Prompt — `dropit_ui_generation_prompt_..._1.md`

- Bỏ màu xung đột (`#FF5722` hoặc `#FF3B30` làm accent; `#8E8E93`; `#333333`), thay bằng token mới.
- Bỏ tính năng đã loại: danh mục/tìm phòng, chọn thời lượng và số người ở sảnh, vòng tiến độ cam + hiệu ứng ở Lockdown, "Bonus Streak Coins", "office manager". Thêm: phiên kế tiếp của nhóm, câu cảnh báo D-05/D-22, Coins D-09, báo cáo chủ nhóm sắp A→Z, Shop chỉ đồ trang trí, Trang bị/Gỡ.

## Sửa màn (áp màu mới qua cấu hình Tailwind: `secondary-container` → `#B02F00`, `on-secondary-container` → trắng; thay `#8E8E93/#FF3B30/#34C759/#FF5722`)

- **rewards_shop** — Bỏ "Double Coin Surge", nhãn độ hiếm (Rare/Elite/Mythic/New), loại Desk Pets/Audiopacks/Badges/Themes. Còn 3 tab Khung avatar / Hình nền / Danh hiệu; giá Coins; trạng thái "Đang dùng · Gỡ", "Đã sở hữu · Trang bị", toast "Thiếu N Coins". (T-BA-111, T-BA-86)
- **the_shop** — Bỏ "Daily Mystery Box / Free Roll", nhãn Epic/Popular, tab Badges/Themes, "pts". Tab Khung/Hình nền/Danh hiệu; mẫu "Đã sở hữu" + "Đang dùng · Gỡ". (T-BA-111, T-BA-112)
- **s_02** — Bỏ "+5% Xu/EXP", "HUYỀN THOẠI", "142 đồng nghiệp đã sở hữu", "Prime", nút tặng bạn bè, hiệu ứng Lockdown của vật phẩm, gradient động, pulse. "Xu" → Coins. Thêm khối ca lỗi: thiếu Coins, đã sở hữu, mất mạng không trừ Coins, bấm hai lần. (T-BA-113, T-BA-86)
- **s_06** — Bỏ Hạng/Level/XP/Điểm cống hiến, "Thần Kỷ Luật + 100 Xu", huy hiệu "Đội trưởng… dẫn dắt phòng", "Đại gia Xu", "Khắc tinh lật máy", "không chạm điện thoại", nút khoe lên Bảng tin. Huy hiệu theo BR-52 (chuỗi, phiên có thưởng, tổng giờ), ghi "không cộng Coins". Thêm công tắc "Hiện chuỗi và huy hiệu trên hồ sơ" mặc định tắt, có cảnh báo khi bật (NFR-P17). (T-BA-114)
- **employee_profile_inventory** — Bỏ chức danh, Tier IV, nhãn Legendary/Epic/Rare, "Best Streak", banner mở khóa theo chuỗi, pulse. Hiện khung + hình nền đang trang bị, huy hiệu; chuỗi "Ẩn" (bật ở Huy hiệu). Nút "Đang dùng · Gỡ" và hàm Gỡ. (T-BA-120)
- **user_profile** — Bỏ "LVL 24", "Productivity Ninja", dấu "Verified Streak Master", "Focus Sensor/Strict mode", Passkey/Linked IDs, glow pulse. Hiện khung + hình nền đang dùng, thẻ huy hiệu; chuỗi chỉ cho chính mình với "Hiện cho nhóm: Tắt (mặc định)". Thêm lối vào "Dữ liệu của tôi"; Đăng xuất ghi "Không đăng xuất được khi đang trong phiên" (Q-66). "Team" → "Nhóm". (T-BA-120)
- **write_journal** — Bỏ "Only you can see…", "E2E Encrypted", công tắc riêng tư, chia sẻ Team Feed, tâm trạng, gắn phiên/flow score/chuỗi, ảnh, ghi âm, nhãn, gợi ý ngẫu nhiên, "Phone didn't flip". Dùng đúng câu "Chủ nhóm và quản trị không xem được trong app." (AC-07.10.7); 1 mục/ngày; `maxlength=5000`, bộ đếm và lỗi khi chạm 5.000 ký tự; ca lỗi mất mạng/ô trống. (T-BA-115)

## Cần lưu ý

- Shop có 3 loại (Khung/Hình nền/**Danh hiệu**) theo chỉ dẫn đợt này; T-BA-111 và `a_03` (đợt 2) ghi chỉ 2 loại Khung/Hình nền. Cần chốt (đề xuất mở Q-, trạng thái `Chờ`).
- Ảnh vật phẩm vẫn là URL ảnh mẫu cũ (nội dung `data-alt` tiếng Anh); chỉ đổi tên/loại hiển thị.
- Màn bên ngoài phạm vi đợt này còn có thể dùng `#FF5722`/`#8E8E93`: rà ở đợt sau.
