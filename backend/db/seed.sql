-- Seed dev cho backend DropIt! (chạy sau design/schema.sql khi khởi tạo container).
-- cognito_sub dạng 'dev:<email>' để POST /dev/token ánh xạ được.
BEGIN;
INSERT INTO users (id, cognito_sub, email, display_name) VALUES
 ('00000000-0000-4000-8000-000000000001','dev:lan@dropit.dev','lan@dropit.dev','Lan (chủ nhóm)'),
 ('00000000-0000-4000-8000-000000000011','dev:an@dropit.dev','an@dropit.dev','An'),
 ('00000000-0000-4000-8000-000000000012','dev:binh@dropit.dev','binh@dropit.dev','Bình'),
 ('00000000-0000-4000-8000-000000000013','dev:chi@dropit.dev','chi@dropit.dev','Chi'),
 ('00000000-0000-4000-8000-000000000014','dev:dung@dropit.dev','dung@dropit.dev','Dũng'),
 ('00000000-0000-4000-8000-000000000015','dev:em@dropit.dev','em@dropit.dev','Em'),
 ('00000000-0000-4000-8000-000000000021','dev:giang@dropit.dev','giang@dropit.dev','Giang'),
 ('00000000-0000-4000-8000-000000000022','dev:hoa@dropit.dev','hoa@dropit.dev','Hoa');

INSERT INTO groups (id, owner_id, name, report_purpose, invite_code) VALUES
 ('00000000-0000-4000-9000-000000000001','00000000-0000-4000-8000-000000000001','Nhóm Học Toán',
  'Theo dõi mức độ tập trung chung của nhóm để điều chỉnh lịch học.','TAPTRUN7'),
 ('00000000-0000-4000-9000-000000000002','00000000-0000-4000-8000-000000000001','Nhóm Đọc Sách',
  'Tổng kết số buổi đọc mỗi tháng.','GHEPNHA5');

INSERT INTO group_members (group_id, user_id, consent_version, consented_at)
SELECT '00000000-0000-4000-9000-000000000001', u, 1, now()
FROM unnest(ARRAY[
 '00000000-0000-4000-8000-000000000011','00000000-0000-4000-8000-000000000012',
 '00000000-0000-4000-8000-000000000013','00000000-0000-4000-8000-000000000014',
 '00000000-0000-4000-8000-000000000015']::uuid[]) AS u;

INSERT INTO consents (user_id, group_id, consent_version, action, purpose_snapshot, retention_months, terms_hash, client_info)
SELECT gm.user_id, gm.group_id, 1, 'GRANT', g.report_purpose, g.retention_months, 'seed', 'seed'
FROM group_members gm JOIN groups g ON g.id = gm.group_id;
COMMIT;
