import express from 'express'
import { type ValidatedRequest } from 'express-joi-validation'
import Goal from '../../db/models/Goal.js'
import { getQuery, type GetQuerySchema } from '../validation.js'
import { getGoalInfo } from './utils.js'

const router = express.Router()

router.post('/:userId', async (req, res: any) => {
  const { userId } = req.params
  try {
    const response = await Goal.save(req.body, userId)
    res.send(response)
  } catch (e) {
    console.log(e)
    return res.sendStatus(500)
  }
})

router.delete('/:userId/:id', async (req, res) => {
  const { id } = req.params

  try {
    await Goal.delete(id)
    res.sendStatus(200)
  } catch (e) {
    res.sendStatus(500)
  }
})

router.patch('/:userId/:id', async (req, res) => {
  const { id } = req.params

  try {
    const updated = await Goal.update(id, req.body)
    res.json(updated)
  } catch (e) {
    res.sendStatus(500)
  }
})

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res: any) => {
    const { id } = req.params

    try {
      const goals = await Goal.find({
        userId: id,
      })
      const goalsWithProgress = await Promise.all(
        goals.map(async (g) => {
          const info = await getGoalInfo(id, g)
          return {
            ...g.dataValues,
            ...info,
          }
        })
      )
      res.json(goalsWithProgress)
    } catch (e) {
      console.log('GET /goal/:id', e)
      return res.sendStatus(500)
    }
  }
)

export default router
