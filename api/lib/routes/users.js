const express = require('express')
const { User, Accel, HeartRate, Energy } = require('../db/models')
const router = express.Router()

const fitbit = require('../adapters/fitbit')
const { getEnergy } = require('../adapters/energy')

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
  const now = new Date()
  let {
    from = new Date().setDate(now.getDate() - 1),
    to = now,
    group,
  } = req.query

  const model = type === 'accel' ? Accel : HeartRate
  let dataPoints = []
  try {
    if (!group) {
      dataPoints = await model.find({
        userId: id,
        from: new Date(from).toISOString(),
        to: new Date(to).toISOString(),
      })
    } else {
      dataPoints = await model.group({
        userId: id,
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

router.get('/:id/energy', async (req, res) => {
  const { id } = req.params
  const now = new Date()
  const {
    from = new Date().setDate(now.getDate() - 1),
    to = now,
    overwrite,
  } = req.query

  const rows = await Energy.find({
    userId: id,
    from: new Date(from).toISOString(),
    to: new Date(to).toISOString(),
  })

  if (!rows.length || !!overwrite) {
    const [accel, hr] = await Promise.all([
      await Accel.find({
        userId: id,
        from: new Date(from).toISOString(),
        to: new Date(to).toISOString(),
      }),
      await HeartRate.find({
        userId: id,
        from: new Date(from).toISOString(),
        to: new Date(to).toISOString(),
      }),
    ])
    const energy = await getEnergy({ accel, hr, weight: 70 })
    await Energy.save(energy, id)
    return res.json(energy.map((d) => ({ t: d.minute, value: d.energy })))
  }

  return res.json(rows)
})

module.exports = router
