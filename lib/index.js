require('dotenv').config()

const express = require('express')
const cors = require('cors')
const app = express()
app.use(cors())
app.use(express.json({ limit: '50mb' }))

const pg = require('./pg')
const fitbit = require('./fitbit')

app.get('/ping', (_, res) => res.send('pong'))

app.post('/fitbit', (req, res) => {
  const { hrDataPoints, accelDataPoints } = fitbit.handleData(req.body)
  if (hrDataPoints.length) pg.saveHr(hrDataPoints)
  if (accelDataPoints.length) pg.saveAccel(accelDataPoints)
  res.sendStatus(200)
})

app.post('/apple-watch', (req, res) => {
  const { accel, heartRate, heartRateVariability } = req.body
  const dataPoints = [
    ...accel.map((p) => ({ ...p, type: 'accel' })),
    ...heartRate.map((p) => ({ ...p, type: 'heartRate' })),
    ...heartRateVariability.map((p) => ({
      ...p,
      type: 'heartRateVariability',
    })),
  ]
  console.log(dataPoints.length)
  res.sendStatus(200)
})

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
