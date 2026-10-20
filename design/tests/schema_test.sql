-- =====================================================================
-- DropIt! — Kiểm thử ràng buộc lược đồ (design/schema.sql)
-- Chạy: psql -v ON_ERROR_STOP=1 -f design/tests/schema_test.sql
-- Mỗi ca in "PASS: ..." hoặc "FAIL: ..." (NOTICE). Toàn bộ chạy trong một
-- transaction rồi ROLLBACK — không để lại dữ liệu.
-- CI coi bất kỳ dòng "FAIL:" nào là thất bại.
-- =====================================================================
\set QUIET on
\pset pager off
BEGIN;

CREATE TEMP TABLE t_result (name text, ok boolean);

-- Ca mong đợi BỊ CHẶN. Nếu câu lệnh chạy được: FAIL và hoàn tác tác dụng của nó.
CREATE FUNCTION pg_temp.expect_fail(name text, q text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE q;
    RAISE EXCEPTION '__unexpected_ok__';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM = '__unexpected_ok__' THEN
      RAISE NOTICE 'FAIL: % (không bị chặn)', name;
      INSERT INTO t_result VALUES (name, false);
    ELSE
      RAISE NOTICE 'PASS: % [%]', name, SQLERRM;
      INSERT INTO t_result VALUES (name, true);
    END IF;
  END;
END $$;

-- Ca mong đợi CHẠY ĐƯỢC (giữ tác dụng).
CREATE FUNCTION pg_temp.expect_ok(name text, q text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE q;
    RAISE NOTICE 'PASS: %', name;
    INSERT INTO t_result VALUES (name, true);
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'FAIL: % [%]', name, SQLERRM;
    INSERT INTO t_result VALUES (name, false);
  END;
END $$;

CREATE FUNCTION pg_temp.expect_true(name text, cond boolean) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF cond THEN RAISE NOTICE 'PASS: %', name; ELSE RAISE NOTICE 'FAIL: %', name; END IF;
  INSERT INTO t_result VALUES (name, COALESCE(cond, false));
END $$;

-- ---------------------------------------------------------------------
-- Dữ liệu nền
-- ---------------------------------------------------------------------
INSERT INTO users(id, display_name) VALUES
 ('00000000-0000-0000-0000-0000000000a1','Chu nhom 1'),
 ('00000000-0000-0000-0000-0000000000a2','Chu nhom 2');
INSERT INTO users(id, display_name)
  SELECT ('00000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid, 'Thanh vien ' || i
  FROM generate_series(1, 12) i;

INSERT INTO groups(id, owner_id, name, report_purpose, invite_code) VALUES
 ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000a1','Nhom 1','Theo doi tap trung','ABCDEFGH'),
 ('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000a2','Nhom 2','Theo doi tap trung','ABCDEFGJ');

-- Thành viên 01..09 vào nhóm 1 (9 người)
INSERT INTO group_members(group_id, user_id, consent_version, consented_at)
  SELECT '10000000-0000-0000-0000-000000000001',
         ('00000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid, 1, now()
  FROM generate_series(1, 9) i;

DO $$
DECLARE
  g1 text := '10000000-0000-0000-0000-000000000001';
  g2 text := '10000000-0000-0000-0000-000000000002';
  o1 text := '00000000-0000-0000-0000-0000000000a1';
  m01 text := '00000000-0000-0000-0000-000000000001';
  m10 text := '00000000-0000-0000-0000-000000000010';
  m11 text := '00000000-0000-0000-0000-000000000011';
  m12 text := '00000000-0000-0000-0000-000000000012';
  ins text := 'INSERT INTO sessions(id, group_id, duration_min, started_at, ends_at, session_day, created_by, status, cancel_reason) VALUES ';
BEGIN
  -- ===== Phiên: thời lượng chỉ 25/50 (BR-02) =====
  PERFORM pg_temp.expect_ok('phien 25 phut hop le',
    ins || format('(%L,%L,25,%L,%L,%L,%L,''SCHEDULED'',NULL)',
      '20000000-0000-0000-0000-000000000001', g1, '2026-11-02 01:00+00', '2026-11-02 01:25+00', '2026-11-02', o1));
  PERFORM pg_temp.expect_ok('phien 50 phut hop le',
    ins || format('(%L,%L,50,%L,%L,%L,%L,''SCHEDULED'',NULL)',
      '20000000-0000-0000-0000-000000000002', g1, '2026-11-02 02:00+00', '2026-11-02 02:50+00', '2026-11-02', o1));
  PERFORM pg_temp.expect_fail('phien 30 phut bi chan (BR-02)',
    ins || format('(gen_random_uuid(),%L,30,%L,%L,%L,%L,''SCHEDULED'',NULL)',
      g1, '2026-11-03 01:00+00', '2026-11-03 01:30+00', '2026-11-03', o1));

  -- ===== ends_at = started_at + duration =====
  PERFORM pg_temp.expect_fail('ends_at lech duration bi chan',
    ins || format('(gen_random_uuid(),%L,25,%L,%L,%L,%L,''SCHEDULED'',NULL)',
      g1, '2026-11-03 01:00+00', '2026-11-03 01:30+00', '2026-11-03', o1));
  PERFORM pg_temp.expect_fail('sua duration ma khong sua ends_at bi chan',
    'UPDATE sessions SET duration_min = 50 WHERE id = ''20000000-0000-0000-0000-000000000001''');

  -- ===== Không chồng phiên trong nhóm (BR-78) =====
  PERFORM pg_temp.expect_fail('chong phien cung nhom bi chan (BR-78)',
    ins || format('(gen_random_uuid(),%L,25,%L,%L,%L,%L,''SCHEDULED'',NULL)',
      g1, '2026-11-02 01:10+00', '2026-11-02 01:35+00', '2026-11-02', o1));
  PERFORM pg_temp.expect_ok('phien sat nhau [) khong tinh chong',
    ins || format('(gen_random_uuid(),%L,25,%L,%L,%L,%L,''SCHEDULED'',NULL)',
      g1, '2026-11-02 01:25+00', '2026-11-02 01:50+00', '2026-11-02', o1));
  PERFORM pg_temp.expect_ok('trung gio o nhom khac duoc phep',
    ins || format('(gen_random_uuid(),%L,25,%L,%L,%L,%L,''SCHEDULED'',NULL)',
      g2, '2026-11-02 01:10+00', '2026-11-02 01:35+00', '2026-11-02', '00000000-0000-0000-0000-0000000000a2'));
  PERFORM pg_temp.expect_ok('chong voi phien da huy duoc phep',
    ins || format('(gen_random_uuid(),%L,25,%L,%L,%L,%L,''CANCELLED'',''OWNER_CANCEL'')',
      g1, '2026-11-02 02:10+00', '2026-11-02 02:35+00', '2026-11-02', o1));

  -- ===== D-21: một người chỉ thuộc 1 nhóm đang hoạt động =====
  PERFORM pg_temp.expect_fail('thanh vien nhom 1 vao them nhom 2 bi chan (D-21)',
    format('INSERT INTO group_members(group_id,user_id,consent_version,consented_at) VALUES (%L,%L,1,now())', g2, m01));

  -- ===== D-25: chủ nhóm không là thành viên / không vào phiên =====
  PERFORM pg_temp.expect_fail('chu nhom lam thanh vien nhom minh bi chan (D-25)',
    format('INSERT INTO group_members(group_id,user_id,consent_version,consented_at) VALUES (%L,%L,1,now())', g1, o1));
  PERFORM pg_temp.expect_fail('chu nhom vao phien nhom minh bi chan (D-25)',
    format('INSERT INTO session_members(session_id,user_id) VALUES (%L,%L)', '20000000-0000-0000-0000-000000000001', o1));
  PERFORM pg_temp.expect_fail('doi chu nhom thanh thanh vien dang hoat dong bi chan (D-25)',
    format('UPDATE groups SET owner_id = %L WHERE id = %L', m01, g1));

  -- ===== BR-74: trần 10 thành viên =====
  PERFORM pg_temp.expect_ok('thanh vien thu 10 duoc vao',
    format('INSERT INTO group_members(group_id,user_id,consent_version,consented_at) VALUES (%L,%L,1,now())', g1, m10));
  PERFORM pg_temp.expect_fail('thanh vien thu 11 bi chan (BR-74)',
    format('INSERT INTO group_members(group_id,user_id,consent_version,consented_at) VALUES (%L,%L,1,now())', g1, m11));

  -- D-21 (tiếp): rời nhóm xong thì vào nhóm khác được
  PERFORM pg_temp.expect_ok('roi nhom 1 roi vao nhom 2 duoc phep (D-21)',
    format('UPDATE group_members SET left_at = now(), leave_reason = ''LEFT'' WHERE group_id = %L AND user_id = %L; '
        || 'INSERT INTO group_members(group_id,user_id,consent_version,consented_at) VALUES (%L,%L,1,now())', g1, m10, g2, m10));
  PERFORM pg_temp.expect_ok('thanh vien moi vao nhom 2 (khong thuoc nhom nao)',
    format('INSERT INTO group_members(group_id,user_id,consent_version,consented_at) VALUES (%L,%L,1,now())', g2, m12));
END $$;

-- ---------------------------------------------------------------------
-- Coins (BR-43, BR-45)
-- ---------------------------------------------------------------------
DO $$
DECLARE
  u text := '00000000-0000-0000-0000-000000000001';
  ins text := 'INSERT INTO coin_ledger(user_id, amount, type, ref_id, reward_date, reason, idempotency_key, balance_after) VALUES ';
BEGIN
  PERFORM pg_temp.expect_ok('thuong phien 10 coins',
    ins || format('(%L,10,''SESSION_REWARD'',%L,''2026-11-02'',''SESSION_COMPLETE'',''k1'',0)', u, '20000000-0000-0000-0000-000000000001'));
  PERFORM pg_temp.expect_true('balance_after do trigger tinh = 10',
    (SELECT balance_after FROM coin_ledger WHERE idempotency_key = 'k1') = 10);
  PERFORM pg_temp.expect_fail('ghi trung SESSION_REWARD cung phien bi chan (BR-45)',
    ins || format('(%L,10,''SESSION_REWARD'',%L,''2026-11-02'',''SESSION_COMPLETE'',''k1-retry'',0)', u, '20000000-0000-0000-0000-000000000001'));
  PERFORM pg_temp.expect_fail('trung idempotency_key bi chan',
    ins || format('(%L,25,''SESSION_REWARD'',gen_random_uuid(),''2026-11-02'',''SESSION_COMPLETE'',''k1'',0)', u));
  PERFORM pg_temp.expect_fail('UPDATE coin_ledger bi chan',
    'UPDATE coin_ledger SET amount = 999 WHERE idempotency_key = ''k1''');
  PERFORM pg_temp.expect_fail('DELETE coin_ledger bi chan',
    'DELETE FROM coin_ledger WHERE idempotency_key = ''k1''');
  PERFORM pg_temp.expect_fail('mua vuot so du (am) bi chan (BR-45)',
    ins || format('(%L,-11,''SHOP_PURCHASE'',gen_random_uuid(),NULL,''SHOP'',''k-buy'',0)', u));
  PERFORM pg_temp.expect_ok('mua dung bang so du duoc phep',
    ins || format('(%L,-10,''SHOP_PURCHASE'',gen_random_uuid(),NULL,''SHOP'',''k-buy2'',0)', u));
  -- Trần ngày: 3 x 25 = 75 trong ngày 2026-11-03
  PERFORM pg_temp.expect_ok('thuong 75 coins trong ngay',
    ins || format('(%L,25,''SESSION_REWARD'',gen_random_uuid(),''2026-11-03'',''S'',''c1'',0),'
               || '(%L,25,''SESSION_REWARD'',gen_random_uuid(),''2026-11-03'',''S'',''c2'',0),'
               || '(%L,25,''SESSION_REWARD'',gen_random_uuid(),''2026-11-03'',''S'',''c3'',0)', u, u, u));
  PERFORM pg_temp.expect_fail('vuot tran 100/ngay bi chan (BR-43)',
    ins || format('(%L,50,''SESSION_REWARD'',gen_random_uuid(),''2026-11-03'',''S'',''c4'',0)', u));
  PERFORM pg_temp.expect_ok('cham dung tran 100/ngay duoc phep',
    ins || format('(%L,25,''SESSION_REWARD'',gen_random_uuid(),''2026-11-03'',''S'',''c5'',0)', u));
  PERFORM pg_temp.expect_fail('them 1 coin sau khi cham tran bi chan',
    ins || format('(%L,1,''SESSION_REWARD'',gen_random_uuid(),''2026-11-03'',''S'',''c6'',0)', u));
  PERFORM pg_temp.expect_ok('ngay moi duoc thuong lai',
    ins || format('(%L,25,''SESSION_REWARD'',gen_random_uuid(),''2026-11-04'',''S'',''c7'',0)', u));
END $$;

-- ---------------------------------------------------------------------
-- session_members: trạng thái cuối bất biến (BR-32)
-- ---------------------------------------------------------------------
DO $$
DECLARE
  s text := '20000000-0000-0000-0000-000000000002';
  u text := '00000000-0000-0000-0000-000000000002';
BEGIN
  INSERT INTO session_members(session_id, user_id, state) VALUES (s::uuid, u::uuid, 'INVITED');
  PERFORM pg_temp.expect_ok('chuyen sang COMPLETED (trang thai cuoi)',
    format('UPDATE session_members SET state = ''COMPLETED'', end_reason = ''TIME_UP'', ended_at = now(), focus_seconds = 3000 WHERE session_id = %L AND user_id = %L', s, u));
  PERFORM pg_temp.expect_fail('sua state sau trang thai cuoi bi chan (BR-32)',
    format('UPDATE session_members SET state = ''EXITED'', exited_at = now() WHERE session_id = %L AND user_id = %L', s, u));
  PERFORM pg_temp.expect_fail('sua focus_seconds sau trang thai cuoi bi chan',
    format('UPDATE session_members SET focus_seconds = 10 WHERE session_id = %L AND user_id = %L', s, u));
  PERFORM pg_temp.expect_fail('sua ended_at sau trang thai cuoi bi chan',
    format('UPDATE session_members SET ended_at = now() + interval ''1 hour'' WHERE session_id = %L AND user_id = %L', s, u));
  PERFORM pg_temp.expect_ok('ghi coins_awarded sau trang thai cuoi duoc phep',
    format('UPDATE session_members SET coins_awarded = 25 WHERE session_id = %L AND user_id = %L', s, u));
END $$;

-- ---------------------------------------------------------------------
-- monthly_reports: bản chụp bất biến, không chứa Coins/chuỗi (BR-53, BR-56)
-- ---------------------------------------------------------------------
DO $$
DECLARE
  g1 text := '10000000-0000-0000-0000-000000000001';
  r  text := '30000000-0000-0000-0000-000000000001';
BEGIN
  INSERT INTO monthly_reports(id, group_id, period, period_end, status, owner_id_snapshot, member_count,
                              group_visible, group_summary, generated_at, expires_at)
  VALUES (r::uuid, g1::uuid, '2026-10-01', '2026-10-31', 'PENDING', '00000000-0000-0000-0000-0000000000a1',
          9, true, NULL, NULL, now() + interval '13 months');
  -- Job ghi dòng khi PENDING, rồi chốt GENERATED
  INSERT INTO monthly_report_rows(report_id, user_id, display_name_snapshot, metrics)
  VALUES (r::uuid, '00000000-0000-0000-0000-000000000001', 'Thanh vien 1', '{"sessions_completed":5}');
  PERFORM pg_temp.expect_fail('metrics chua khoa coins bi chan (BR-53)',
    format('INSERT INTO monthly_report_rows(report_id, user_id, metrics) VALUES (%L, NULL, ''{"coins":10}'')', r));
  PERFORM pg_temp.expect_fail('metrics chua khoa current_streak bi chan (BR-53)',
    format('INSERT INTO monthly_report_rows(report_id, user_id, metrics) VALUES (%L, NULL, ''{"current_streak":3}'')', r));
  UPDATE monthly_reports SET status = 'GENERATED', generated_at = now(),
         group_summary = '{"sessions":12,"completion_rate":0.8}' WHERE id = r::uuid;

  PERFORM pg_temp.expect_fail('sua group_summary bao cao da tao bi chan (BR-56)',
    format('UPDATE monthly_reports SET group_summary = ''{"sessions":99}'' WHERE id = %L', r));
  PERFORM pg_temp.expect_fail('sua member_count bao cao da tao bi chan',
    format('UPDATE monthly_reports SET member_count = 3 WHERE id = %L', r));
  PERFORM pg_temp.expect_fail('sua group_visible bao cao da tao bi chan',
    format('UPDATE monthly_reports SET group_visible = false WHERE id = %L', r));
  PERFORM pg_temp.expect_fail('sua owner_id_snapshot/period bao cao da tao bi chan',
    format('UPDATE monthly_reports SET owner_id_snapshot = %L, period = ''2026-09-01'' WHERE id = %L',
           '00000000-0000-0000-0000-0000000000a2', r));
  PERFORM pg_temp.expect_fail('dua bao cao da tao ve FAILED bi chan',
    format('UPDATE monthly_reports SET status = ''FAILED'', generated_at = NULL WHERE id = %L', r));
  PERFORM pg_temp.expect_fail('xoa bao cao da tao khi khong co co purge bi chan',
    format('DELETE FROM monthly_reports WHERE id = %L', r));
  PERFORM pg_temp.expect_fail('sua metrics dong bao cao da tao bi chan',
    format('UPDATE monthly_report_rows SET metrics = ''{"sessions_completed":50}'' WHERE report_id = %L', r));
  PERFORM pg_temp.expect_fail('them dong vao bao cao da tao bi chan',
    format('INSERT INTO monthly_report_rows(report_id, user_id, display_name_snapshot, metrics) VALUES (%L, %L, ''X'', ''{}'')',
           r, '00000000-0000-0000-0000-000000000003'));
  PERFORM pg_temp.expect_fail('xoa dong bao cao khi khong co co purge bi chan',
    format('DELETE FROM monthly_report_rows WHERE report_id = %L', r));
  PERFORM pg_temp.expect_ok('ghi emailed_at/pdf_key sau khi tao duoc phep',
    format('UPDATE monthly_reports SET emailed_at = now(), pdf_key = ''reports/x.pdf'' WHERE id = %L', r));
  PERFORM pg_temp.expect_ok('an danh hoa dong khi xoa tai khoan duoc phep',
    format('UPDATE monthly_report_rows SET user_id = NULL, display_name_snapshot = NULL WHERE report_id = %L', r));
  PERFORM pg_temp.expect_fail('group_summary chua khoa coins bi chan (BR-53)',
    format('INSERT INTO monthly_reports(group_id, period, period_end, status, owner_id_snapshot, member_count, group_visible, group_summary, generated_at, expires_at) '
        || 'VALUES (%L, ''2026-09-01'', ''2026-09-30'', ''GENERATED'', %L, 9, true, ''{"coins":120}'', now(), now())',
           g1, '00000000-0000-0000-0000-0000000000a1'));
  PERFORM pg_temp.expect_fail('group_summary chua khoa streak bi chan (BR-53)',
    format('INSERT INTO monthly_reports(group_id, period, period_end, status, owner_id_snapshot, member_count, group_visible, group_summary, generated_at, expires_at) '
        || 'VALUES (%L, ''2026-08-01'', ''2026-08-31'', ''GENERATED'', %L, 9, true, ''{"longest_streak":7}'', now(), now())',
           g1, '00000000-0000-0000-0000-0000000000a1'));
  PERFORM pg_temp.expect_ok('job xoa theo han luu (dropit.purge) duoc phep',
    format('SET LOCAL dropit.purge = ''on''; DELETE FROM monthly_reports WHERE id = %L; SET LOCAL dropit.purge = ''off''', r));
END $$;

-- ---------------------------------------------------------------------
-- View chủ nhóm không có cột Coins/chuỗi (BR-53, D-12)
-- ---------------------------------------------------------------------
DO $$
BEGIN
  PERFORM pg_temp.expect_true('owner_session_member_view ton tai',
    EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'owner_session_member_view'));
  PERFORM pg_temp.expect_true('owner_session_member_view khong co cot coins/streak/balance',
    NOT EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_name = 'owner_session_member_view'
                  AND column_name ~* '(coin|streak|balance|ledger)'));
END $$;

-- ---------------------------------------------------------------------
-- Tổng kết
-- ---------------------------------------------------------------------
DO $$
DECLARE p int; f int;
BEGIN
  SELECT count(*) FILTER (WHERE ok), count(*) FILTER (WHERE NOT ok) INTO p, f FROM t_result;
  RAISE NOTICE 'TONG KET: % PASS, % FAIL', p, f;
END $$;

ROLLBACK;
