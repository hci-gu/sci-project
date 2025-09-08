import express from 'express'
import cors from 'cors'
import router from './routes/index.js'

export default () => {
  const app = express()
  app.use(cors())
  app.use(express.json({ limit: '50mb' }))

  app.use(router)
  return app
}
