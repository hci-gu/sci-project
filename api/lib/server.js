const express = require('express')
const cors = require('cors')
const router = require('./routes')

module.exports = () => {
  const app = express()
  app.use(cors())
  app.use(express.json({ limit: '50mb' }))

  app.use(router)
  return app
}
