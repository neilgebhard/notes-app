const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { Pool } = require('pg');

let pool;

async function getDbCredentials() {
  const client = new SecretsManagerClient();
  const response = await client.send(
    new GetSecretValueCommand({ SecretId: process.env.DB_SECRET_ARN })
  );
  return JSON.parse(response.SecretString);
}

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

    const noteId = event.pathParameters?.id;
    if (!noteId) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({ error: 'Note ID is required' }),
      };
    }

    const pool = await getPool();

    const result = await pool.query(
      'DELETE FROM notes WHERE id = $1 AND user_id = $2 RETURNING id',
      [noteId, userId]
    );

    if (result.rows.length === 0) {
      return {
        statusCode: 404,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({ error: 'Note not found' }),
      };
    }

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        message: 'Note deleted successfully',
        id: result.rows[0].id,
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
