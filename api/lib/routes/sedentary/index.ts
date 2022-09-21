import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import { getQuery, GetQuerySchema } from '../validation'
import { activityForPeriod } from './utils'

const router = express.Router()

router.get(
  '/:id',
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

export default router
