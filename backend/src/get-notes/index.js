const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { Pool } = require('pg');

let pool;

// Get database credentials from Secrets Manager
async function getDbCredentials() {
  const client = new SecretsManagerClient();
  const response = await client.send(
    new GetSecretValueCommand({ SecretId: process.env.DB_SECRET_ARN })
  );
  return JSON.parse(response.SecretString);
}

// Initialize database connection pool
async function getPool() {
  if (!pool) {
    const credentials = await getDbCredentials();
    pool = new Pool({
      host: credentials.host,
      port: credentials.port,
      database: credentials.dbname,
      user: credentials.username,
      password: credentials.password,
      ssl: { rejectUnauthorized: false },
      max: 2,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });
  }
  return pool;
}

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  try {
    // Get user ID from Cognito authorizer
    const userId = event.requestContext?.authorizer?.claims?.sub;
    if (!userId) {
      return {
        statusCode: 401,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({ error: 'Unauthorized' }),
      };
    }

    const pool = await getPool();

    // Query notes for the user
    const result = await pool.query(
      'SELECT id, title, content, created_at, updated_at FROM notes WHERE user_id = $1 ORDER BY updated_at DESC',
      [userId]
    );

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        notes: result.rows,
        count: result.rows.length,
      }),
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Internal server error',
        message: error.message,
      }),
    };
  }
};
