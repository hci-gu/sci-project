require('dotenv').config()

const express = require('express')
const cors = require('cors')
const app = express()
app.use(cors())
app.use(express.json({ limit: '50mb' }))

const mongo = require('./mongo')

app.use(async (_, __, next) => {
  await mongo.init()
  next()
})

app.get('/ping', (_, res) => {
  res.send('pong')
})

app.post('/data', (req, res) => {
  console.log('received data')
  const { accel, heartRate, heartRateVariability } = req.body
  console.log(
    'accel.length',
    accel.length,
    'heartRate.length',
    heartRate.length,
    'heartRateVariability.length',
    heartRateVariability.length
  )
  const dataPoints = [
    ...accel.map((p) => ({ ...p, type: 'accel' })),
    ...heartRate.map((p) => ({ ...p, type: 'heartRate' })),
    ...heartRateVariability.map((p) => ({
      ...p,
      type: 'heartRateVariability',
    })),
  ]
  mongo.save(dataPoints)
  res.sendStatus(200)
})

app.get('/data', async (req, res) => {
  const { type, offset, limit } = req.query
  const dataPoints = await mongo.get(
    { type },
    { offset: parseInt(offset), limit: parseInt(limit) }
  )
  res.json(dataPoints)
})

app.listen(4000, () => console.log('listening on port 4000'))
