import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import { getQuery, GetQuerySchema } from '../validation'
import { boutsForPeriod, fillMockData, removeBout, saveBout } from './utils'
import { boutBody, BoutBodySchema } from './validation'

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

router.post(
  '/:id',
  boutBody,
  async (req: ValidatedRequest<BoutBodySchema>, res) => {
    try {
      const bout = await saveBout(req.params.id, req.body)
      res.send(bout)
    } catch (e) {
      console.log('POST /bouts/:id', e)
      return res.sendStatus(500)
    }
  }
)

router.delete('/:userId/:id', async (req, res) => {
  const { userId, id } = req.params

  try {
    await removeBout(userId, id)
    res.sendStatus(200)
  } catch (e) {
    console.log('DELETE /bouts/:userId/:id', e)
    res.sendStatus(500)
  }
})

router.get('/:userId/mock', async (req, res) => {
  const { userId } = req.params

  try {
    await fillMockData(userId)
    res.send({ ok: true })
  } catch (e) {
    console.log('GET /bouts/:userId/mock', e)
    res.sendStatus(500)
  }
})

export default router
