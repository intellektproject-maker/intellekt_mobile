# Faculty notification deployment

The faculty notification worker depends on these additive tables:

- `faculty_device_tokens`
- `faculty_task_notification_events`

Apply `20260910_faculty_notifications.sql` to the production PostgreSQL database before enabling faculty push/reminder testing.

The application start command intentionally does not execute migrations automatically. This avoids startup failures caused by database migration errors and prevents application startup from being coupled to schema changes.

## Verification

After applying the migration, verify:

```sql
SELECT to_regclass('public.faculty_device_tokens');
SELECT to_regclass('public.faculty_task_notification_events');
```

Both queries should return their table names.

Then verify the existing faculty token route can write to `faculty_device_tokens` and that the notification worker can claim reminder events in `faculty_task_notification_events`.

Do not modify or migrate any student notification table as part of this deployment.
