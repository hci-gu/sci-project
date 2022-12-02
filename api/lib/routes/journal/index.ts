import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import moment from 'moment'
import Journal from '../../db/models/Journal'
import { getQuery, GetQuerySchema } from '../validation'
import { createNoise2D } from 'simplex-noise'

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

const mockBodyPart = (bodyPart: string) => {
  const noise2D = createNoise2D()
  const data = []
  for (let i = 0; i < 100; i++) {
    const value = noise2D(i / 10, 0)
    const normalized = (value + 1) / 2
    data.push({
      id: i,
      t: moment().subtract(i, 'days').toDate(),
      type: 'pain',
      comment: Math.random() <= 0.05 ? 'some comment' : '',
      painLevel: Math.floor(normalized * 10),
      bodyPart,
    })
  }
  return data
}

const mockedData = () => {
  return [
    ...mockBodyPart('scapula-right'),
    ...mockBodyPart('shoulderJoint-right'),
  ]
}

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id } = req.params

    try {
      const response = await Journal.find({
        userId: id,
      })
      // res.json(mockedData())
      res.json(response)
    } catch (e) {
      console.log('GET /journal/:id', e)
      return res.sendStatus(500)
    }
  }
)

export default router
