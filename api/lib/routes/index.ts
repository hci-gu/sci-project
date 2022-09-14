import express from 'express'
const router = express.Router()

import userRouter from './users'

router.get('/ping', (_, res) => res.send('pong'))

router.use('/users', userRouter)

export default router
