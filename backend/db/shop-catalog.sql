-- Production catalog only: no demo users, groups, history or Coins. Idempotent.
BEGIN;
INSERT INTO shop_items (id, kind, name, preview_key, price, status, is_default) VALUES
 ('00000000-0000-4000-a000-000000000001','AVATAR_FRAME','Khung mặc định','frame_default',NULL,'HIDDEN',true),
 ('00000000-0000-4000-a000-000000000002','BACKGROUND','Nền mặc định','bg_default',NULL,'HIDDEN',true),
 ('00000000-0000-4000-a000-000000000011','AVATAR_FRAME','Khung Lá Xanh','frame_leaf',30,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000012','AVATAR_FRAME','Khung Hoàng Hôn','frame_sunset',60,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000013','AVATAR_FRAME','Khung Ngân Hà','frame_galaxy',150,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000021','BACKGROUND','Nền Thư Viện','bg_library',40,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000022','BACKGROUND','Nền Biển Đêm','bg_night_sea',80,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000023','BACKGROUND','Nền Rừng Sương','bg_misty_forest',200,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000031','TITLE','Người Gác Đêm','title_night_owl',50,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000032','TITLE','Kẻ Săn Bình Minh','title_early_bird',50,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000039','BACKGROUND','Nền Mùa Hè (ngừng bán)','bg_summer',70,'HIDDEN',false)
ON CONFLICT (id) DO NOTHING;
-- Additional original cosmetics. Safe to run repeatedly; never changes ownership or Coins.
INSERT INTO shop_items (id, kind, name, preview_key, price, status, is_default) VALUES
 ('00000000-0000-4000-a000-000000000041','AVATAR_FRAME','Khung Băng Tinh','frame_frost',120,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000042','AVATAR_FRAME','Khung Hỏa Phượng','frame_phoenix',180,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000043','AVATAR_FRAME','Khung Hải Triều','frame_tidal',100,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000044','AVATAR_FRAME','Khung Cơ Giới','frame_cyber',160,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000045','AVATAR_FRAME','Khung Anh Đào','frame_sakura',90,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000046','AVATAR_FRAME','Khung Vương Miện','frame_royal',250,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000051','TITLE','Vệ Binh Băng Giá','title_ice_guardian',70,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000052','TITLE','Người Giữ Lửa','title_flame_keeper',80,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000053','TITLE','Linh Hồn Đại Dương','title_ocean_soul',70,'ON_SALE',false),
 ('00000000-0000-4000-a000-000000000054','TITLE','Bậc Thầy Tập Trung','title_crowned',120,'ON_SALE',false)
ON CONFLICT (id) DO NOTHING;

COMMIT;
