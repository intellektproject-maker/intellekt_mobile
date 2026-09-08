-- Faculty mobile authentication support
-- Safe to run against the existing PostgreSQL database.

ALTER TABLE faculty
  ADD COLUMN IF NOT EXISTS must_reset_password BOOLEAN NOT NULL DEFAULT TRUE;

CREATE INDEX IF NOT EXISTS idx_faculty_faculty_id_upper
  ON faculty (UPPER(TRIM(faculty_id)));

-- Verification query:
-- SELECT faculty_id, name, email, phone, must_reset_password
-- FROM faculty
-- WHERE UPPER(TRIM(faculty_id)) = 'IG003';
