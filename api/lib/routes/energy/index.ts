import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import { getQuery, GetQuerySchema } from '../validation'
import { energyForPeriod, fillEnergyFromCounts } from './utils'

const router = express.Router()

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params
    const { from, to, activity, watt, group } = req.query

    try {
      const energy = await energyForPeriod({
        id,
        from,
        to,
        activity,
        watt,
        group,
      })

      return res.json(energy)
    } catch (e) {
      console.log('GET /energy/:id', e)
      return res.sendStatus(500)
    }
  }
)

router.get(
  '/:id/fill',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params
    const { from, to } = req.query
    try {
      await fillEnergyFromCounts({
        id,
        from,
        to,
      })
      res.send('OK')
    } catch (e) {
      console.log('GET /energy/:id/fill', e)
      return res.sendStatus(500)
    }
  }
)

export default router
