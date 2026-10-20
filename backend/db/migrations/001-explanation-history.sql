-- Migration 001 (backend local, ngoài design/schema.sql gốc — xem README "Lệch so với schema.sql").
-- Idempotent: áp mỗi lần khởi động (src/shared/migrate.ts) và chạy tay bằng `npm run db:migrate`.

-- BR-85 / AC-04.05.5: lưu lịch sử bản cũ khi sửa giải trình; AC-04.06.6: nhãn "đã sửa lúc …".
ALTER TABLE explanations ADD COLUMN IF NOT EXISTS edited_at timestamptz;

CREATE TABLE IF NOT EXISTS explanation_revisions (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  explanation_id uuid NOT NULL REFERENCES explanations(id),
  body           text NOT NULL,
  written_at     timestamptz NOT NULL,              -- lúc bản này được gửi/sửa
  replaced_at    timestamptz NOT NULL DEFAULT now() -- lúc bị bản mới thay
);
CREATE INDEX IF NOT EXISTS explanation_revisions_expl_idx ON explanation_revisions(explanation_id, replaced_at);

-- Chỉ thêm, không sửa/xóa bản cũ (NFR-P13).
CREATE OR REPLACE FUNCTION trg_explanation_revisions_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Lịch sử giải trình chỉ thêm (BR-85)' USING ERRCODE = 'check_violation';
END $$;
DROP TRIGGER IF EXISTS explanation_revisions_append_only ON explanation_revisions;
CREATE TRIGGER explanation_revisions_append_only BEFORE UPDATE OR DELETE ON explanation_revisions
  FOR EACH ROW EXECUTE FUNCTION trg_explanation_revisions_append_only();
