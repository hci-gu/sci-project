import express from 'express'
import Position from '../../db/models/Position.js'

const router = express.Router()

router.post('/:id', async (req, res) => {
  const { id } = req.params
  const position = req.body

  console.log('GOT POSITION', position)

  await Position.save(
    {
      ...position,
    },
    id
  )
  console.log('SAVED POSITION', position)

  res.sendStatus(200)
})

export default router
