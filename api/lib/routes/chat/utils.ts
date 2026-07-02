import moment from 'moment'
import type { PromptMetrics } from '../../adapters/openai.js'
import { Activity } from '../../constants.js'
import type { Bout } from '../../db/classes.js'
import BoutModel from '../../db/models/Bout.js'
import JournalModel from '../../db/models/Journal.js'

type SummaryBucket = PromptMetrics['summaryBucket']

const ACTIVE_ACTIVITIES = new Set<Activity>([
  Activity.active,
  Activity.weights,
  Activity.skiErgo,
  Activity.armErgo,
  Activity.rollOutside,
])

type SummaryContext = Pick<
  PromptMetrics,
  | 'referenceDateTime'
  | 'summaryStart'
  | 'summaryEnd'
  | 'summaryDate'
  | 'summaryBucket'
  | 'summaryLabel'
  | 'summaryNarrative'
  | 'cacheKey'
>

const normalizeReferenceTime = (date: Date) => {
  const normalized = new Date(date)
  normalized.setSeconds(0, 0)
  return normalized
}

export const parseRequestedAt = (value: unknown) => {
  if (value == null || value === '' || Array.isArray(value) || typeof value !== 'string') {
    return null
  }

  const parsed = moment(value, moment.ISO_8601, true)
  if (!parsed.isValid()) {
    return null
  }

  return normalizeReferenceTime(parsed.toDate())
}

const buildPromptCacheKey = ({
  userId,
  summaryDate,
  summaryBucket,
}: {
  userId: string
  summaryDate: Date
  summaryBucket: SummaryBucket
}) => `${userId}-${moment.utc(summaryDate).format('YYYY-MM-DD')}-${summaryBucket}`

const summaryLabelForBucket = (bucket: SummaryBucket) => {
  switch (bucket) {
    case 'morning':
      return 'yesterday review'
    case 'day':
      return 'today so far'
    case 'evening':
      return 'full-day reflection'
  }
}

const summaryNarrativeForBucket = (bucket: SummaryBucket) => {
  switch (bucket) {
    case 'morning':
      return 'This is a morning retrospective. Treat the image as a calm look back at yesterday, with closure and reflection.'
    case 'day':
      return 'This is a daytime in-progress snapshot. Make the image feel open-ended, present-tense, and still unfolding.'
    case 'evening':
      return 'This is an evening wrap-up. Make the image feel complete, settled, and reflective of the day as a whole.'
  }
}

export const getSummaryContext = (referenceDateTime: Date): SummaryContext => {
  const reference = moment.utc(referenceDateTime)
  const hour = reference.hour()

  let summaryBucket: SummaryBucket
  let summaryStart: Date
  let summaryEnd: Date
  let summaryDate: Date

  if (hour < 9) {
    summaryBucket = 'morning'
    summaryStart = reference.clone().subtract(1, 'day').startOf('day').toDate()
    summaryEnd = reference.clone().subtract(1, 'day').endOf('day').toDate()
    summaryDate = summaryStart
  } else if (hour <= 18) {
    summaryBucket = 'day'
    summaryStart = reference.clone().startOf('day').toDate()
    summaryEnd = reference.toDate()
    summaryDate = reference.toDate()
  } else {
    summaryBucket = 'evening'
    summaryStart = reference.clone().startOf('day').toDate()
    summaryEnd = reference.clone().endOf('day').toDate()
    summaryDate = reference.toDate()
  }

  return {
    referenceDateTime: reference.toDate(),
    summaryStart,
    summaryEnd,
    summaryDate,
    summaryBucket,
    summaryLabel: summaryLabelForBucket(summaryBucket),
    summaryNarrative: summaryNarrativeForBucket(summaryBucket),
    cacheKey: [
      summaryBucket,
      summaryStart.toISOString(),
      summaryEnd.toISOString(),
    ].join('|'),
  }
}

export const promptMetricsFromData = ({
  bouts,
  overallJournalEntries,
  context,
}: {
  bouts: Pick<Bout, 'activity' | 'minutes'>[]
  overallJournalEntries: number
  context: SummaryContext
}): PromptMetrics => {
  let minutesSittingStill = 0
  let minutesMoving = 0
  let minutesActive = 0

  const sedentaryBoutMinutes: number[] = []

  for (const bout of bouts) {
    const minutes = Math.max(0, Math.round(Number(bout.minutes) || 0))

    if (bout.activity === Activity.sedentary) {
      minutesSittingStill += minutes
      sedentaryBoutMinutes.push(minutes)
      continue
    }

    if (bout.activity === Activity.moving) {
      minutesMoving += minutes
      continue
    }

    if (ACTIVE_ACTIVITIES.has(bout.activity)) {
      minutesActive += minutes
      continue
    }
  }

  const averageSittingStillPeriod =
    sedentaryBoutMinutes.length > 0
      ? Math.round(
          sedentaryBoutMinutes.reduce((sum, minutes) => sum + minutes, 0) /
            sedentaryBoutMinutes.length
        )
      : 0

  return {
    minutesSittingStill,
    minutesMoving,
    minutesActive,
    averageSittingStillPeriod,
    overallJournalEntries: Math.max(0, overallJournalEntries),
    ...context,
  }
}

export const getPromptMetricsForUser = async (
  userId: string,
  referenceDateTime: Date
): Promise<PromptMetrics> => {
  const context = getSummaryContext(referenceDateTime)
  const cacheKey = buildPromptCacheKey({
    userId,
    summaryDate: context.summaryDate,
    summaryBucket: context.summaryBucket,
  })

  const [bouts, journalEntries] = await Promise.all([
    BoutModel.find({
      userId,
      from: context.summaryStart,
      to: context.summaryEnd,
    }),
    JournalModel.find({ userId }),
  ])

  return promptMetricsFromData({
    bouts,
    overallJournalEntries: journalEntries.length,
    context: {
      ...context,
      cacheKey,
    },
  })
}

export const shouldReuseImage = (prompt: string | null | undefined, cacheKey: string) =>
  Boolean(prompt && prompt.startsWith(`CACHE_KEY:${cacheKey}\n`))
