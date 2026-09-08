require('dotenv').config();

const fs = require('fs');
const path = require('path');
const pool = require('./db');

async function run() {
  const migrationsDir = path.join(__dirname, 'migrations');
  const files = fs.readdirSync(migrationsDir)
    .filter((file) => file.endsWith('.sql'))
    .sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    if (!sql.trim()) continue;
    console.log(`Running migration: ${file}`);
    await pool.query(sql);
  }

  console.log('Database migrations completed.');
}

run()
  .catch((error) => {
    console.error('Database migration failed:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
