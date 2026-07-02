import express from 'express'
import { type ValidatedRequest } from 'express-joi-validation'
import NotificationEventModel from '../../db/models/NotificationEvent.js'
import { getQuery, type GetQuerySchema } from '../validation.js'

const router = express.Router()

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res: any) => {
    const { id } = req.params
    const { from, to } = req.query

    try {
      const notificationEvents = await NotificationEventModel.find({
        userId: id,
        from,
        to,
      })

      return res.json(notificationEvents)
    } catch (e) {
      console.log('GET /notification-events/:id', e)
      return res.sendStatus(500)
    }
  }
)

export default router
