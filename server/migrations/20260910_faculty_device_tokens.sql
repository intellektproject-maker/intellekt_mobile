-- Faculty FCM device-token storage.
-- Adds multi-device support for Faculty push notifications without changing
-- the existing Student notification/token tables or behavior.

CREATE TABLE IF NOT EXISTS faculty_device_tokens (
  id SERIAL PRIMARY KEY,
  faculty_id VARCHAR(100) NOT NULL,
  token TEXT NOT NULL,
  platform VARCHAR(50) NOT NULL DEFAULT 'android',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT faculty_device_tokens_token_unique UNIQUE (token)
);

CREATE INDEX IF NOT EXISTS idx_faculty_device_tokens_faculty_id
  ON faculty_device_tokens (faculty_id);

-- Keep the latest registration time available when an existing token is
-- registered again after an FCM token refresh or app reinstall.
CREATE INDEX IF NOT EXISTS idx_faculty_device_tokens_updated_at
  ON faculty_device_tokens (updated_at);

-- Verification examples:
-- SELECT * FROM faculty_device_tokens
-- WHERE faculty_id = 'IG003'
-- ORDER BY updated_at DESC;
--
-- DELETE FROM faculty_device_tokens
-- WHERE faculty_id = 'IG003' AND token = '<current-device-token>';
