'use strict';

const { createFacultyNotification } = require('./faculty-notification-service');

const TIME_ZONE = process.env.FACULTY_NOTIFICATION_TIMEZONE || 'Asia/Kolkata';
const INTERVAL_MS = Number(process.env.FACULTY_NOTIFICATION_WORKER_INTERVAL_MS) || 30000;
const WINDOW_MINUTES = Number(process.env.FACULTY_NOTIFICATION_WINDOW_MINUTES) || 5;

function getZonedParts(date = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: TIME_ZONE,
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', hourCycle: 'h23'
  }).formatToParts(date);
  return Object.fromEntries(
    parts.filter((p) => p.type !== 'literal').map((p) => [p.type, p.value])
  );
}

function dateStringOffset(dateString, days) {
  const date = new Date(`${dateString}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

function isWithinWindow(hour, minute, targetHour) {
  return hour === targetHour && minute >= 0 && minute < WINDOW_MINUTES;
}

function messageFor(eventType, task) {
  if (eventType === 'due-soon') {
    return `Task due tomorrow: ${task.other_tasks || task.total_test_note || 'Please complete your assigned task.'}`;
  }
  if (eventType === 'due-tomorrow') {
    return `Reminder: your task is due tomorrow${task.other_tasks ? ` — ${task.other_tasks}` : '.'}`;
  }
  return `Overdue task: ${task.other_tasks || task.total_test_note || 'Please complete your assigned task.'}`;
}

async function claimEvent(pool, task, eventType, eventDate) {
  const result = await pool.query(
    `INSERT INTO faculty_task_notification_events
       (task_id, faculty_id, event_type, event_date)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (task_id, faculty_id, event_type, event_date) DO NOTHING
     RETURNING id`,
    [task.id, task.faculty_id, eventType, eventDate]
  );
  return result.rowCount > 0;
}

async function processFacultyTaskReminders(pool) {
  const now = getZonedParts();
  const hour = Number(now.hour);
  const minute = Number(now.minute);
  const today = `${now.year}-${now.month}-${now.day}`;
  const tomorrow = dateStringOffset(today, 1);

  const dueSoonWindow = isWithinWindow(hour, minute, 0);
  const afternoonWindow = isWithinWindow(hour, minute, 15);
  if (!dueSoonWindow && !afternoonWindow) return;

  const dueResult = await pool.query(
    `SELECT id, faculty_id, faculty_name, other_tasks, total_test_note, due_date
     FROM faculty_tasks
     WHERE is_completed = FALSE
       AND due_date IS NOT NULL
       AND due_date = $1::date`,
    [tomorrow]
  );

  if (dueSoonWindow) {
    for (const task of dueResult.rows) {
      if (!(await claimEvent(pool, task, 'due-soon', tomorrow))) continue;
      await createFacultyNotification(pool, {
        facultyId: task.faculty_id,
        moduleName: 'tasks',
        message: messageFor('due-soon', task),
        title: 'Task Due Tomorrow',
        data: { module: 'tasks', taskId: task.id, event: 'due-soon' }
      });
    }
  }

  if (afternoonWindow) {
    for (const task of dueResult.rows) {
      if (!(await claimEvent(pool, task, 'due-tomorrow', tomorrow))) continue;
      await createFacultyNotification(pool, {
        facultyId: task.faculty_id,
        moduleName: 'tasks',
        message: messageFor('due-tomorrow', task),
        title: 'Task Due Tomorrow',
        data: { module: 'tasks', taskId: task.id, event: 'due-tomorrow' }
      });
    }

    const overdueResult = await pool.query(
      `SELECT id, faculty_id, faculty_name, other_tasks, total_test_note, due_date
       FROM faculty_tasks
       WHERE is_completed = FALSE
         AND due_date IS NOT NULL
         AND due_date < $1::date`,
      [today]
    );

    for (const task of overdueResult.rows) {
      if (!(await claimEvent(pool, task, 'overdue', today))) continue;
      await createFacultyNotification(pool, {
        facultyId: task.faculty_id,
        moduleName: 'tasks',
        message: messageFor('overdue', task),
        title: 'Task Overdue',
        data: { module: 'tasks', taskId: task.id, event: 'overdue' }
      });
    }
  }
}

function createFacultyNotificationWorker({ pool, intervalMs = INTERVAL_MS } = {}) {
  if (!pool || typeof pool.query !== 'function') {
    throw new Error('Faculty notification worker requires a PostgreSQL pool');
  }

  let timer = null;
  let running = false;

  async function run() {
    if (running) return;
    running = true;
    try {
      await processFacultyTaskReminders(pool);
    } catch (error) {
      console.error('Faculty notification worker error:', error);
    } finally {
      running = false;
    }
  }

  return {
    start() {
      if (timer) return;
      void run();
      timer = setInterval(() => void run(), intervalMs);
      console.log(`Faculty notification worker started (${TIME_ZONE})`);
    },
    stop() {
      if (!timer) return;
      clearInterval(timer);
      timer = null;
    },
    runNow: run
  };
}

module.exports = { createFacultyNotificationWorker, processFacultyTaskReminders };
