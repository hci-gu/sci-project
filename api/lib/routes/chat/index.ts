import express from 'express'
import openai from '../../adapters/openai.js'
import Image from '../../db/models/Image.js'

const router = express.Router()

router.get('/:userId/image', async (req, res: any) => {
  const { userId } = req.params

  const found = await Image.findOne({ userId })
  if (found?.data) {
    const buf = Buffer.isBuffer(found.data)
      ? found.data
      : Buffer.from(String(found.data).trim(), 'base64')

    res.type('png') // sets Content-Type: image/png
    res.set('Content-Length', String(buf.length))
    return res.end(buf)
  }

  // TODO: here is the part where we read user data and actually generate something based on this.
  const image = await openai.generateImage(openai.generatePrompt(2000))

  try {
    await Image.save(
      { data: image, createdAt: new Date(), updatedAt: new Date() },
      userId
    )
  } catch (error) {
    console.error('Error saving image for user', userId, error)
  }

  res.type('png')
  res.set('Content-Length', String(image.length))
  res.send(image)
})

export default router
