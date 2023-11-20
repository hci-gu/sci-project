import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import { getQuery, GetQuerySchema } from '../validation'
import AccelCountModel from '../../db/models/AccelCount'
import moment from 'moment'
import { Activity } from '../../constants'

const router = express.Router()

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params
    const { from, to, group } = req.query

    try {
      if (group) {
        const counts = await AccelCountModel.group({
          userId: id,
          from,
          to,
          unit: group,
        })

        return res.json(counts)
      }

      const counts = await AccelCountModel.find({
        userId: id,
        from,
        to,
      })

      return res.json(counts)
    } catch (e) {
      console.log('GET /counts/:id', e)
      return res.sendStatus(500)
    }
  }
)

router.post('/:id', async (req, res) => {
  const { id } = req.params
  const counts = req.body

  try {
    await AccelCountModel.save(counts, id)
    return res.sendStatus(200)
  } catch (e) {
    console.log('POST /counts/:id', e)
    return res.sendStatus(500)
  }
})

export default router
