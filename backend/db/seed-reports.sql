-- Local report preview: historical sessions only; no wallet/streak changes.
BEGIN;
DO $$
DECLARE
  gid uuid := '00000000-0000-4000-9000-000000000001';
  owner_id uuid := '00000000-0000-4000-8000-000000000001';
  uid uuid; sid uuid; st timestamptz; d date; i int; n int; exited boolean;
  first_day date := (date_trunc('month', now() AT TIME ZONE 'Asia/Ho_Chi_Minh') - interval '2 months')::date;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM groups WHERE id=gid) THEN
    RAISE EXCEPTION 'Run the base demo seed first';
  END IF;
  FOR i IN 1..6 LOOP
    d := first_day + i * 3;
    st := (d + time '19:30') AT TIME ZONE 'Asia/Ho_Chi_Minh';
    sid := md5('dropit-report-preview:' || d)::uuid;
    INSERT INTO sessions(id,group_id,duration_min,started_at,ends_at,session_day,status,
      forfeited,forfeited_at,forfeit_trigger_user_id,completed_at,created_by,created_at)
    VALUES(sid,gid,25,st,st+interval '25 minutes',d,'COMPLETED',i IN (2,5),
      CASE WHEN i IN (2,5) THEN st+interval '9 minutes' END,
      CASE WHEN i IN (2,5) THEN '00000000-0000-4000-8000-000000000014'::uuid END,
      st+interval '25 minutes',owner_id,st-interval '1 day')
    ON CONFLICT(id) DO NOTHING;
    FOR n IN 11..15 LOOP
      uid := ('00000000-0000-4000-8000-' || lpad(n::text,12,'0'))::uuid;
      exited := n=14 AND i IN (2,5);
      INSERT INTO session_members(session_id,user_id,state,end_reason,joined_at,exited_at,
        ended_at,focus_seconds,coins_awarded,late_join,pause_count)
      VALUES(sid,uid,
        (CASE WHEN exited THEN 'EXITED' WHEN n=15 AND i IN (1,3,5) THEN 'ABSENT' ELSE 'COMPLETED' END)::member_state,
        (CASE WHEN exited THEN 'GRACE_EXPIRED' WHEN n=15 AND i IN (1,3,5) THEN 'NO_SHOW' ELSE 'TIME_UP' END)::member_end_reason,
        CASE WHEN NOT(n=15 AND i IN (1,3,5)) THEN st-interval '1 minute' END,
        CASE WHEN exited THEN st+interval '9 minutes' END,
        CASE WHEN exited THEN st+interval '9 minutes' ELSE st+interval '25 minutes' END,
        CASE WHEN exited THEN 540 WHEN n=15 AND i IN (1,3,5) THEN 0 ELSE 1500 END,
        0,n=12 AND i=4,CASE WHEN n=13 AND i=3 THEN 1 ELSE 0 END)
      ON CONFLICT(session_id,user_id) DO NOTHING;
      IF exited THEN
        INSERT INTO explanations(session_id,user_id,body,created_at)
        VALUES(sid,uid,'Dữ liệu mẫu: kết nối mạng gián đoạn khi đang tập trung.',st+interval '30 minutes')
        ON CONFLICT(session_id,user_id) DO NOTHING;
      END IF;
    END LOOP;
  END LOOP;
END $$;
COMMIT;
