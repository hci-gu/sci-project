import { config } from 'dotenv'
config()

import db from './db/index.ts'
import createServer from './server.ts'
import './cron.ts'

const { DB_HOST, DB_USERNAME, DB_PASSWORD, DB } = process.env

const [host, port] = DB_HOST?.split(':') ?? ['localhost', '5678']

db({
  database: DB ?? 'sci',
  username: DB_USERNAME ?? 'admin',
  password: DB_PASSWORD ?? 'password',
  host,
  port: port ? parseInt(port) : 5432,
})

const app = createServer()
app.listen(4000, () => console.log('listening on port 4000'))
