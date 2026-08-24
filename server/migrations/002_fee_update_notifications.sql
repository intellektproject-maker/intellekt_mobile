/* =========================================================
   FEE UPDATE NOTIFICATIONS
   ---------------------------------------------------------
   Enqueue a targeted notification whenever a student-facing
   fee field changes in the fees table.

   reminder_enabled is included so switching the faculty
   reminder ON/OFF also produces the normal fee-update
   notification. last_reminder_sent_at is intentionally
   excluded because it is maintained by the reminder worker.
========================================================= */

ALTER TABLE notification_events
ADD COLUMN IF NOT EXISTS roll_no VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_notification_events_roll_no
ON notification_events (UPPER(TRIM(roll_no)));

CREATE OR REPLACE FUNCTION enqueue_fee_update_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF
        OLD.roll_no IS DISTINCT FROM NEW.roll_no
        OR OLD.total_fee IS DISTINCT FROM NEW.total_fee
        OR OLD.fee_paid IS DISTINCT FROM NEW.fee_paid
        OR OLD.next_due IS DISTINCT FROM NEW.next_due
        OR OLD.reminder_enabled IS DISTINCT FROM NEW.reminder_enabled
    THEN
        INSERT INTO notification_events (
            event_key,
            module_name,
            roll_no,
            title,
            message,
            status,
            attempts,
            available_at,
            created_at,
            updated_at
        )
        VALUES (
            'fee-update:' || UPPER(TRIM(NEW.roll_no)) || ':' ||
                md5(
                    UPPER(TRIM(COALESCE(NEW.roll_no, ''))) || ':' ||
                    clock_timestamp()::text || ':' ||
                    random()::text
                ),
            'fees',
            UPPER(TRIM(NEW.roll_no)),
            'Fees Details Updated',
            'Fees Details Have been Updated',
            'pending',
            0,
            NOW(),
            NOW(),
            NOW()
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_fee_update_notification ON fees;

CREATE TRIGGER trg_fee_update_notification
AFTER UPDATE OF roll_no, total_fee, fee_paid, next_due, reminder_enabled
ON fees
FOR EACH ROW
EXECUTE FUNCTION enqueue_fee_update_notification();
