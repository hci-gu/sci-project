const express = require('express')
const { User, Accel, HeartRate } = require('../db/models')
const router = express.Router()

const fitbit = require('../adapters/fitbit')

router.post('/', async (req, res) => {
  const result = await User.save(req.body)
  res.send(result)
})

router.get('/:id', async (req, res) => {
  const { id } = req.params

  const result = await User.get(id)

  if (!result) {
    return res.sendStatus(404)
  }
  return res.send(result)
})

router.post('/:id/data', async (req, res) => {
  const { id } = req.params
  const { hrDataPoints, accelDataPoints } = fitbit.handleData(req.body)

  try {
    if (accelDataPoints.length) await Accel.save(accelDataPoints, id)
    if (hrDataPoints.length) await HeartRate.save(hrDataPoints, id)
  } catch (e) {
    return res.sendStatus(400)
  }

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
  try {
    if (!group) {
      dataPoints = await model.find({
        userId: id,
        type,
        from: new Date(from).toISOString(),
        to: new Date(to).toISOString(),
      })
    } else {
      dataPoints = await model.group({
        userId: id,
        type,
        from: new Date(from).toISOString(),
        to: new Date(to).toISOString(),
        unit: group,
      })
    }
  } catch (e) {
    console.log(e)
  }

  res.json(dataPoints)
})

module.exports = router
