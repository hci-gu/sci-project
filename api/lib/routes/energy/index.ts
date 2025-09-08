import express from 'express'
import { type ValidatedRequest } from 'express-joi-validation'
import { getQuery, type GetQuerySchema } from '../validation.js'
import { energyForPeriod, fillEnergyFromCounts } from './utils.js'

const router = express.Router()

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res: any) => {
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

router.get('/:id/stats', async (req, res) => {
  const { id } = req.params
})

router.get(
  '/:id/fill',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res: any) => {
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
