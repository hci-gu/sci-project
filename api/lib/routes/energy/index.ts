import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import { getQuery, GetQuerySchema } from '../validation'
import { energyForPeriod } from './utils'

const router = express.Router()

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params
    const { from, to, activity, watt, group } = req.query
    console.log('GET /ENERGY/:id', { from, to, activity, watt, group })

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
      console.log('GET /users/:id/energy', e)
      return res.sendStatus(500)
    }
  }
)

export default router
