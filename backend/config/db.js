/**
 * AquaGuard AI — PostgreSQL Connection Pool & Auto-Initializer
 */

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const connectionString = process.env.DATABASE_URL || 
  `postgresql://${process.env.PGUSER || 'postgres'}:${process.env.PGPASSWORD || 'postgres'}@${process.env.PGHOST || '127.0.0.1'}:${process.env.PGPORT || 5433}/${process.env.PGDATABASE || 'aquaguard_db'}`;

const pool = new Pool({
  connectionString,
  ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

let isConnected = false;

pool.on('connect', () => {
  if (!isConnected) {
    console.log('✅ PostgreSQL Database connected successfully (aquaguard_db).');
    isConnected = true;
  }
});

pool.on('error', (err) => {
  console.error('❌ Unexpected PostgreSQL pool error:', err.message);
});

/**
 * Initialize Tables from schema.sql if not existing
 */
async function initializeDatabase() {
  try {
    const client = await pool.connect();
    console.log('🔄 Checking PostgreSQL schema status...');

    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'complaints'
      );
    `);

    if (!tableCheck.rows[0].exists) {
      console.log('⚙️ Initializing database tables & seeds from schema.sql...');
      const schemaPath = path.join(__dirname, '..', 'schema.sql');
      if (fs.existsSync(schemaPath)) {
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');
        await client.query(schemaSql);
        console.log('✅ PostgreSQL database tables and initial seed data created successfully!');
      }
    } else {
      console.log('✅ PostgreSQL database tables verified and ready.');
      isConnected = true;
    }

    client.release();
  } catch (error) {
    console.warn('⚠️ Note: PostgreSQL connection check at', connectionString, 'message:', error.message);
    console.warn('💡 Tip: AquaGuard AI backend runs with memory cache fallback if PostgreSQL is offline.');
  }
}

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
  initializeDatabase,
  isConnected: () => isConnected
};
