require('dotenv').config()
const db = require('./db')
const createServer = require('./server')

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB } = process.env

db({
  database: DB,
  username: DB_USERNAME,
  password: DB_PASSWORD,
  host: DB_HOST,
  port: DB_PORT,
})

const app = createServer()
app.listen(4000, () => console.log('listening on port 4000'))
