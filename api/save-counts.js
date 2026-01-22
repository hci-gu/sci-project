const { Client } = require('pg')
const fs = require('fs')
const { createObjectCsvWriter } = require('csv-writer')

// Database connection configuration
const dbConfig = {
  user: 'admin',
  host: 'localhost',
  database: 'sci',
  password: 'appademinpassword',
  port: 5432, // Default PostgreSQL port
}

// CSV file path
const csvFilePath = './Energy.csv'

// Create a CSV writer
const csvWriter = createObjectCsvWriter({
  path: csvFilePath,
  header: [
    { id: 'id', title: 'ID' },
    { id: 't', title: 'Timestamp' },
    { id: 'kcal', title: 'Kcal' },
    { id: 'activity', title: 'Activity' },
    { id: 'UserId', title: 'User ID' },
  ],
})

async function exportToCsv() {
  const client = new Client(dbConfig)

  try {
    // Connect to the database
    await client.connect()

    // Query to fetch all data from the AccelCounts table
    const query = 'SELECT * FROM "Energies"'
    const res = await client.query(query)

    if (res.rows.length === 0) {
      console.log('No data found in the AccelCounts table.')
      return
    }

    // Write data to the CSV file
    await csvWriter.writeRecords(res.rows)
    console.log(`Data successfully written to ${csvFilePath}`)
  } catch (err) {
    console.error('Error exporting data to CSV:', err)
  } finally {
    // Close the database connection
    await client.end()
  }
}

// Run the export function
exportToCsv()
