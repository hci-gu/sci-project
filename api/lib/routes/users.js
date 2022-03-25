const express = require('express')
const { User, Accel, AccelCount, HeartRate } = require('../db/models')
const router = express.Router()

const fitbit = require('../adapters/fitbit')
const { getEnergy } = require('../adapters/energy')
const { calculateCounts } = require('../adapters/counts')

const checkAndSaveCounts = async (userId) => {
  const now = new Date()
  const from = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate(),
    now.getHours(),
    now.getMinutes() - 1
  )
  const to = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate(),
    now.getHours(),
    now.getMinutes() - 1,
    59
  )

  const accelCounts = await AccelCount.find({
    userId,
    from,
    to,
  })

  if (!!accelCounts.length) {
    return
  }

  const [accel, hr] = await Promise.all([
    Accel.find({ userId, from, to }),
    HeartRate.find({ userId, from, to }),
  ])

  if (accel.length < 1800) {
    return
  }
  const counts = await calculateCounts({ accel, hr })
  await AccelCount.save(counts, userId)
}

router.post('/', async (req, res) => {
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

  const result = await User.get(id)

  if (!result) {
    return res.sendStatus(404)
  }
  return res.send(result)
})

router.patch('/:id', async (req, res) => {
  const { id } = req.params
  const { weight } = req.body

  try {
    const user = await User.get(id)

    if (!user) {
      return res.sendStatus(404)
    }

    user.weight = parseInt(weight)

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
