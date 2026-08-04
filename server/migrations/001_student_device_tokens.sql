CREATE TABLE IF NOT EXISTS student_device_tokens (
    id BIGSERIAL PRIMARY KEY,
    roll_no VARCHAR(100) NOT NULL,
    token TEXT NOT NULL UNIQUE,
    platform VARCHAR(20) NOT NULL DEFAULT 'android',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_student_device_tokens_roll_no
    ON student_device_tokens (UPPER(TRIM(roll_no)));
