import { Activity } from '../../../lib/constants'
import {
  getSummaryContext,
  parseRequestedAt,
  promptMetricsFromData,
  shouldReuseImage,
} from '../../../lib/routes/chat/utils'

describe('chat prompt metrics', () => {
  const dayContext = getSummaryContext(new Date('2026-03-26T14:30:00.000Z'))

  test('derives prompt metrics from bouts and journal totals', () => {
    const metrics = promptMetricsFromData({
      bouts: [
        { activity: Activity.sedentary, minutes: 60 },
        { activity: Activity.sedentary, minutes: 30 },
        { activity: Activity.moving, minutes: 45 },
        { activity: Activity.active, minutes: 20 },
        { activity: Activity.weights, minutes: 15 },
      ],
      overallJournalEntries: 6,
      context: dayContext,
    })

    expect(metrics).toEqual({
      minutesSittingStill: 90,
      minutesMoving: 45,
      minutesActive: 35,
      averageSittingStillPeriod: 45,
      overallJournalEntries: 6,
      ...dayContext,
    })
  })

  test('parses a requested ISO timestamp', () => {
    const parsed = parseRequestedAt('2026-03-26T08:15:27.000Z')

    expect(parsed?.toISOString()).toBe('2026-03-26T08:15:00.000Z')
  })

  test('returns null for an invalid requested timestamp', () => {
    expect(parseRequestedAt('not-a-date')).toBeNull()
  })

  test('returns null when the requested timestamp is missing', () => {
    expect(parseRequestedAt(undefined)).toBeNull()
  })

  test('builds a morning context from yesterday', () => {
    const context = getSummaryContext(new Date('2026-03-26T08:15:00.000Z'))

    expect(context.summaryBucket).toBe('morning')
    expect(context.summaryLabel).toBe('yesterday review')
    expect(context.summaryStart.toISOString()).toBe('2026-03-25T00:00:00.000Z')
    expect(context.summaryEnd.toISOString()).toBe('2026-03-25T23:59:59.999Z')
    expect(context.cacheKey).toBe('morning|2026-03-25T00:00:00.000Z|2026-03-25T23:59:59.999Z')
  })

  test('builds a daytime context from today so far', () => {
    const context = getSummaryContext(new Date('2026-03-26T12:45:00.000Z'))

    expect(context.summaryBucket).toBe('day')
    expect(context.summaryLabel).toBe('today so far')
    expect(context.summaryStart.toISOString()).toBe('2026-03-26T00:00:00.000Z')
    expect(context.summaryEnd.toISOString()).toBe('2026-03-26T12:45:00.000Z')
    expect(context.cacheKey).toBe('day|2026-03-26T00:00:00.000Z|2026-03-26T12:45:00.000Z')
  })

  test('builds an evening context for the full day', () => {
    const context = getSummaryContext(new Date('2026-03-26T19:10:00.000Z'))

    expect(context.summaryBucket).toBe('evening')
    expect(context.summaryLabel).toBe('full-day reflection')
    expect(context.summaryStart.toISOString()).toBe('2026-03-26T00:00:00.000Z')
    expect(context.summaryEnd.toISOString()).toBe('2026-03-26T23:59:59.999Z')
    expect(context.cacheKey).toBe('evening|2026-03-26T00:00:00.000Z|2026-03-26T23:59:59.999Z')
  })

  test('reuses a cached image only when the summary key matches', () => {
    const prompt = 'CACHE_KEY:user-1-2026-03-26-day\nPROMPT'

    expect(shouldReuseImage(prompt, 'user-1-2026-03-26-day')).toBe(true)

    expect(
      shouldReuseImage(prompt, 'user-1-2026-03-26-evening')
    ).toBe(false)
    expect(shouldReuseImage(null, dayContext.cacheKey)).toBe(false)
  })
})
