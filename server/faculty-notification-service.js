'use strict';

const admin = require('firebase-admin');

const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token'
]);

function getMessaging() {
  if (!admin.apps || admin.apps.length === 0) {
    return null;
  }
  return admin.messaging();
}

async function sendToFaculty(pool, facultyIds, { title, body, data = {} }) {
  const ids = [...new Set((facultyIds || []).map((id) => String(id || '').trim().toUpperCase()).filter(Boolean))];
  if (!ids.length) return { sent: 0, removed: 0 };

  const messaging = getMessaging();
  if (!messaging) {
    console.warn('Faculty push skipped: Firebase Cloud Messaging is not initialized');
    return { sent: 0, removed: 0 };
  }

  const result = await pool.query(
    `SELECT token
     FROM faculty_device_tokens
     WHERE UPPER(TRIM(faculty_id)) = ANY($1::text[])`,
    [ids]
  );

  const tokens = [...new Set(result.rows.map((row) => row.token).filter(Boolean))];
  if (!tokens.length) return { sent: 0, removed: 0 };

  let sent = 0;
  let removed = 0;

  // Firebase multicast accepts at most 500 registration tokens per request.
  for (let i = 0; i < tokens.length; i += 500) {
    const batch = tokens.slice(i, i + 500);
    const response = await messaging.sendEachForMulticast({
      tokens: batch,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([key, value]) => [key, String(value)])
      ),
      android: {
        priority: 'high',
        notification: { channelId: 'default' }
      }
    });

    sent += response.successCount;

    const invalidTokens = [];
    response.responses.forEach((item, index) => {
      if (!item.success && item.error && INVALID_TOKEN_CODES.has(item.error.code)) {
        invalidTokens.push(batch[index]);
      }
    });

    if (invalidTokens.length) {
      const deleted = await pool.query(
        `DELETE FROM faculty_device_tokens
         WHERE token = ANY($1::text[])`,
        [invalidTokens]
      );
      removed += deleted.rowCount || 0;
    }
  }

  return { sent, removed };
}

async function createFacultyNotification(pool, {
  facultyId,
  moduleName,
  message,
  title = 'INTELLEKT',
  data = {}
}) {
  const id = String(facultyId || '').trim().toUpperCase();
  if (!id) return { inserted: false, sent: 0, removed: 0 };

  const result = await pool.query(
    `INSERT INTO faculty_notifications
       (faculty_id, module_name, message, is_read)
     VALUES ($1, $2, $3, FALSE)
     RETURNING id`,
    [id, moduleName, message]
  );

  const push = await sendToFaculty(pool, [id], { title, body: message, data });
  return { inserted: result.rowCount > 0, ...push };
}

module.exports = {
  sendToFaculty,
  createFacultyNotification
};
