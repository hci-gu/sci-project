import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import { getQuery, GetQuerySchema } from '../validation'
import { boutsForPeriod } from './utils'

const router = express.Router()

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params
    const { from, to, group } = req.query

    try {
      const bouts = await boutsForPeriod({
        id,
        from,
        to,
        group,
      })

      return res.json(bouts)
    } catch (e) {
      console.log('GET /bouts/:id', e)
      return res.sendStatus(500)
    }
  }
)

export default router
