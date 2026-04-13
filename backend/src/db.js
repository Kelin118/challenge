import { Pool } from 'pg';

import { env } from './config/env.js';

const databaseUrl = env.databaseUrl;

export const pool = databaseUrl
  ? new Pool({
      connectionString: databaseUrl,
    })
  : null;

if (!pool) {
  console.warn('DATABASE_URL is not set. PostgreSQL connection is disabled.');
} else {
  pool.on('error', (error) => {
    console.error('Unexpected PostgreSQL pool error:', error);
  });
}

export async function query(text, params) {
  if (!pool) {
    throw new Error('DATABASE_URL is not configured.');
  }

  return pool.query(text, params);
}

export async function withTransaction(callback) {
  if (!pool) {
    throw new Error('DATABASE_URL is not configured.');
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    throw error;
  } finally {
    client.release();
  }
}

export async function connectDatabase() {
  if (!pool) {
    return false;
  }

  try {
    await query('SELECT 1');
    console.log('PostgreSQL connected');
    return true;
  } catch (error) {
    console.error('Failed to connect to PostgreSQL:', error);
    return false;
  }
}
