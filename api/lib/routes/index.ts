import express from 'express'
const router = express.Router()

import userRouter from './users/index.ts'
import energyRouter from './energy/index.ts'
import countsRouter from './counts/index.ts'
import sedentaryRouter from './sedentary/index.ts'
import boutsRouter from './bouts/index.ts'
import positionsRouter from './positions/index.ts'
import journalRouter from './journal/index.ts'
import goalsRouter from './goals/index.ts'

router.get('/ping', (_, res: any) => res.send('pong'))

router.use('/users', userRouter)
router.use('/energy', energyRouter)
router.use('/counts', countsRouter)
router.use('/sedentary', sedentaryRouter)
router.use('/bouts', boutsRouter)
router.use('/positions', positionsRouter)
router.use('/journal', journalRouter)
router.use('/goals', goalsRouter)

export default router
