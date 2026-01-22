const { Pool } = require('pg')

// Database configuration
const pool = new Pool({
  user: 'admin',
  host: 'localhost',
  database: 'sci',
  password: 'appademinpassword',
  port: 5432, // Default PostgreSQL port
})

// Query to summarize the number of Accel data points and periods per user
const query = `
  SELECT 
    "UserId",
    COUNT(*) AS data_points,
    MIN(t) AS first_data_point,
    MAX(t) AS last_data_point
  FROM "Accels"
  GROUP BY "UserId";
`

async function summarizeAccelData() {
  try {
    const client = await pool.connect()
    const result = await client.query(query)
    client.release()

    // Process and display results
    console.log('Summary of Accel Data Points and Periods for Each User:')
    result.rows.forEach((row) => {
      console.log(`UserId: ${row.UserId}`)
      console.log(`  Data Points: ${row.data_points}`)
      console.log(`  Period: ${row.first_data_point} - ${row.last_data_point}`)
    })
  } catch (error) {
    console.error('Error querying the database:', error)
  } finally {
    await pool.end()
  }
}

// Run the summarization function
summarizeAccelData()
