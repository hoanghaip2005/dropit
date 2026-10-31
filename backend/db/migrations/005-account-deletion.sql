-- Account erasure may remove explanation revision content; normal edits remain append-only.
CREATE OR REPLACE FUNCTION trg_explanation_revisions_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' AND current_setting('dropit.purge', true) = 'on' THEN RETURN OLD; END IF;
  RAISE EXCEPTION 'Lịch sử giải trình chỉ thêm (BR-85)' USING ERRCODE = 'check_violation';
END $$;
