import express from 'express'
import { type ValidatedRequest } from 'express-joi-validation'
import TelemetryModel from '../../db/models/Telemetry.js'
import { getQuery, type GetQuerySchema } from '../validation.js'

const router = express.Router()

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res: any) => {
    const { id } = req.params
    const { from, to } = req.query

    try {
      const telemetry = await TelemetryModel.find({ userId: id, from, to })
      return res.json(telemetry)
    } catch (e) {
      console.log('GET /telemetry/:id', e)
      return res.sendStatus(500)
    }
  }
)

router.post('/:userId', async (req, res: any) => {
  const { userId } = req.params

  try {
    await TelemetryModel.save(req.body, userId)
  } catch (e) {
    console.log('POST /telemetry/:userId', e)
    return res.sendStatus(400)
  }

  return res.sendStatus(200)
})

export default router
