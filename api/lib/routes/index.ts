import express from 'express'
const router = express.Router()

import userRouter from './users'
import energyRouter from './energy'
import countsRouter from './counts'
import sedentaryRouter from './sedentary'
import boutsRouter from './bouts'
import positionsRouter from './positions'
import journalRouter from './journal'
import goalsRouter from './goals'

router.get('/ping', (_, res) => res.send('pong'))

router.use('/users', userRouter)
router.use('/energy', energyRouter)
router.use('/counts', countsRouter)
router.use('/sedentary', sedentaryRouter)
router.use('/bouts', boutsRouter)
router.use('/positions', positionsRouter)
router.use('/journal', journalRouter)
router.use('/goals', goalsRouter)

export default router
