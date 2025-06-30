import express from 'express'
import { type ValidatedRequest } from 'express-joi-validation'
import { getQuery, type GetQuerySchema } from '../validation.ts'
import { activityForPeriod } from './utils.ts'

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
      console.log('GET /sedentary/:id', e)
      return res.sendStatus(500)
    }
  }
)

export default router
