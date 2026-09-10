const express = require('express');
const pool = require('./db');
const { createFacultyNotificationWorker } = require('./faculty-notification-worker');

if (!express.application.__facultyDeviceTokenRoutesInstalled) {
  const originalListen = express.application.listen;

  express.application.listen = function facultyAwareListen(...args) {
    const app = this;

    if (!app.__facultyDeviceTokenRoutesRegistered) {
      app.__facultyDeviceTokenRoutesRegistered = true;

      app.post('/faculty/device-token', async (req, res) => {
        const { faculty_id, token, platform = 'android' } = req.body || {};
        const facultyId = String(faculty_id || '').toUpperCase().trim();
        const deviceToken = String(token || '').trim();
        const devicePlatform = String(platform || 'android').trim();
        if (!facultyId || !deviceToken) return res.status(400).json({ error: 'faculty_id and token are required' });
        try {
          const faculty = await pool.query(`SELECT faculty_id FROM faculty WHERE UPPER(TRIM(faculty_id)) = $1 LIMIT 1`, [facultyId]);
          if (faculty.rows.length === 0) return res.status(404).json({ error: 'Faculty not found' });
          await pool.query(`INSERT INTO faculty_device_tokens (faculty_id, token, platform, updated_at) VALUES ($1,$2,$3,CURRENT_TIMESTAMP) ON CONFLICT (token) DO UPDATE SET faculty_id=EXCLUDED.faculty_id, platform=EXCLUDED.platform, updated_at=CURRENT_TIMESTAMP`, [facultyId, deviceToken, devicePlatform]);
          return res.json({ success: true });
        } catch (error) {
          console.error('POST /faculty/device-token error:', error);
          return res.status(500).json({ error: 'Failed to register faculty notification device' });
        }
      });

      app.delete('/faculty/device-token', async (req, res) => {
        const { faculty_id, token } = req.body || {};
        const facultyId = String(faculty_id || '').toUpperCase().trim();
        const deviceToken = String(token || '').trim();
        if (!facultyId || !deviceToken) return res.status(400).json({ error: 'faculty_id and token are required' });
        try {
          await pool.query(`DELETE FROM faculty_device_tokens WHERE UPPER(TRIM(faculty_id)) = $1 AND token = $2`, [facultyId, deviceToken]);
          return res.json({ success: true });
        } catch (error) {
          console.error('DELETE /faculty/device-token error:', error);
          return res.status(500).json({ error: 'Failed to unregister faculty notification device' });
        }
      });

      app.put('/faculty-notifications/read/:facultyId/:notificationId', async (req, res) => {
        const facultyId = String(req.params.facultyId || '').toUpperCase().trim();
        const notificationId = Number(req.params.notificationId);
        if (!facultyId || !Number.isInteger(notificationId) || notificationId <= 0) {
          return res.status(400).json({ error: 'Valid facultyId and notificationId are required' });
        }
        try {
          const result = await pool.query(
            `UPDATE faculty_notifications
             SET is_read = TRUE
             WHERE id = $1 AND UPPER(TRIM(faculty_id)) = $2
             RETURNING id`,
            [notificationId, facultyId]
          );
          if (result.rowCount === 0) return res.status(404).json({ error: 'Notification not found' });
          return res.json({ success: true });
        } catch (error) {
          console.error('PUT /faculty-notifications/read error:', error);
          return res.status(500).json({ error: 'Failed to mark notification as read' });
        }
      });

      if (!app.__facultyNotificationWorkerStarted) {
        app.__facultyNotificationWorkerStarted = true;
        try {
          app.__facultyNotificationWorker = createFacultyNotificationWorker({ pool });
          app.__facultyNotificationWorker.start();
        } catch (error) {
          console.error('Faculty notification worker failed to start:', error);
        }
      }
    }

    return originalListen.apply(app, args);
  };

  express.application.__facultyDeviceTokenRoutesInstalled = true;
}
