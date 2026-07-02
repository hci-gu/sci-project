import express from 'express'
import imageGeneration, {
  cacheKeyForImageSettings,
  parseImageGenerationSettings,
  settingsLabel,
  SUPPORTED_IMAGE_MODEL_VALUES,
} from '../../adapters/image-generation.js'
import Image from '../../db/models/Image.js'
import {
  getPromptMetricsForUser,
  parseRequestedAt,
  shouldReuseImage,
} from './utils.js'

const router = express.Router()
const imageGenerationLocks = new Map<string, number>()
const IMAGE_POLL_INTERVAL_MS = 1500
const IMAGE_POLL_TIMEOUT_MS = 90_000

const sleep = (ms: number) =>
  new Promise((resolve) => {
    setTimeout(resolve, ms)
  })

const imageBufferFromRow = (data: unknown) =>
  Buffer.isBuffer(data)
    ? data
    : Buffer.from(String(data ?? '').trim(), 'base64')

const mimeTypeFromPrompt = (prompt: string | null | undefined) => {
  const match = prompt?.match(/(?:^|\n)MIME_TYPE:([^\n]+)(?:\n|$)/)
  return match?.[1] ?? 'image/png'
}

const sendImageResponse = (res: any, image: Buffer, mimeType = 'image/png') => {
  res.type(mimeType)
  res.set('Content-Length', String(image.length))
  return res.end(image)
}

const waitForGeneratedImage = async ({
  userId,
  cacheKey,
  timeoutMs = IMAGE_POLL_TIMEOUT_MS,
  intervalMs = IMAGE_POLL_INTERVAL_MS,
}: {
  userId: string
  cacheKey: string
  timeoutMs?: number
  intervalMs?: number
}) => {
  const deadline = Date.now() + timeoutMs

  while (Date.now() <= deadline) {
    const found = await Image.findOneByCacheKey({ userId, cacheKey })
    if (found?.data && shouldReuseImage(found.prompt, cacheKey)) {
      return {
        image: imageBufferFromRow(found.data),
        mimeType: mimeTypeFromPrompt(found.prompt),
      }
    }

    await sleep(intervalMs)
  }

  return null
}

router.get('/:userId/image', async (req, res: any) => {
  const { userId } = req.params
  const requestedAt = parseRequestedAt(req.query.date ?? req.query.at)
  const selectedSettings = parseImageGenerationSettings(
    req.query as Record<string, unknown>
  )

  if (!requestedAt) {
    return res.status(400).json({
      error:
        'Missing or invalid date query parameter. Use an ISO 8601 date-time string.',
    })
  }

  if (!selectedSettings) {
    return res.status(400).json({
      error:
        'Invalid image generation query parameters. Supported model values: ' +
        SUPPORTED_IMAGE_MODEL_VALUES.join(', '),
    })
  }

  const promptMetrics = await getPromptMetricsForUser(userId, requestedAt)
  const cacheKey = cacheKeyForImageSettings(
    promptMetrics.cacheKey,
    selectedSettings
  )
  const promptCacheValue = `CACHE_KEY:${cacheKey}\nMODEL:${settingsLabel(selectedSettings)}\n`
  const generationKey = `${userId}:${cacheKey}`

  const found = await Image.findOneByCacheKey({
    userId,
    cacheKey,
  })
  if (found?.data && shouldReuseImage(found.prompt, cacheKey)) {
    return sendImageResponse(
      res,
      imageBufferFromRow(found.data),
      mimeTypeFromPrompt(found.prompt)
    )
  }

  if (imageGenerationLocks.has(generationKey)) {
    const polledImage = await waitForGeneratedImage({
      userId,
      cacheKey,
    })

    if (polledImage) {
      return sendImageResponse(res, polledImage.image, polledImage.mimeType)
    }

    return res.status(504).json({
      error: 'Timed out waiting for the generated image to be saved.',
    })
  }

  imageGenerationLocks.set(generationKey, Date.now())
  try {
    const prompt = imageGeneration.generatePrompt(promptMetrics)
    const image = await imageGeneration.generateImage(selectedSettings, prompt)

    await Image.save(
      {
        data: image.data,
        prompt: `${promptCacheValue}MIME_TYPE:${image.mimeType}\n${prompt}`,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      userId
    )

    return sendImageResponse(res, image.data, image.mimeType)
  } catch (error) {
    console.error('Error saving image for user', userId, error)
    return res.sendStatus(500)
  } finally {
    imageGenerationLocks.delete(generationKey)
  }
})

export default router
