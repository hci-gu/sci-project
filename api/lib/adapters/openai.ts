import dotenv from 'dotenv'
dotenv.config()
import OpenAI from 'openai'
const openai = new OpenAI()

const IMAGE_MODEL = 'gpt-image-1-mini'
const IMAGE_SIZE = '1024x1536'
const IMAGE_QUALITY = 'low'
const IMAGE_BACKGROUND = 'opaque'
const IMAGE_OUTPUT_FORMAT = 'png'

export type OpenAIImageModel = string
export type OpenAIImageQuality =
  | 'standard'
  | 'hd'
  | 'low'
  | 'medium'
  | 'high'
  | 'auto'

export const DEFAULT_OPENAI_IMAGE_MODEL = IMAGE_MODEL
export const DEFAULT_OPENAI_IMAGE_QUALITY = IMAGE_QUALITY

export type PromptMetrics = {
  minutesSittingStill: number
  minutesMoving: number
  minutesActive: number
  averageSittingStillPeriod: number
  overallJournalEntries: number
  referenceDateTime: Date
  summaryStart: Date
  summaryEnd: Date
  summaryDate: Date
  summaryBucket: 'morning' | 'day' | 'evening'
  summaryLabel: string
  summaryNarrative: string
  cacheKey: string
}

const sanitizeMetric = (value: number) =>
  Number.isFinite(value) ? Math.max(0, Math.round(value)) : 0

const tierForHigherIsBetter = (
  value: number,
  good: number,
  strong: number,
  excellent: number
) => {
  if (value >= excellent) return 3
  if (value >= strong) return 2
  if (value >= good) return 1
  return 0
}

const tierForLowerIsBetter = (
  value: number,
  good: number,
  strong: number,
  excellent: number
) => {
  if (value <= excellent) return 3
  if (value <= strong) return 2
  if (value <= good) return 1
  return 0
}

const clamp = (value: number, min: number, max: number) =>
  Math.min(max, Math.max(min, value))

const dateLabel = (date: Date) =>
  date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })

const weekdayLabel = (date: Date) =>
  date.toLocaleDateString('en-US', { weekday: 'long' }).toUpperCase()

const bucketLabel = (bucket: PromptMetrics['summaryBucket']) => {
  switch (bucket) {
    case 'morning':
      return 'MORNING REFLECTION'
    case 'day':
      return 'DAYTIME SNAPSHOT'
    case 'evening':
      return 'EVENING WRAP'
  }
}

const movementDirection = (tier: number) => {
  switch (tier) {
    case 3:
      return 'Movement is strong. Open the posture, stretch the neck forward, and brighten the golden network with confident continuity.'
    case 2:
      return 'Movement is steady. Keep the stance balanced and let a few warm current lines move through the torso.'
    case 1:
      return 'Movement is present but limited. Keep the pose cautious, with only a restrained sense of forward momentum.'
    default:
      return 'Movement is sparse. Let the pose stay compact and the constellation feel quieter and less connected.'
  }
}

const activeDirection = (tier: number) => {
  switch (tier) {
    case 3:
      return 'Active minutes are high. Add crisp ember-gold accents and sharper facet contrasts that suggest real exertion.'
    case 2:
      return 'Active minutes are meaningful. Include a visible ember-gold pulse near the shoulders and forelimbs.'
    case 1:
      return 'Active minutes are brief. Suggest only one concentrated warm flare to hint at exertion.'
    default:
      return 'Active minutes are minimal. Keep exertion understated and avoid a triumphant or athletic feel.'
  }
}

const stillnessDirection = (tier: number) => {
  switch (tier) {
    case 3:
      return 'Stillness is broken up well. Keep the fog light, the silhouette loose, and the rhythm of the image varied.'
    case 2:
      return 'Stillness is interrupted often enough. Keep the fog moderate and the body language reasonably relaxed.'
    case 1:
      return 'Stillness is only partly broken up. Let some heaviness remain in the torso and background veil.'
    default:
      return 'Long sitting bouts dominate. Thicken the veil, compress the posture slightly, and make the scene feel more static.'
  }
}

const journalDirection = (tier: number) => {
  switch (tier) {
    case 3:
      return 'Journal reporting is consistent. Make the composition feel intentional and clearly narrated, with crisp caption treatment.'
    case 2:
      return 'Journal reporting is solid. Preserve a clear story arc and readable text treatment.'
    case 1:
      return 'Journal reporting is occasional. Keep the narrative hints modest and slightly understated.'
    default:
      return 'Journal reporting is sparse. Leave more ambiguity in the scene and keep the narrative details minimal.'
  }
}

const captionForScore = (score: number) => {
  if (score >= 10) return 'BALANCED RHYTHM'
  if (score >= 7) return 'STEADY PROGRESS'
  if (score >= 4) return 'GENTLE RESET'
  return 'QUIET RECOVERY'
}

