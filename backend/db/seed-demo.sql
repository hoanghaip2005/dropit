-- Seed bổ sung (idempotent — chạy lại không nhân đôi): danh mục Shop + lịch sử phiên/Coins/chuỗi/huy hiệu cho An.
-- Áp tự động khi tạo container mới (03-seed-demo.sql); với DB đang chạy: npm run db:seed
BEGIN;

-- ---------- Shop (EP-06): khung avatar, hình nền, danh hiệu; giá cố định (BR-93, BR-121) ----------
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

-- Thành viên vào nhóm từ 2 tháng trước (báo cáo chỉ tính phiên từ ngày vào — BR-59)
UPDATE group_members SET joined_at = LEAST(joined_at, date_trunc('month', now()) - interval '2 months')
WHERE group_id = '00000000-0000-4000-9000-000000000001';
UPDATE groups SET created_at = LEAST(created_at, date_trunc('month', now()) - interval '2 months')
WHERE id IN ('00000000-0000-4000-9000-000000000001','00000000-0000-4000-9000-000000000002');

-- ---------- Lịch sử phiên nhóm "Nhóm Học Toán" ----------
DO $$
DECLARE
  g    uuid := '00000000-0000-4000-9000-000000000001';
  lan  uuid := '00000000-0000-4000-8000-000000000001';
  an   uuid := '00000000-0000-4000-8000-000000000011';
  binh uuid := '00000000-0000-4000-8000-000000000012';
  chi  uuid := '00000000-0000-4000-8000-000000000013';
  dung uuid := '00000000-0000-4000-8000-000000000014';
  em   uuid := '00000000-0000-4000-8000-000000000015';
  today date := (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
  -- (ngày, giờ, người EXITED hoặc NULL)
  plan_days date[];
  plan_exit uuid[];
  i int; sid uuid; st timestamptz; d date; ex uuid; forf boolean; u uuid; ui uuid;
BEGIN
  IF EXISTS (SELECT 1 FROM sessions WHERE id = md5('dropit-seed-demo-1')::uuid) THEN
    RAISE NOTICE 'seed-demo đã có, bỏ qua phần phiên';
    RETURN;
  END IF;
  -- tháng trước: 3 phiên (một phiên Dũng rời → mất thưởng tập thể); 6 ngày gần nhất: hoàn thành có thưởng
  plan_days := ARRAY[
    (date_trunc('month', today) - interval '1 month' + interval '9 days')::date,
    (date_trunc('month', today) - interval '1 month' + interval '14 days')::date,
    (date_trunc('month', today) - interval '1 month' + interval '19 days')::date,
    today - 6, today - 5, today - 4, today - 3, today - 2, today - 1];
  plan_exit := ARRAY[NULL, dung, NULL, NULL, NULL, NULL, NULL, NULL, NULL]::uuid[];

  FOR i IN 1..array_length(plan_days, 1) LOOP
    d := plan_days[i]; ex := plan_exit[i]; forf := ex IS NOT NULL;
    sid := md5('dropit-seed-demo-' || i)::uuid;
    st := (d + time '20:00') AT TIME ZONE 'Asia/Ho_Chi_Minh';
    INSERT INTO sessions (id, group_id, duration_min, started_at, ends_at, session_day, status, forfeited, forfeited_at, forfeit_trigger_user_id, completed_at, created_by, created_at)
    VALUES (sid, g, 25, st, st + interval '25 minutes', d, 'COMPLETED', forf,
            CASE WHEN forf THEN st + interval '12 minutes' END, ex, st + interval '25 minutes', lan, st - interval '1 day');
    FOREACH u IN ARRAY ARRAY[an, binh, chi, dung] LOOP
      IF u = ex THEN
        INSERT INTO session_members (session_id, user_id, state, end_reason, joined_at, exited_at, ended_at, focus_seconds, grace_used)
        VALUES (sid, u, 'EXITED', 'GRACE_EXPIRED', st - interval '2 minutes', st + interval '12 minutes', st + interval '12 minutes', 700, 1);
        INSERT INTO achievement_log (user_id, kind, value_before, value_after, day, ref_session_id, reason, created_at)
        SELECT u, 'STREAK_BREAK', 0, 0, d, sid, 'EXITED', st + interval '12 minutes';
        INSERT INTO notifications (user_id, type, title, body, data, dedupe_key, created_at, read_at)
        SELECT rr.rid, 'MEMBER_EXITED', 'Nhóm Học Toán', 'Dũng đã rời phiên lúc 20:12. Phiên đã mất thưởng tập thể — vẫn tiếp tục đến hết giờ.',
               jsonb_build_object('session_id', sid, 'group_id', g, 'exited_display_name', 'Dũng', 'exited_user_id', u, 'forfeited', true),
               'seed-exit-' || sid, st + interval '12 minutes', st + interval '1 day'
        FROM unnest(ARRAY[lan, an, binh, chi, em]) AS rr(rid);
      ELSE
        INSERT INTO session_members (session_id, user_id, state, end_reason, joined_at, ended_at, focus_seconds, coins_awarded)
        VALUES (sid, u, 'COMPLETED', 'TIME_UP', st - interval '2 minutes', st + interval '25 minutes', 1500, CASE WHEN forf THEN 0 ELSE 10 END);
        INSERT INTO daily_attendance (user_id, day, group_id, first_session_id, focus_minutes) VALUES (u, d, g, sid, 25)
        ON CONFLICT (user_id, day) DO NOTHING;
        IF forf THEN
          INSERT INTO achievement_log (user_id, kind, value_before, value_after, day, ref_session_id, reason, created_at)
          VALUES (u, 'STREAK_BREAK', NULL, 0, d, sid, 'SESSION_FORFEITED', st + interval '25 minutes');
        ELSE
          INSERT INTO coin_ledger (user_id, amount, type, ref_id, reward_date, reason, idempotency_key, balance_after, created_at)
          VALUES (u, 10, 'SESSION_REWARD', sid, d, 'SESSION_COMPLETE', 'SESSION_REWARD:' || sid || ':' || u, 0, st + interval '25 minutes');
          INSERT INTO achievement_log (user_id, kind, value_before, value_after, day, ref_session_id, reason, created_at)
          VALUES (u, 'STREAK_INC', NULL, NULL, d, sid, 'SESSION_REWARDED', st + interval '25 minutes')
          ON CONFLICT DO NOTHING;
        END IF;
        INSERT INTO notifications (user_id, type, title, body, data, dedupe_key, created_at, read_at)
        VALUES (u, 'SESSION_RESULT', 'Nhóm Học Toán',
                CASE WHEN forf THEN 'Bạn đã hoàn thành phiên. Phiên mất thưởng tập thể: 0 Coins.' ELSE 'Bạn đã hoàn thành phiên: +10 Coins.' END,
                jsonb_build_object('session_id', sid, 'group_id', g), 'seed-result-' || sid || '-' || u, st + interval '25 minutes',
                CASE WHEN d < today - 1 THEN st + interval '1 hour' END);
      END IF;
    END LOOP;
    INSERT INTO session_members (session_id, user_id, state, end_reason, ended_at) VALUES (sid, em, 'ABSENT', 'NO_SHOW', st);
  END LOOP;

  -- chuỗi đã phát lại từ nhật ký trên: INC, BREAK(forfeit), rồi 7 lần INC (ngày không có lịch giữ nguyên chuỗi, BR-49)
  UPDATE users SET current_streak = 7, longest_streak = 7, streak_last_inc_day = today - 1 WHERE id IN (an, binh, chi);
  UPDATE users SET current_streak = 7, longest_streak = 7, streak_last_inc_day = today - 1 WHERE id = dung;
  -- huy hiệu theo mốc (BR-52)
  INSERT INTO user_badges (user_id, badge_id, awarded_at, showcase_slot)
  SELECT p.uid, b.bid, (today - 1 + time '20:25') AT TIME ZONE 'Asia/Ho_Chi_Minh', CASE WHEN p.uid = an AND b.bid = 'STREAK_7' THEN 1 END
  FROM unnest(ARRAY[an, binh, chi, dung]) AS p(uid) CROSS JOIN unnest(ARRAY['STREAK_3','STREAK_7']) AS b(bid)
  ON CONFLICT DO NOTHING;
  INSERT INTO achievement_log (user_id, kind, value_before, value_after, day, ref_session_id, ref_badge_id, reason, created_at)
  SELECT p.uid, 'BADGE_AWARD', NULL, x.t, today - 1, md5('dropit-seed-demo-9')::uuid, x.b, 'STREAK_DAYS', (today - 1 + time '20:25') AT TIME ZONE 'Asia/Ho_Chi_Minh'
  FROM unnest(ARRAY[an, binh, chi, dung]) AS p(uid) CROSS JOIN (VALUES ('STREAK_3', 3), ('STREAK_7', 7)) AS x(b, t);
  INSERT INTO notifications (user_id, type, title, body, data, dedupe_key, created_at)
  VALUES (an, 'BADGE_EARNED', 'Huy hiệu mới', 'Bạn vừa đạt huy hiệu “Chuỗi 7 ngày”.', jsonb_build_object('badge_code', 'STREAK_7'),
          'BADGE_EARNED:' || an || ':STREAK_7', (today - 1 + time '20:25') AT TIME ZONE 'Asia/Ho_Chi_Minh');

  -- An mua và trang bị "Khung Lá Xanh" (30 Coins)
  ui := md5('dropit-seed-demo-item-an')::uuid;
  INSERT INTO coin_ledger (entry_id, user_id, amount, type, ref_id, reason, idempotency_key, balance_after, created_at)
  VALUES (md5('dropit-seed-demo-ledger-an')::uuid, an, -30, 'SHOP_PURCHASE', ui, 'SHOP_PURCHASE:00000000-0000-4000-a000-000000000011',
          'SHOP_PURCHASE:' || an || ':00000000-0000-4000-a000-000000000011', 0, now() - interval '20 hours');
  INSERT INTO user_items (id, user_id, item_id, price_paid, ledger_entry_id, acquired_at)
  VALUES (ui, an, '00000000-0000-4000-a000-000000000011', 30, md5('dropit-seed-demo-ledger-an')::uuid, now() - interval '20 hours');
  INSERT INTO user_equipped (user_id, kind, item_id) VALUES (an, 'AVATAR_FRAME', '00000000-0000-4000-a000-000000000011');

  -- Hôm nay, 3 giờ trước: Dũng rời phiên (còn hạn giải trình/khiếu nại để demo US-04.05/04.07); An vắng
  sid := md5('dropit-seed-demo-today')::uuid;
  st := date_trunc('minute', now()) - interval '3 hours';
  d := (st AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
  INSERT INTO sessions (id, group_id, duration_min, started_at, ends_at, session_day, status, forfeited, forfeited_at, forfeit_trigger_user_id, completed_at, created_by, created_at)
  VALUES (sid, g, 25, st, st + interval '25 minutes', d, 'COMPLETED', true, st + interval '8 minutes', dung, st + interval '25 minutes', lan, st - interval '1 day');
  INSERT INTO session_members (session_id, user_id, state, end_reason, joined_at, exited_at, ended_at, focus_seconds, grace_used)
  VALUES (sid, dung, 'EXITED', 'GRACE_EXPIRED', st - interval '1 minute', st + interval '8 minutes', st + interval '8 minutes', 480, 1);
  INSERT INTO session_members (session_id, user_id, state, end_reason, joined_at, ended_at, focus_seconds)
  VALUES (sid, binh, 'COMPLETED', 'TIME_UP', st - interval '1 minute', st + interval '25 minutes', 1500),
         (sid, chi,  'COMPLETED', 'TIME_UP', st - interval '1 minute', st + interval '25 minutes', 1500);
  INSERT INTO session_members (session_id, user_id, state, end_reason, ended_at) VALUES (sid, an, 'ABSENT', 'NO_SHOW', st), (sid, em, 'ABSENT', 'NO_SHOW', st);
  INSERT INTO daily_attendance (user_id, day, group_id, first_session_id, focus_minutes)
  VALUES (binh, d, g, sid, 25), (chi, d, g, sid, 25) ON CONFLICT DO NOTHING;
  INSERT INTO achievement_log (user_id, kind, value_before, value_after, day, ref_session_id, reason, created_at)
  VALUES (dung, 'STREAK_BREAK', 7, 0, d, sid, 'EXITED', st + interval '8 minutes'),
         (binh, 'STREAK_BREAK', 7, 0, d, sid, 'SESSION_FORFEITED', st + interval '25 minutes'),
         (chi,  'STREAK_BREAK', 7, 0, d, sid, 'SESSION_FORFEITED', st + interval '25 minutes');
  UPDATE users SET current_streak = 0 WHERE id IN (dung, binh, chi);
  INSERT INTO notifications (user_id, type, title, body, data, dedupe_key, created_at)
  SELECT rr.rid, 'MEMBER_EXITED', 'Nhóm Học Toán', 'Dũng đã rời phiên. Phiên đã mất thưởng tập thể — vẫn tiếp tục đến hết giờ.',
         jsonb_build_object('session_id', sid, 'group_id', g, 'exited_display_name', 'Dũng', 'exited_user_id', dung, 'forfeited', true),
         'seed-exit-' || sid, st + interval '8 minutes'
  FROM unnest(ARRAY[lan, an, binh, chi, em]) AS rr(rid);
END $$;
COMMIT;
