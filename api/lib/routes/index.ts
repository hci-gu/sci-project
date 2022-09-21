import express from 'express'
const router = express.Router()

import userRouter from './users'
import energyRouter from './energy'
import sedentaryRouter from './sedentary'

router.get('/ping', (_, res) => res.send('pong'))

router.use('/users', userRouter)
router.use('/energy', energyRouter)
router.use('/sedentary', sedentaryRouter)

export default router
