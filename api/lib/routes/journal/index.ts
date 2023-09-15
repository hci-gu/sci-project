import express from 'express'
import { ValidatedRequest } from 'express-joi-validation'
import moment from 'moment'
import Journal from '../../db/models/Journal'
import { getQuery, GetQuerySchema } from '../validation'
import { JournalType } from '../../constants'
import { fillMockData, getCurrentPressureUlcers, getCurrentUTI } from './utils'

const router = express.Router()

router.post('/:userId', async (req, res) => {
  const { userId } = req.params
  try {
    const response = await Journal.save(
      {
        ...req.body,
        t: req.body.t ? new Date(req.body.t) : new Date(),
      },
      userId
    )
    res.send(response)
  } catch (e) {
    console.log(e)
    return res.sendStatus(500)
  }
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
    const update = req.body
    if (update.t) {
      update.t = new Date(update.t)
    }
    const updated = await Journal.update(id, update)
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
    const { from, to, type } = req.query

    try {
      const response = await Journal.find(
        {
          userId: id,
          from,
          to,
        },
        type ? { type } : {}
      )
      res.json(response)
    } catch (e) {
      console.log('GET /journal/:id', e)
      return res.sendStatus(500)
    }
  }
)

// router.get('/:id/mock', async (req, res) => {
//   await fillMockData(req.params.id)

//   res.json({
//     message: 'ok',
//   })
// })

router.get(
  '/:id/:type',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res) => {
    const { id, type } = req.params
    const { to } = req.query

    try {
      switch (type) {
        case JournalType.pressureUlcer:
          res.json(await getCurrentPressureUlcers(id, to))
          break
        case JournalType.urinaryTractInfection:
          res.json(await getCurrentUTI(id, to))
          break
        default:
          res.sendStatus(404)
          break
      }
    } catch (e) {
      console.log('GET /journal/:id/:type', e)
      return res.sendStatus(500)
    }
  }
)

export default router
