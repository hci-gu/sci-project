const express = require('express')
const { User, Accel, HeartRate } = require('../../db/models')
const Joi = require('joi')
const validator = require('express-joi-validation').createValidator({})

const router = express.Router()

const fitbit = require('../../adapters/fitbit')
const {
  checkAndSaveCounts,
  energyForPeriod,
  activityForPeriod,
  promiseSeries,
} = require('./utils')
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
    console.log('POST /users/:id/data', e)
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
    return res.sendStatus(500)
  }

  res.json(dataPoints)
})

const querySchema = Joi.object({
  from: Joi.string(),
  to: Joi.string(),
  activity: Joi.string(),
  gender: Joi.string(),
  condition: Joi.string(),
  watt: Joi.number(),
  injuryLevel: Joi.number(),
  weight: Joi.number(),
})
router.get('/:id/energy', validator.query(querySchema), async (req, res) => {
  const { id } = req.params
  const now = new Date()
  const {
    from = new Date().setDate(now.getDate() - 1),
    to = now,
    activity,
    watt,
  } = req.query

  try {
    const energy = await energyForPeriod({
      id,
      from,
      to,
      activity,
      watt,
      overwrite: req.query,
    })

    return res.json(energy)
  } catch (e) {
    console.log('GET /users/:id/energy', e)
    return res.sendStatus(500)
  }
})

router.get('/:id/energy/today', async (req, res) => {
  const { id } = req.params
  const { activity, watt } = req.query
  const now = new Date()
  const startOfDay = new Date(now.setHours(0, 0, 0, 0))
  const endOfDay = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate(),
    23,
    59,
    59
  )

  try {
    const energy = await energyForPeriod({
      id,
      activity,
      watt,
      from: startOfDay,
      to: endOfDay,
    })

    return res.json({
      energy: energy.reduce((acc, curr) => acc + curr.energy, 0),
    })
  } catch (e) {
    console.log('GET /users/:id/energy/today', e)
    return res.sendStatus(500)
  }
})

router.get('/:id/activity', async (req, res) => {
  const { id } = req.params
  const now = new Date()
  const { from = new Date().setDate(now.getDate() - 1), to = now } = req.query

  try {
    const activity = await activityForPeriod({
      id,
      from,
      to,
    })

    return res.json(activity)
  } catch (e) {
    console.log('GET /users/:id/activity', e)
    return res.sendStatus(500)
  }
})

// repair missing counts,
router.get('/:id/fill', async (req, res) => {
  await promiseSeries([], (date) => {
    return checkAndSaveCounts('5abdb7ad-f973-46ae-b1f1-1bc904885068', date)
  })
  res.send('done')
})

module.exports = router
