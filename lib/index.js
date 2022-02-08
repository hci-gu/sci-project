require('dotenv').config()

const express = require('express')
const cors = require('cors')
const app = express()
app.use(cors())
app.use(express.json({ limit: '50mb' }))

const mongo = require('./mongo')
const pg = require('./pg')
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
  if (hrDataPoints.length) pg.saveHr(hrDataPoints)
  if (accelDataPoints.length) pg.saveAccel(accelDataPoints)
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

// v0.1 apple watch in mongo
app.get('/data', async (req, res) => {
  const { type, offset, limit } = req.query
  const dataPoints = await mongo.get(
    'sensor-data',
    { type },
    { offset: parseInt(offset), limit: parseInt(limit) }
  )
  res.json(dataPoints)
})

// v0.2 fitbit in mongo, bad timestamps
app.get('/mongo/data/:type', async (req, res) => {
  const { type } = req.params
  const { offset, limit } = req.query

  const dataPoints = await mongo.get(
    `sensor-data-${type}`,
    {},
    { offset: parseInt(offset), limit: parseInt(limit) }
  )
  res.json(dataPoints)
})

// v0.3 fitbit in postgres, fixed timestamps
app.get('/data/:type', async (req, res) => {
  const { type } = req.params
  let { from, to, group } = req.query

  if (!from) {
    from = new Date()
    from.setDate(from.getDate() - 1)
  }
  if (!to) {
    to = new Date()
  }

  let dataPoints = []
  if (!group) {
    dataPoints = await pg.get({
      type,
      from: new Date(from).toISOString(),
      to: new Date(to).toISOString(),
    })
  } else {
    dataPoints = await pg.aggregate({
      type,
      from: new Date(from).toISOString(),
      to: new Date(to).toISOString(),
      unit: group,
    })
  }

  res.json(dataPoints)
})

app.listen(4000, () => console.log('listening on port 4000'))
