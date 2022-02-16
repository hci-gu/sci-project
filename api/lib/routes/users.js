const express = require('express')
const { User, Accel, HeartRate } = require('../db')
const router = express.Router()

const fitbit = require('../adapters/fitbit')

router.post('/', async (req, res) => {
  console.log('save user ', req.body)
  const result = await User.save(req.body)
  res.send(result)
})

router.get('/:id', async (req, res) => {
  const { id } = req.params

  const result = await User.get(id)
  res.send(result)
})

router.post('/:id/data', async (req, res) => {
  const { id } = req.params
  const { hrDataPoints, accelDataPoints } = fitbit.handleData(req.body)

  if (accelDataPoints.length) Accel.save(accelDataPoints, id)
  if (hrDataPoints.length) HeartRate.save(hrDataPoints, id)

  res.sendStatus(200)
})

router.get('/:id/data/:type', async (req, res) => {
  const { id, type } = req.params
  let { from, to, group } = req.query

  if (!from) {
    from = new Date()
    from.setDate(from.getDate() - 1)
  }
  if (!to) {
    to = new Date()
  }

  const model = type === 'accel' ? Accel : HeartRate
  let dataPoints = []
  if (!group) {
    dataPoints = await model.find({
      type,
      from: new Date(from).toISOString(),
      to: new Date(to).toISOString(),
    })
  } else {
    dataPoints = await model.group({
      type,
      from: new Date(from).toISOString(),
      to: new Date(to).toISOString(),
      unit: group,
    })
  }

  res.json(dataPoints)
})

module.exports = router
