import express from 'express'
const router = express.Router()

import userRouter from './users/index.js'
import energyRouter from './energy/index.js'
import countsRouter from './counts/index.js'
import sedentaryRouter from './sedentary/index.js'
import boutsRouter from './bouts/index.js'
import positionsRouter from './positions/index.js'
import journalRouter from './journal/index.js'
import goalsRouter from './goals/index.js'
import chatRouter from './chat/index.js'
import dfuRouter from './dfu/index.js'
import telemetryRouter from './telemetry/index.js'

router.get('/ping', (_, res: any) => res.send('pong'))

router.use('/users', userRouter)
router.use('/energy', energyRouter)
router.use('/counts', countsRouter)
router.use('/sedentary', sedentaryRouter)
router.use('/bouts', boutsRouter)
router.use('/positions', positionsRouter)
router.use('/journal', journalRouter)
router.use('/goals', goalsRouter)
router.use('/chat', chatRouter)
router.use('/dfu', dfuRouter)
router.use('/telemetry', telemetryRouter)

export default router
