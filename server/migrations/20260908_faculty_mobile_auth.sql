-- Faculty mobile authentication + task-management database support.
-- Safe for an existing database: all structural changes are idempotent.

ALTER TABLE faculty
  ADD COLUMN IF NOT EXISTS must_reset_password BOOLEAN NOT NULL DEFAULT TRUE;

CREATE INDEX IF NOT EXISTS idx_faculty_faculty_id_upper
  ON faculty (UPPER(TRIM(faculty_id)));

CREATE TABLE IF NOT EXISTS faculty_tasks (
  id SERIAL PRIMARY KEY,
  faculty_id VARCHAR(100) NOT NULL,
  faculty_name VARCHAR(255) NOT NULL,
  class_name VARCHAR(100) NOT NULL,
  subject_name VARCHAR(255) DEFAULT '',
  total_test_note TEXT DEFAULT '',
  other_tasks TEXT DEFAULT '',
  due_date DATE,
  priority VARCHAR(20) DEFAULT 'Medium',
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMP NULL,
  assigned_by VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  task_type VARCHAR(20) DEFAULT 'Weekly',
  parent_daily_task_id INTEGER NULL,
  task_date DATE NULL
);

ALTER TABLE faculty_tasks
  ADD COLUMN IF NOT EXISTS faculty_id VARCHAR(100),
  ADD COLUMN IF NOT EXISTS faculty_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS class_name VARCHAR(100),
  ADD COLUMN IF NOT EXISTS subject_name VARCHAR(255) DEFAULT '',
  ADD COLUMN IF NOT EXISTS total_test_note TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS other_tasks TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS due_date DATE,
  ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'Medium',
  ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP NULL,
  ADD COLUMN IF NOT EXISTS assigned_by VARCHAR(100),
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS task_type VARCHAR(20) DEFAULT 'Weekly',
  ADD COLUMN IF NOT EXISTS parent_daily_task_id INTEGER NULL,
  ADD COLUMN IF NOT EXISTS task_date DATE NULL;

CREATE INDEX IF NOT EXISTS idx_faculty_tasks_faculty_id
  ON faculty_tasks (faculty_id);

CREATE INDEX IF NOT EXISTS idx_faculty_tasks_task_type_date
  ON faculty_tasks (task_type, task_date);

CREATE TABLE IF NOT EXISTS faculty_notifications (
  id SERIAL PRIMARY KEY,
  faculty_id VARCHAR(100) NOT NULL,
  module_name VARCHAR(100) NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE faculty_notifications
  ADD COLUMN IF NOT EXISTS faculty_id VARCHAR(100),
  ADD COLUMN IF NOT EXISTS module_name VARCHAR(100),
  ADD COLUMN IF NOT EXISTS message TEXT,
  ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_faculty_notifications_faculty
  ON faculty_notifications (faculty_id, module_name, is_read);

-- Verification examples:
-- SELECT faculty_id, name, email, phone, must_reset_password
-- FROM faculty WHERE UPPER(TRIM(faculty_id)) = 'IG003';
-- SELECT * FROM faculty_tasks WHERE faculty_id = 'IG003' ORDER BY created_at DESC;
-- SELECT * FROM faculty_notifications WHERE faculty_id = 'IG003' ORDER BY created_at DESC;
