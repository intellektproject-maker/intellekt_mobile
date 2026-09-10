const express = require('express');
const pool = require('./db');

// This module is loaded with Node's --require hook so the existing server.js
// does not need to be modified. It registers only Faculty device-token routes
// when the Express application starts listening.
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

        if (!facultyId || !deviceToken) {
          return res.status(400).json({
            error: 'faculty_id and token are required'
          });
        }

        try {
          const faculty = await pool.query(
            `SELECT faculty_id
             FROM faculty
             WHERE UPPER(TRIM(faculty_id)) = $1
             LIMIT 1`,
            [facultyId]
          );

          if (faculty.rows.length === 0) {
            return res.status(404).json({ error: 'Faculty not found' });
          }

          await pool.query(
            `INSERT INTO faculty_device_tokens (
              faculty_id,
              token,
              platform,
              updated_at
            )
            VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
            ON CONFLICT (token) DO UPDATE SET
              faculty_id = EXCLUDED.faculty_id,
              platform = EXCLUDED.platform,
              updated_at = CURRENT_TIMESTAMP`,
            [facultyId, deviceToken, devicePlatform]
          );

          return res.json({ success: true });
        } catch (error) {
          console.error('POST /faculty/device-token error:', error);
          return res.status(500).json({
            error: 'Failed to register faculty notification device'
          });
        }
      });

      app.delete('/faculty/device-token', async (req, res) => {
        const { faculty_id, token } = req.body || {};
        const facultyId = String(faculty_id || '').toUpperCase().trim();
        const deviceToken = String(token || '').trim();

        if (!facultyId || !deviceToken) {
          return res.status(400).json({
            error: 'faculty_id and token are required'
          });
        }

        try {
          await pool.query(
            `DELETE FROM faculty_device_tokens
             WHERE UPPER(TRIM(faculty_id)) = $1
               AND token = $2`,
            [facultyId, deviceToken]
          );

          return res.json({ success: true });
        } catch (error) {
          console.error('DELETE /faculty/device-token error:', error);
          return res.status(500).json({
            error: 'Failed to unregister faculty notification device'
          });
        }
      });
    }

    return originalListen.apply(app, args);
  };

  express.application.__facultyDeviceTokenRoutesInstalled = true;
}
