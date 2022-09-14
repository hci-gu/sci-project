import express from 'express'
import Joi from 'joi'
import { createValidator, ValidatedRequest } from 'express-joi-validation'
const validator = createValidator({})
import UserModel from '../../db/models/User'
import AccelModel from '../../db/models/Accel'
import AccelCountModel from '../../db/models/AccelCount'
import HeartRateModel from '../../db/models/HeartRate'

const router = express.Router()

const handleFitbitData = require('../../adapters/fitbit')
import {
  checkAndSaveCounts,
  energyForPeriod,
  activityForPeriod,
  fromToForDate,
} from './utils'
import { getQuery, GetQuerySchema, UserBodySchema } from './validation'
const validation = require('./validation')

router.post('/', validation.userBody, async (req, res) => {
  const result = await UserModel.save(req.body)
  res.send(result)
})

router.get('/register', async (req, res) => {
  const { redirect_uri, state } = req.query

  const user = await UserModel.save(req.body)

  res.redirect(`${redirect_uri}?state=${state}&userId=${user.id}`)
})

router.get('/:id', async (req, res) => {
  const { id } = req.params

  try {
    const result = await UserModel.get(id)

    if (!result) {
      return res.sendStatus(404)
    }
    return res.send(result)
  } catch (e) {
    return res.sendStatus(500)
  }
})

router.patch(
  '/:id',
  validation.userBody,
  async (req: ValidatedRequest<UserBodySchema>, res) => {
    const { id } = req.params

    try {
      const user = await UserModel.get(id)

      if (!user) {
        return res.sendStatus(404)
      }

      let property: keyof typeof req.body
      for (property in req.body) {
        user.set(property, req.body[property])
      }

      await user.save()

      return res.send(user)
    } catch (e) {
      return res.sendStatus(500)
    }
  }
)

router.post('/:id/data', async (req, res) => {
  const { id } = req.params
  const { hrDataPoints, accelDataPoints } = handleFitbitData(req.body)

  try {
    if (accelDataPoints.length) await AccelModel.save(accelDataPoints, id)
    if (hrDataPoints.length) await HeartRateModel.save(hrDataPoints, id)
    await checkAndSaveCounts(id, accelDataPoints, hrDataPoints)
  } catch (e) {
    console.log('POST /users/:id/data', e)
    return res.sendStatus(400)
  }

  res.sendStatus(200)
})

router.get(
  '/:id/data/:type',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id, type } = req.params
    let { from, to, group } = req.query

    const model = type === 'accel' ? AccelModel : HeartRateModel
    let dataPoints = []
    try {
      if (!group) {
        dataPoints = await model.find({
          userId: id,
          from,
          to,
        })
      } else {
        dataPoints = await model.group({
          userId: id,
          from,
          to,
          unit: group,
        })
      }
    } catch (e) {
      return res.sendStatus(500)
    }

    res.json(dataPoints)
  }
)

router.get(
  '/:id/energy',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params
    const now = new Date()
    const { from, to, activity, watt } = req.query

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
  }
)

router.get(
  '/:id/energy/today',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params
    const { activity, watt } = req.query
    const [from, to] = fromToForDate(new Date())

    try {
      const energy = await energyForPeriod({
        id,
        activity,
        watt,
        from,
        to,
      })

      return res.json({
        energy: energy.reduce((acc, curr) => acc + curr.energy, 0),
      })
    } catch (e) {
      console.log('GET /users/:id/energy/today', e)
      return res.sendStatus(500)
    }
  }
)

router.get(
  '/:id/activity',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params
    const { from, to } = req.query

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
  }
)

router.get('/:id/day/:date', async (req, res) => {
  const [from, to] = fromToForDate(new Date(req.params.date))

  res.send({
    from,
    to,
  })
})

export default router
