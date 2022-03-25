const express = require('express')
const { User, Accel, AccelCount, HeartRate } = require('../../db/models')
const router = express.Router()

const fitbit = require('../../adapters/fitbit')
const { getEnergy } = require('../../adapters/energy')
const { checkAndSaveCounts } = require('./utils')
const validation = require('./validation')

router.post('/', validation.userBody, async (req, res) => {
  const result = await User.save(req.body)
  res.send(result)
})

router.get('/register', async (req, res) => {
  const { redirect_uri, state } = req.query

  const user = await User.save(req.body)

  res.redirect(`${redirect_uri}?state=${state}&userId=${user.id}`)
})

router.get('/:id', async (req, res) => {
  const { id } = req.params

  try {
    const result = await User.get(id)

    if (!result) {
      return res.sendStatus(404)
    }
    return res.send(result)
  } catch (e) {
    return res.sendStatus(500)
  }
})

router.patch('/:id', validation.userBody, async (req, res) => {
  const { id } = req.params

  try {
    const user = await User.get(id)

    if (!user) {
      return res.sendStatus(404)
    }

    Object.keys(req.body).forEach((key) => {
      user[key] = req.body[key]
    })

    await user.save()

    return res.send(user)
  } catch (e) {
    return res.sendStatus(500)
  }
})

router.post('/:id/data', async (req, res) => {
  const { id } = req.params
  const { hrDataPoints, accelDataPoints } = fitbit.handleData(req.body)

  try {
    if (accelDataPoints.length) await Accel.save(accelDataPoints, id)
    if (hrDataPoints.length) await HeartRate.save(hrDataPoints, id)
    await checkAndSaveCounts(id)
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
  } catch (e) {}

  res.json(dataPoints)
})

router.get('/:id/energy', async (req, res) => {
  const { id } = req.params
  const now = new Date()
  const {
    from = new Date().setDate(now.getDate() - 1),
    to = now,
    mode,
  } = req.query

  const user = await User.get(id)
  const counts = await AccelCount.find({
    userId: id,
    from: new Date(from).toISOString(),
    to: new Date(to).toISOString(),
  })
  const energy = await getEnergy({ counts, weight: user.weight })

  return res.json(energy)
})

module.exports = router
