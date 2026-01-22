import express from 'express'
import TelemetryModel from '../../db/models/Telemetry.js'

const router = express.Router()

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
