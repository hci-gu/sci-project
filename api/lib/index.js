require('dotenv').config()
const db = require('./db')
const createServer = require('./server')
require('./cron')

const { DB_HOST, DB_USERNAME, DB_PASSWORD, DB } = process.env

const [host, port] = DB_HOST.split(':')

db({
  database: DB,
  username: DB_USERNAME,
  password: DB_PASSWORD,
  host,
  port,
})

const app = createServer()
app.listen(4000, () => console.log('listening on port 4000'))

const push = require('./push')

const run = () => {
  console.log(process.env)
  push.send({
    deviceId:
      '0bec4dba07f3dee988b5c69afe960aa741cc867b79013638615d9ba2ccdf155f',
    message: {
      title: 'Test',
      body: 'Test',
    },
  })
}

run()
