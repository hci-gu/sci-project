import dotenv from 'dotenv'
import axios from 'axios'

dotenv.config()

export type GeminiImageModel = string

type GeneratedImage = {
  data: Buffer
  mimeType: string
}

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models'
const GEMINI_API_KEY =
  process.env.GEMINI_API_KEY ?? process.env.GOOGLE_API_KEY ?? null
const GEMINI_IMAGE_ASPECT_RATIO = '2:3'
const GEMINI_IMAGE_SIZE = '1K'

const generationConfigForModel = (model: GeminiImageModel) => {
  if (model === 'gemini-3.1-flash-image-preview') {
    return {
      imageConfig: {
        aspectRatio: GEMINI_IMAGE_ASPECT_RATIO,
        imageSize: GEMINI_IMAGE_SIZE,
      },
    }
  }

  return {
    imageConfig: {
      aspectRatio: GEMINI_IMAGE_ASPECT_RATIO,
    },
  }
}

const generateImage = async (
  model: GeminiImageModel,
  prompt: string
): Promise<GeneratedImage> => {
  if (!GEMINI_API_KEY) {
    throw new Error('Missing GEMINI_API_KEY or GOOGLE_API_KEY')
  }

  const response = await axios.post(
    `${GEMINI_API_URL}/${model}:generateContent`,
    {
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
      generationConfig: generationConfigForModel(model),
    },
    {
      headers: {
        'x-goog-api-key': GEMINI_API_KEY,
        'Content-Type': 'application/json',
      },
      timeout: 120_000,
    }
  )

  const parts =
    response.data?.candidates?.flatMap(
      (candidate: any) => candidate?.content?.parts ?? []
    ) ?? []

  const inlineData = parts.find(
    (part: any) => part?.inlineData?.data
  )?.inlineData
  if (!inlineData?.data) {
    throw new Error('No image data returned from Gemini')
  }

  return {
    data: Buffer.from(inlineData.data, 'base64'),
    mimeType: inlineData.mimeType || 'image/png',
  }
}

export default {
  generateImage,
}
