import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import AccelCountModel from '../../db/models/AccelCount'
import AccelModel from '../../db/models/Accel'
import HeartRateModel from '../../db/models/HeartRate'

const router = express.Router()

import handleFitbitData from '../../adapters/fitbit'
import { checkAndSaveCounts } from './utils'
import {
  getQuery,
  GetQuerySchema,
  userBody,
  UserBodySchema,
} from './validation'
import UserModel, {
  ForbiddenError,
  hashPassword,
  NotFoundError,
} from '../../db/models/User'
import { User } from '../../db/classes'

const stripSensitive = (user: User) => {
  const { password, ...rest } = user.toJSON()
  return rest
}

const returnUser = async (user: User) => {
  const hasData = await AccelCountModel.hasData(user.id)
  return {
    ...stripSensitive(user),
    hasData,
  }
}

router.post('/', userBody, async (req, res) => {
  try {
    const result = await UserModel.save(req.body)
    res.send(await returnUser(result))
  } catch (e) {
    if (e instanceof ForbiddenError) {
      return res.sendStatus(403)
    }
    res.sendStatus(500)
  }
})

router.get('/:id', async (req, res) => {
  const { id } = req.params

  try {
    const result = await UserModel.get(id)

    if (!result) {
      return res.sendStatus(404)
    }
    return res.send(await returnUser(result))
  } catch (e) {
    return res.sendStatus(500)
  }
})

router.patch(
  '/:id',
  userBody,
  async (req: ValidatedRequest<UserBodySchema>, res) => {
    const { id } = req.params

    try {
      const user = await UserModel.get(id)

      if (!user) {
        return res.sendStatus(404)
      }

      let property: keyof typeof req.body
      for (property in req.body) {
        const value = req.body[property]
        if (value == null) continue
        if (property === 'password') {
          const pw = await hashPassword(value as string)
          user.set(property, pw)
        } else if (property == 'injuryLevel' && typeof value === 'number') {
          if (value > 0) {
            user.set(property, value as number)
          }
        } else {
          user.set(property, value)
        }
      }

      await user.save()

      return res.send(await returnUser(user))
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

router.post(
  '/login',
  userBody,
  async (req: ValidatedRequest<UserBodySchema>, res) => {
    const { email, password } = req.body

    try {
      const user = await UserModel.login(email, password)
      return res.send(await returnUser(user))
    } catch (e) {
      console.log(e)
      if (e instanceof NotFoundError) {
        return res.sendStatus(404)
      }
      if (e instanceof ForbiddenError) {
        return res.sendStatus(403)
      }
      return res.sendStatus(500)
    }
  }
)

router.delete('/:id', async (req, res) => {
  try {
    await UserModel.delete(req.params.id)
    res.sendStatus(200)
  } catch (e) {
    res.sendStatus(500)
  }
})

export default router
