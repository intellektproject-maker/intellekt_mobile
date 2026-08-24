/* =========================================================
   FEE REMINDER POLICY
   ---------------------------------------------------------
   The faculty controls reminder_enabled in fees.

   TRUE  -> the worker may send one polite pending-fee
            reminder per student per calendar day while
            there is still an outstanding balance.

   FALSE -> no fee-payment reminder is sent.

   The normal "Fees Details Have been Updated" event is
   independent of this flag and is still generated when
   reminder_enabled itself changes.
========================================================= */

CREATE INDEX IF NOT EXISTS idx_fees_reminder_policy
ON fees (reminder_enabled, last_reminder_sent_at);
