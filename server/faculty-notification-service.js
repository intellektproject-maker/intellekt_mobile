'use strict';

const admin = require('firebase-admin');

/**
 * FCM error codes that indicate the device token is no longer valid.
 */
const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token'
]);

/**
 * This channel ID must match the channel ID created in Flutter.
 */
const ANDROID_NOTIFICATION_CHANNEL_ID = 'intellekt_high_importance';

/**
 * Get Firebase Messaging only when Firebase is initialized.
 */
function getMessaging() {
  if (!admin.apps || admin.apps.length === 0) {
    return null;
  }

  return admin.messaging();
}

/**
 * Normalize data values because FCM data values must be strings.
 */
function normalizeData(data = {}) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [
      String(key),
      String(value ?? '')
    ])
  );
}

/**
 * Send push notifications to all registered devices belonging
 * to the specified faculty IDs.
 *
 * Supports:
 * - Multiple devices per faculty
 * - Multiple faculty recipients
 * - Automatic invalid-token cleanup
 * - Firebase response logging
 */
async function sendToFaculty(
  pool,
  facultyIds,
  {
    title,
    body,
    data = {}
  }
) {
  const ids = [
    ...new Set(
      (facultyIds || [])
        .map((id) => String(id || '').trim().toUpperCase())
        .filter(Boolean)
    )
  ];

  if (!ids.length) {
    console.warn('Faculty push skipped: no faculty IDs supplied');

    return {
      sent: 0,
      failed: 0,
      removed: 0
    };
  }

  const messaging = getMessaging();

  if (!messaging) {
    console.warn(
      'Faculty push skipped: Firebase Cloud Messaging is not initialized'
    );

    return {
      sent: 0,
      failed: 0,
      removed: 0
    };
  }

  let tokenResult;

  try {
    tokenResult = await pool.query(
      `
      SELECT token, faculty_id
      FROM faculty_device_tokens
      WHERE UPPER(TRIM(faculty_id)) = ANY($1::text[])
      `,
      [ids]
    );
  } catch (error) {
    console.error(
      'Faculty push failed while reading device tokens:',
      error
    );

    return {
      sent: 0,
      failed: 0,
      removed: 0
    };
  }

  const tokens = [
    ...new Set(
      tokenResult.rows
        .map((row) => row.token)
        .filter((token) => typeof token === 'string' && token.trim())
    )
  ];

  if (!tokens.length) {
    console.log(
      `Faculty push skipped: no registered device tokens for ${ids.join(', ')}`
    );

    return {
      sent: 0,
      failed: 0,
      removed: 0
    };
  }

  const normalizedData = normalizeData(data);

  let sent = 0;
  let failed = 0;
  let removed = 0;

  /**
   * Firebase allows a maximum of 500 tokens per multicast request.
   */
  for (let i = 0; i < tokens.length; i += 500) {
    const batch = tokens.slice(i, i + 500);

    try {
      const response = await messaging.sendEachForMulticast({
        tokens: batch,

        notification: {
          title: String(title || 'INTELLEKT'),
          body: String(body || 'You have a new notification.')
        },

        data: normalizedData,

        android: {
          priority: 'high',

          notification: {
            channelId: ANDROID_NOTIFICATION_CHANNEL_ID,

            title: String(title || 'INTELLEKT'),
            body: String(body || 'You have a new notification.'),

            sound: 'default',

            defaultSound: true,
            defaultVibrateTimings: true,

            visibility: 'public',

            notificationCount: 1
          }
        },

        apns: {
          payload: {
            aps: {
              alert: {
                title: String(title || 'INTELLEKT'),
                body: String(body || 'You have a new notification.')
              },
              sound: 'default',
              badge: 1
            }
          }
        }
      });

      sent += response.successCount;
      failed += response.failureCount;

      const invalidTokens = [];

      response.responses.forEach((item, index) => {
        if (item.success) {
          console.log(
            `Faculty push delivered successfully to token ${index + 1}/${batch.length}`
          );
          return;
        }

        const errorCode = item.error?.code || 'unknown-error';
        const errorMessage = item.error?.message || 'Unknown Firebase error';
        const failedToken = batch[index];

        console.error(
          `Faculty push failed for token ${index + 1}/${batch.length}`,
          {
            code: errorCode,
            message: errorMessage
          }
        );

        if (INVALID_TOKEN_CODES.has(errorCode)) {
          invalidTokens.push(failedToken);
        }
      });

      /**
       * Remove invalid or expired FCM tokens.
       */
      if (invalidTokens.length > 0) {
        try {
          const deleted = await pool.query(
            `
            DELETE FROM faculty_device_tokens
            WHERE token = ANY($1::text[])
            `,
            [invalidTokens]
          );

          removed += deleted.rowCount || 0;

          console.log(
            `Removed ${deleted.rowCount || 0} invalid faculty FCM token(s)`
          );
        } catch (error) {
          console.error(
            'Failed to remove invalid faculty FCM tokens:',
            error
          );
        }
      }
    } catch (error) {
      failed += batch.length;

      console.error(
        'Faculty multicast push request failed:',
        error
      );
    }
  }

  console.log(
    `Faculty push result | Recipients: ${ids.join(', ')} | ` +
    `Tokens: ${tokens.length} | Sent: ${sent} | ` +
    `Failed: ${failed} | Removed: ${removed}`
  );

  return {
    sent,
    failed,
    removed
  };
}

/**
 * Create an in-app faculty notification and send its push notification.
 */
async function createFacultyNotification(
  pool,
  {
    facultyId,
    moduleName,
    message,
    title = 'INTELLEKT',
    data = {}
  }
) {
  const id = String(facultyId || '').trim().toUpperCase();

  if (!id) {
    console.warn(
      'Faculty notification skipped: faculty ID is missing'
    );

    return {
      inserted: false,
      sent: 0,
      failed: 0,
      removed: 0
    };
  }

  const notificationMessage = String(
    message || 'You have a new notification.'
  );

  let insertResult;

  try {
    insertResult = await pool.query(
      `
      INSERT INTO faculty_notifications
        (
          faculty_id,
          module_name,
          message,
          is_read
        )
      VALUES
        ($1, $2, $3, FALSE)
      RETURNING id
      `,
      [
        id,
        moduleName || 'general',
        notificationMessage
      ]
    );
  } catch (error) {
    console.error(
      `Failed to insert faculty notification for ${id}:`,
      error
    );

    return {
      inserted: false,
      sent: 0,
      failed: 0,
      removed: 0
    };
  }

  const pushResult = await sendToFaculty(
    pool,
    [id],
    {
      title,
      body: notificationMessage,
      data: {
        ...data,
        faculty_id: id,
        module_name: moduleName || 'general',
        notification_id: insertResult.rows[0]?.id || ''
      }
    }
  );

  return {
    inserted: insertResult.rowCount > 0,
    notificationId: insertResult.rows[0]?.id || null,
    ...pushResult
  };
}

module.exports = {
  sendToFaculty,
  createFacultyNotification
};