import openai, {
  DEFAULT_OPENAI_IMAGE_MODEL,
  DEFAULT_OPENAI_IMAGE_QUALITY,
  type OpenAIImageQuality,
  type PromptMetrics,
} from './openai.js'
import gemini, { type GeminiImageModel } from './gemini.js'

export type GeneratedImage = {
  data: Buffer
  mimeType: string
}

export type OpenAIImageSettings = {
  provider: 'openai'
  model: string
  quality: OpenAIImageQuality
}

export type GeminiImageSettings = {
  provider: 'gemini'
  model: GeminiImageModel
}

export type ImageGenerationSettings = OpenAIImageSettings | GeminiImageSettings

const GEMINI_MODEL_ALIASES: Record<string, GeminiImageModel> = {
  gemini: 'gemini-2.5-flash-image',
  nanobanana: 'gemini-2.5-flash-image',
  'nano-banana': 'gemini-2.5-flash-image',
  'gemini-2.5-flash-image': 'gemini-2.5-flash-image',
  nanobanana2: 'gemini-3.1-flash-image-preview',
  'nano-banana-2': 'gemini-3.1-flash-image-preview',
  'gemini-3.1-flash-image-preview': 'gemini-3.1-flash-image-preview',
}

const OPENAI_PROVIDER_ALIASES = new Set(['openai'])
const OPENAI_MODEL_PREFIXES = ['gpt-image', 'dall-e']
const OPENAI_QUALITIES: OpenAIImageQuality[] = [
  'standard',
  'hd',
  'low',
  'medium',
  'high',
  'auto',
]

export const SUPPORTED_IMAGE_MODEL_VALUES = [
  'openai',
  'gpt-image-1-mini',
  'gemini-2.5-flash-image',
  'gemini-3.1-flash-image-preview',
] as const

const asObjectRecord = (value: unknown): Record<string, unknown> | null =>
  value != null && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null

const firstString = (value: unknown): string | null => {
  if (Array.isArray(value)) {
    return firstString(value[0])
  }

  return typeof value === 'string' && value.trim() !== '' ? value.trim() : null
}

const parseOpenAIQuality = (value: unknown): OpenAIImageQuality | null => {
  const raw = firstString(value)
  if (!raw) return DEFAULT_OPENAI_IMAGE_QUALITY

  const normalized = raw.toLowerCase()
  return OPENAI_QUALITIES.find((quality) => quality === normalized) ?? null
}

const looksLikeOpenAIModel = (value: string) =>
  OPENAI_PROVIDER_ALIASES.has(value) ||
  OPENAI_MODEL_PREFIXES.some((prefix) => value.startsWith(prefix))

const resolveOpenAIModel = (value: string | null) => {
  if (!value) return DEFAULT_OPENAI_IMAGE_MODEL
  return OPENAI_PROVIDER_ALIASES.has(value.toLowerCase())
    ? DEFAULT_OPENAI_IMAGE_MODEL
    : value
}

const defaultSettings = (): OpenAIImageSettings => ({
  provider: 'openai',
  model: DEFAULT_OPENAI_IMAGE_MODEL,
  quality: DEFAULT_OPENAI_IMAGE_QUALITY,
})

const readQueryValue = (query: Record<string, unknown>, ...keys: string[]) => {
  for (const key of keys) {
    const direct = firstString(query[key])
    if (direct) return direct
  }

  const modelSettings = asObjectRecord(query.model)
  if (!modelSettings) return null

  for (const key of keys) {
    const nested = firstString(modelSettings[key])
    if (nested) return nested
  }

  return null
}

export const parseImageGenerationSettings = (
  query: Record<string, unknown>
): ImageGenerationSettings | null => {
  const providerValue = readQueryValue(query, 'provider', 'backend', 'vendor')
  const modelValue = readQueryValue(query, 'imageModel', 'model')
  const qualityValue = parseOpenAIQuality(readQueryValue(query, 'quality'))

  if (qualityValue == null) {
    return null
  }

  const normalizedProvider = providerValue?.toLowerCase() ?? null
  const normalizedModel = modelValue?.toLowerCase() ?? null

  if (!normalizedProvider && !normalizedModel) {
    return defaultSettings()
  }

  if (normalizedProvider === 'gemini') {
    const geminiModel =
      (normalizedModel && GEMINI_MODEL_ALIASES[normalizedModel]) ??
      GEMINI_MODEL_ALIASES.gemini

    return {
      provider: 'gemini',
      model: geminiModel,
    }
  }

  if (normalizedProvider === 'openai') {
    return {
      provider: 'openai',
      model: resolveOpenAIModel(modelValue),
      quality: qualityValue,
    }
  }

  if (normalizedProvider) {
    return null
  }

  if (normalizedModel && GEMINI_MODEL_ALIASES[normalizedModel]) {
    return {
      provider: 'gemini',
      model: GEMINI_MODEL_ALIASES[normalizedModel],
    }
  }

  if (normalizedModel && looksLikeOpenAIModel(normalizedModel)) {
    return {
      provider: 'openai',
      model: resolveOpenAIModel(modelValue),
      quality: qualityValue,
    }
  }

  return null
}

export const cacheKeyForImageSettings = (
  cacheKey: string,
  settings: ImageGenerationSettings
) =>
  settings.provider === 'openai'
    ? `${settings.provider}:${settings.model}:quality=${settings.quality}:${cacheKey}`
    : `${settings.provider}:${settings.model}:${cacheKey}`

export const settingsLabel = (settings: ImageGenerationSettings) =>
  settings.provider === 'openai'
    ? `${settings.provider}:${settings.model}:${settings.quality}`
    : `${settings.provider}:${settings.model}`

export const generatePrompt = (metrics: PromptMetrics) =>
  openai.generatePrompt(metrics)

export const generateImage = async (
  settings: ImageGenerationSettings,
  prompt: string
): Promise<GeneratedImage> => {
  switch (settings.provider) {
    case 'openai':
      return openai.generateImage(prompt, settings.model, settings.quality)
    case 'gemini':
      return gemini.generateImage(settings.model, prompt)
  }

  const exhaustiveCheck: never = settings
  throw new Error(`Unsupported image generation settings: ${exhaustiveCheck}`)
}

export default {
  generateImage,
  generatePrompt,
}