const overallMood = (score: number) => {
  if (score >= 10) {
    return 'Overall tone: composed, capable, and quietly triumphant without becoming flashy.'
  }

  if (score >= 7) {
    return 'Overall tone: calm, resilient, and supportive, with visible momentum.'
  }

  if (score >= 4) {
    return 'Overall tone: restorative and encouraging, balancing strain with a sense of potential.'
  }

  return 'Overall tone: subdued and restorative, acknowledging inertia while still leaving room for hope.'
}

const generatePrompt = ({
  minutesSittingStill,
  minutesMoving,
  minutesActive,
  averageSittingStillPeriod,
  overallJournalEntries,
  referenceDateTime,
  summaryStart,
  summaryEnd,
  summaryDate,
  summaryBucket,
  summaryLabel,
  summaryNarrative,
}: PromptMetrics) => {
  const sittingStill = sanitizeMetric(minutesSittingStill)
  const moving = sanitizeMetric(minutesMoving)
  const active = sanitizeMetric(minutesActive)
  const averageStillness = sanitizeMetric(averageSittingStillPeriod)
  const journalEntries = sanitizeMetric(overallJournalEntries)

  const movementTier = tierForHigherIsBetter(moving, 30, 90, 180)
  const activeTier = tierForHigherIsBetter(active, 10, 25, 45)
  const stillnessTier = tierForLowerIsBetter(averageStillness, 60, 40, 20)
  const journalTier = tierForHigherIsBetter(journalEntries, 1, 4, 7)
  const totalScore = movementTier + activeTier + stillnessTier + journalTier

  const bubbleSize = clamp(14 + journalEntries * 2 + movementTier * 4, 18, 42)
  const planktonCount = clamp(4 + activeTier * 4 + movementTier * 2, 4, 22)
  const anemoneBrightness = clamp(28 + moving / 6 + activeTier * 10, 30, 92)
  const fogDensity = clamp(
    50 + sittingStill / 30 - stillnessTier * 8 - movementTier * 3,
    18,
    74
  )

  return `
(${referenceDateTime.toISOString()})
Abstract Cubist Night scene from 'Cycle of Balance' triptych (moose version).
Aspect 3:5, deep-navy.
Flat-vector painterly style with subtle paper-grain texture.
Palette: indigo #1C2436, plum #3D2A3B, ember gold #E4B661,
accent moss #B7C48E, and ivory #F9F4E6.
Lighting soft and low, rim glow along moose silhouette;
facets subdued and cool with faint gold edges.
Background: seven-node constellation network subtly echoing antler geometry,
each node representing one of the last 7 days of recovery rhythm and effort;
connected by faint golden lines, brightest node representing the summary day near moose's head.
Moose in side profile facing right, posture relaxed but emotionally responsive to the behavioural data below,
antlers spreading outward. Front-left hoof resting lightly near a large
translucent moss orb (${bubbleSize}% canvas width).
Body formed by angular shard facets blending into the dark background.
Metrics visuals:
- ${planktonCount} faint gold motes behind left antler;
- eye halo ${anemoneBrightness}% brightness;
- nebula veil overlay at ${fogDensity}% opacity, ~56 px grid.
Behaviour-based art direction:
- Reference timestamp: ${referenceDateTime.toISOString()}.
- Summary window: ${summaryLabel} from ${summaryStart.toISOString()} to ${summaryEnd.toISOString()}.
- Time framing: ${summaryNarrative}
- Sitting still total: ${sittingStill} minutes.
- Moving total: ${moving} minutes.
- Active total: ${active} minutes.
- Average sitting-still period: ${averageStillness} minutes.
- Overall journal entries: ${journalEntries}.
- ${movementDirection(movementTier)}
- ${activeDirection(activeTier)}
- ${stillnessDirection(stillnessTier)}
- ${journalDirection(journalTier)}
- ${overallMood(totalScore)}
Top-left text (ALL CAPS):
'${weekdayLabel(summaryDate)}'
'${dateLabel(summaryDate).toUpperCase()}'
'${bucketLabel(summaryBucket)}'
geometric sans, flush-left.
Bottom-centre caption: '${captionForScore(totalScore)}' Ivory text.
Gentle vignette; 1-2 px light-gold rim-light along antlers and shoulders.
No icons or shadows.
`.trim()
}

const generateImage = async (
  prompt: string,
  model: OpenAIImageModel = IMAGE_MODEL,
  quality: OpenAIImageQuality = IMAGE_QUALITY
) => {
  const response = await openai.images.generate({
    model,
    prompt,
    quality,
    size: IMAGE_SIZE,
    background: IMAGE_BACKGROUND,
    output_format: IMAGE_OUTPUT_FORMAT,
  })

  const base64 = response.data?.[0]?.b64_json
  if (!base64) {
    throw new Error('No image data returned from OpenAI')
  }

  return {
    data: Buffer.from(base64, 'base64'),
    mimeType: 'image/png',
  }
}

export default {
  generateImage,
  generatePrompt,
}
