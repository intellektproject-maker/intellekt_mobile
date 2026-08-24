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

    const attendanceTimeZone =
        process.env.ATTENDANCE_NOTIFICATION_TIMEZONE || 'Asia/Kolkata';
    const feeReminderTimeZone =
        process.env.FEE_REMINDER_NOTIFICATION_TIMEZONE || 'Asia/Kolkata';

    function getZonedDateParts(date = new Date(), timeZone = attendanceTimeZone) {
        const parts = new Intl.DateTimeFormat('en-CA', {
            timeZone,
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            weekday: 'short',
            hour: '2-digit',
            minute: '2-digit',
            hourCycle: 'h23'
        }).formatToParts(date);

        return Object.fromEntries(
            parts
                .filter((part) => part.type !== 'literal')
                .map((part) => [part.type, part.value])
        );
    }

    function getMondayDate(sundayDate) {
        const date = new Date(`${sundayDate}T00:00:00Z`);
        date.setUTCDate(date.getUTCDate() - 6);
        return date.toISOString().slice(0, 10);
    }

    async function ensureWeeklyAttendanceRunsTable() {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS weekly_attendance_notification_runs (
                run_date DATE PRIMARY KEY,
                status VARCHAR(20) NOT NULL DEFAULT 'pending',
                attempts INTEGER NOT NULL DEFAULT 0,
                last_error TEXT,
                started_at TIMESTAMPTZ,
                completed_at TIMESTAMPTZ,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
        `);
    }

    async function claimWeeklyAttendanceRun(runDate) {
        await ensureWeeklyAttendanceRunsTable();

        await pool.query(
            `
            INSERT INTO weekly_attendance_notification_runs (run_date)
            VALUES ($1)
            ON CONFLICT (run_date) DO NOTHING
            `,
            [runDate]
        );

        const result = await pool.query(
            `
            UPDATE weekly_attendance_notification_runs
            SET status = 'processing',
                attempts = attempts + 1,
                last_error = NULL,
                started_at = NOW(),
                updated_at = NOW()
            WHERE run_date = $1
              AND (
                  status = 'pending'
                  OR (
                      status = 'failed'
                      AND attempts < 5
                      AND updated_at <= NOW() - INTERVAL '1 minute'
                  )
              )
            RETURNING run_date
            `,
            [runDate]
        );

        return result.rowCount > 0;
    }

    async function sendWeeklyAttendanceReminder() {
        const now = getZonedDateParts();
        const hour = Number(now.hour);
        if (now.weekday !== 'Sun' || hour < 17) return;

        const runDate = `${now.year}-${now.month}-${now.day}`;
        if (!(await claimWeeklyAttendanceRun(runDate))) return;

        const mondayDate = getMondayDate(runDate);
        const title = 'Weekly attendance reminder';
        const message = 'Attendance have been updated click to view';

        try {
            await pool.query(
                `
                INSERT INTO student_notifications
                    (roll_no, module_name, message, is_read)
                SELECT s.roll_no, 'attendance', $1, FALSE
                FROM students s
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM student_notifications sn
                    WHERE UPPER(TRIM(sn.roll_no)) = UPPER(TRIM(s.roll_no))
                      AND sn.module_name = 'attendance'
                      AND sn.message = $1
                )
                `,
                [`${message} Week: ${mondayDate} to ${runDate}`]
            );

            const students = await pool.query(
                `SELECT DISTINCT roll_no FROM students ORDER BY roll_no`
            );

            let successCount = 0;
            let failureCount = 0;
            for (const student of students.rows) {
                const result = await sendPushToStudent(
                    student.roll_no,
                    title,
                    message,
                    {
                        module_name: 'attendance',
                        notification_type: 'weekly_attendance',
                        week_start: mondayDate,
                        week_end: runDate,
                        roll_no: student.roll_no
                    }
                );
                successCount += result.successCount || 0;
                failureCount += result.failureCount || 0;
            }

            await pool.query(
                `
                UPDATE weekly_attendance_notification_runs
                SET status = 'sent', completed_at = NOW(), updated_at = NOW()
                WHERE run_date = $1
                `,
                [runDate]
            );

            console.log(
                `Weekly attendance reminder processed: ${students.rows.length} students, ` +
                `${successCount} delivered, ${failureCount} failed`
            );
        } catch (error) {
            await pool.query(
                `
                UPDATE weekly_attendance_notification_runs
                SET status = 'failed', last_error = $2, updated_at = NOW()
                WHERE run_date = $1
                `,
                [runDate, String(error && error.message ? error.message : error).slice(0, 2000)]
            );
            throw error;
        }
    }

    async function sendFeePaymentReminders() {
        const candidates = await pool.query(
            `
            SELECT id, roll_no, total_fee, fee_paid, next_due
            FROM fees
            WHERE reminder_enabled = TRUE
              AND COALESCE(total_fee, 0) > COALESCE(fee_paid, 0)
              AND (
                  last_reminder_sent_at IS NULL
                  OR last_reminder_sent_at <= NOW() - INTERVAL '24 hours'
              )
            ORDER BY id ASC
            LIMIT $1
            `,
            [batchSize]
        );

        for (const fee of candidates.rows) {
            const claim = await pool.query(
                `
                UPDATE fees
                SET last_reminder_sent_at = NOW()
                WHERE id = $1
                  AND reminder_enabled = TRUE
                  AND COALESCE(total_fee, 0) > COALESCE(fee_paid, 0)
                  AND (
                      last_reminder_sent_at IS NULL
                      OR last_reminder_sent_at <= NOW() - INTERVAL '24 hours'
                  )
                RETURNING roll_no, next_due
                `,
                [fee.id]
            );

            if (claim.rowCount === 0) continue;

            const studentRollNo = claim.rows[0].roll_no;
            const dueDate = claim.rows[0].next_due;
            const title = 'Fees Payment Reminder';
            const message = dueDate
                ? `Kindly remember to pay your pending fees. Your next due date is ${dueDate}.`
                : 'Kindly remember to pay your pending fees. Please check your Fee Details for the due date.';

            try {
                await pool.query(
                    `
                    INSERT INTO student_notifications
                        (roll_no, module_name, message, is_read)
                    VALUES ($1, 'fees', $2, FALSE)
                    `,
                    [studentRollNo, message]
                );

                const result = await sendPushToStudent(
                    studentRollNo,
                    title,
                    message,
                    {
                        module_name: 'fees',
                        notification_type: 'fee_payment_reminder',
                        roll_no: studentRollNo
                    }
                );

                console.log(
                    `Fee payment reminder processed for ${studentRollNo}: ` +
                    `${result.successCount || 0} delivered, ${result.failureCount || 0} failed`
                );
            } catch (error) {
                await pool.query(
                    `
                    UPDATE fees
                    SET last_reminder_sent_at = NULL
                    WHERE id = $1
                      AND reminder_enabled = TRUE
                    `,
                    [fee.id]
                );
                console.error(`Fee payment reminder failed for ${studentRollNo}:`, error);
            }
        }
    }

    async function claimEvents() {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const result = await client.query(
                `
                SELECT id, event_key, module_name, class_name, board,
                       subject_id, title, message, roll_no
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
        if (event.module_name === 'fees' && event.roll_no) {
            const result = await pool.query(
                `
                SELECT DISTINCT s.roll_no
                FROM students s
                WHERE UPPER(TRIM(s.roll_no)) = UPPER(TRIM($1))
                `,
                [event.roll_no]
            );
            return result.rows;
        }

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
                if (event.module_name === 'fees') {
                    await pool.query(
                        `
                        DELETE FROM student_notifications
                        WHERE UPPER(TRIM(roll_no)) = UPPER(TRIM($1))
                          AND module_name = 'fees'
                        `,
                        [student.roll_no]
                    );

                    await pool.query(
                        `
                        INSERT INTO student_notifications
                            (roll_no, module_name, message, is_read)
                        VALUES ($1, 'fees', $2, FALSE)
                        `,
                        [student.roll_no, event.message]
                    );
                }

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
            try {
                await sendWeeklyAttendanceReminder();
            } catch (error) {
                console.error('Weekly attendance reminder failed:', error);
            }

            try {
                await sendFeePaymentReminders();
            } catch (error) {
                console.error('Fee payment reminder cycle failed:', error);
            }

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