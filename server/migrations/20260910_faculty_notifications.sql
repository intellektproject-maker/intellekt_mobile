-- Faculty notification infrastructure.
-- This migration is additive and does not modify any student notification tables.

CREATE TABLE IF NOT EXISTS faculty_device_tokens (
    id SERIAL PRIMARY KEY,
    faculty_id VARCHAR NOT NULL,
    token TEXT NOT NULL UNIQUE,
    platform VARCHAR(32) NOT NULL DEFAULT 'android',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_faculty_device_tokens_faculty_id
    ON faculty_device_tokens (faculty_id);

CREATE TABLE IF NOT EXISTS faculty_task_notification_events (
    id BIGSERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL,
    faculty_id VARCHAR NOT NULL,
    event_type VARCHAR(32) NOT NULL,
    event_date DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (task_id, faculty_id, event_type, event_date)
);

CREATE INDEX IF NOT EXISTS idx_faculty_task_notification_events_task
    ON faculty_task_notification_events (task_id);
