import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import Journal from '../../db/models/Journal'
import { getQuery, GetQuerySchema } from '../validation'

const router = express.Router()

router.post('/:userId', async (req, res) => {
  const { userId } = req.params

  const response = await Journal.save(
    {
      ...req.body,
      t: new Date(),
    },
    userId
  )

  res.send(response)
})

router.delete('/:userId/:id', async (req, res) => {
  const { id } = req.params

  try {
    await Journal.delete(id)
    res.sendStatus(200)
  } catch (e) {
    res.sendStatus(500)
  }
})

router.patch('/:userId/:id', async (req, res) => {
  const { id } = req.params

  try {
    const updated = await Journal.update(id, req.body)
    res.json(updated)
  } catch (e) {
    res.sendStatus(500)
  }
})

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params
    const { from, to } = req.query

    try {
      const response = await Journal.find({
        userId: id,
        from,
        to,
      })
      res.json(response)
    } catch (e) {
      console.log('GET /journal/:id', e)
      return res.sendStatus(500)
    }
  }
)

export default router
