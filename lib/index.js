require('dotenv').config()

const express = require('express')
const cors = require('cors')
const app = express()
app.use(cors())
app.use(express.json({ limit: '50mb' }))

const mongo = require('./mongo')
const fitbit = require('./fitbit')

app.use(async (_, __, next) => {
  await mongo.init()
  next()
})

app.get('/ping', (_, res) => {
  console.log('?????')
  res.send('pong')
})

app.post('/fitbit', (req, res) => {
  const { hrDataPoints, accelDataPoints } = fitbit.handleData(req.body)
  if (hrDataPoints.length) mongo.save('sensor-data-hr', hrDataPoints)
  if (accelDataPoints.length) mongo.save('sensor-data-accel', accelDataPoints)
  res.sendStatus(200)
})

app.post('/data', (req, res) => {
  const { accel, heartRate, heartRateVariability } = req.body
  const dataPoints = [
    ...accel.map((p) => ({ ...p, type: 'accel' })),
    ...heartRate.map((p) => ({ ...p, type: 'heartRate' })),
    ...heartRateVariability.map((p) => ({
      ...p,
      type: 'heartRateVariability',
    })),
  ]
  mongo.save('sensor-data', dataPoints)
  res.sendStatus(200)
})

app.get('/data', async (req, res) => {
  const { type, offset, limit } = req.query
  const dataPoints = await mongo.get(
    'sensor-data',
    { type },
    { offset: parseInt(offset), limit: parseInt(limit) }
  )
  res.json(dataPoints)
})

app.get('/data/:type', async (req, res) => {
  const { type } = req.params
  const { offset, limit } = req.query

  const dataPoints = await mongo.get(
    `sensor-data-${type}`,
    {},
    { offset: parseInt(offset), limit: parseInt(limit) }
  )
  res.json(dataPoints)
})

app.listen(4000, () => console.log('listening on port 4000'))
