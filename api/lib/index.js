require('dotenv').config()

const express = require('express')
const cors = require('cors')
const app = express()
app.use(cors())
app.use(express.json({ limit: '50mb' }))

require('./db')

const router = require('./routes')

app.use(router)

app.listen(4000, () => console.log('listening on port 4000'))
