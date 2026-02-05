import express from 'express'
import { type ValidatedRequest } from 'express-joi-validation'
import { getQuery, type GetQuerySchema } from '../validation.js'
import AccelCountModel from '../../db/models/AccelCount.js'

const router = express.Router()

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res: any) => {
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

router.post('/:id', async (req, res: any) => {
  const { id } = req.params
  const counts = req.body

  try {
    if (!Array.isArray(counts)) {
      return res.sendStatus(400)
    }

    if (counts.length === 0) {
      return res.sendStatus(200)
    }

    const hasInvalidRow = counts.some(
      (c) =>
        !c ||
        !c.t ||
        typeof c.a !== 'number' ||
        Number.isNaN(c.a) ||
        typeof c.hr !== 'number' ||
        Number.isNaN(c.hr)
    )

    if (hasInvalidRow) {
      return res.sendStatus(400)
    }

    // Respond immediately, then process in the background.
    res.sendStatus(200)

    setImmediate(async () => {
      try {
        await AccelCountModel.bulkSave(counts, id)
      } catch (e) {
        console.log('POST /counts/:id async', e)
      }
    })
    return
  } catch (e) {
    console.log('POST /counts/:id', e)
    return res.sendStatus(500)
  }
})

export default router
