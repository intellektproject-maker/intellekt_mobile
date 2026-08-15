'use strict';

const DEFAULT_INTERVAL_MS = 10000;
const DEFAULT_BATCH_SIZE = 10;

function createNotificationWorker({
    pool,
    sendPushToStudent,
    intervalMs = Number(process.env.NOTIFICATION_WORKER_INTERVAL_MS) || DEFAULT_INTERVAL_MS,
    batchSize = Number(process.env.NOTIFICATION_WORKER_BATCH_SIZE) || DEFAULT_BATCH_SIZE
}) {
    if (!pool || typeof pool.connect !== 'function') {
        throw new Error('Notification worker requires a PostgreSQL pool');
    }
    if (typeof sendPushToStudent !== 'function') {
        throw new Error('Notification worker requires sendPushToStudent');
    }

    let timer = null;
    let running = false;
    let stopped = true;

    async function claimEvents() {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const result = await client.query(
                `
                SELECT id, event_key, module_name, class_name, board,
                       subject_id, title, message
                FROM notification_events
                WHERE status = 'pending'
                  AND COALESCE(available_at, NOW()) <= NOW()
                ORDER BY created_at ASC
                FOR UPDATE SKIP LOCKED
                LIMIT $1
                `,
                [batchSize]
            );

            if (result.rows.length > 0) {
                await client.query(
                    `
                    UPDATE notification_events
                    SET status = 'processing',
                        attempts = COALESCE(attempts, 0) + 1,
                        updated_at = NOW()
                    WHERE id = ANY($1::bigint[])
                    `,
                    [result.rows.map((row) => row.id)]
                );
            }

            await client.query('COMMIT');
            return result.rows;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    async function findStudents(event) {
        const values = [event.class_name, event.board];
        let subjectFilter = '';

        if (event.subject_id !== null && event.subject_id !== undefined) {
            values.push(Number(event.subject_id));
            subjectFilter = `
                AND EXISTS (
                    SELECT 1
                    FROM student_subjects ss
                    WHERE UPPER(TRIM(ss.roll_no)) = UPPER(TRIM(s.roll_no))
                      AND ss.subject_id = $3
                )
            `;
        }

        const result = await pool.query(
            `
            SELECT DISTINCT s.roll_no
            FROM students s
            WHERE TRIM(s.class) = TRIM($1)
              AND UPPER(TRIM(s.board)) = UPPER(TRIM($2))
              ${subjectFilter}
            `,
            values
        );
        return result.rows;
    }

    async function markSent(eventId) {
        await pool.query(
            `
            UPDATE notification_events
            SET status = 'sent', last_error = NULL, updated_at = NOW()
            WHERE id = $1
            `,
            [eventId]
        );
    }

    async function markFailed(eventId, error) {
        const message = String(error && error.message ? error.message : error).slice(0, 2000);
        await pool.query(
            `
            UPDATE notification_events
            SET status = CASE WHEN COALESCE(attempts, 0) >= 5 THEN 'failed' ELSE 'pending' END,
                last_error = $2,
                available_at = NOW() + INTERVAL '1 minute',
                updated_at = NOW()
            WHERE id = $1
            `,
            [eventId, message]
        );
    }

    async function processEvent(event) {
        try {
            const students = await findStudents(event);
            let successCount = 0;
            let failureCount = 0;

            for (const student of students) {
                const result = await sendPushToStudent(
                    student.roll_no,
                    event.title,
                    event.message,
                    {
                        module_name: event.module_name,
                        event_key: event.event_key,
                        roll_no: student.roll_no
                    }
                );
                successCount += result.successCount || 0;
                failureCount += result.failureCount || 0;
            }

            await markSent(event.id);
            console.log(
                `Notification event ${event.event_key} processed: ` +
                `${students.length} students, ${successCount} delivered, ${failureCount} failed`
            );
        } catch (error) {
            console.error(`Notification event ${event.event_key} failed:`, error);
            await markFailed(event.id, error);
        }
    }

    async function tick() {
        if (running || stopped) return;
        running = true;
        try {
            const events = await claimEvents();
            for (const event of events) await processEvent(event);
        } catch (error) {
            console.error('Notification worker cycle failed:', error);
        } finally {
            running = false;
        }
    }

    function start() {
        if (timer) return;
        stopped = false;
        console.log(`Notification worker started (every ${intervalMs} ms)`);
        void tick();
        timer = setInterval(() => void tick(), intervalMs);
        timer.unref();
    }

    function stop() {
        stopped = true;
        if (timer) clearInterval(timer);
        timer = null;
    }

    return { start, stop, tick };
}

module.exports = { createNotificationWorker };
