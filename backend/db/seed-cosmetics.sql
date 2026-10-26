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
