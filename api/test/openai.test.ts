import openai from '../lib/adapters/openai'

const promptContext = {
  referenceDateTime: new Date('2026-03-26T14:30:00.000Z'),
  summaryStart: new Date('2026-03-26T00:00:00.000Z'),
  summaryEnd: new Date('2026-03-26T14:30:00.000Z'),
  summaryDate: new Date('2026-03-26T14:30:00.000Z'),
  summaryBucket: 'day' as const,
  summaryLabel: 'today so far',
  summaryNarrative:
    'This is a daytime in-progress snapshot. Make the image feel open-ended, present-tense, and still unfolding.',
  cacheKey: 'day|2026-03-26T00:00:00.000Z|2026-03-26T14:30:00.000Z',
}

describe('openai.generatePrompt', () => {
  test('includes the provided behaviour metrics in the prompt', () => {
    const prompt = openai.generatePrompt({
      minutesSittingStill: 420,
      minutesMoving: 85,
      minutesActive: 12,
      averageSittingStillPeriod: 55,
      overallJournalEntries: 2,
      ...promptContext,
    })

    expect(prompt).toContain('Reference timestamp: 2026-03-26T14:30:00.000Z.')
    expect(prompt).toContain(
      'Summary window: today so far from 2026-03-26T00:00:00.000Z to 2026-03-26T14:30:00.000Z.'
    )
    expect(prompt).toContain('Sitting still total: 420 minutes.')
    expect(prompt).toContain('Moving total: 85 minutes.')
    expect(prompt).toContain('Active total: 12 minutes.')
    expect(prompt).toContain('Average sitting-still period: 55 minutes.')
    expect(prompt).toContain('Overall journal entries: 2.')
    expect(prompt).toContain('This is a daytime in-progress snapshot.')
    expect(prompt).not.toContain('CACHE_KEY:')
  })

  test('shifts the prompt tone when movement and journaling are strong', () => {
    const prompt = openai.generatePrompt({
      minutesSittingStill: 180,
      minutesMoving: 220,
      minutesActive: 60,
      averageSittingStillPeriod: 18,
      overallJournalEntries: 8,
      ...promptContext,
    })

    expect(prompt).toContain('Movement is strong.')
    expect(prompt).toContain('Active minutes are high.')
    expect(prompt).toContain('Stillness is broken up well.')
    expect(prompt).toContain('Journal reporting is consistent.')
    expect(prompt).toContain("Bottom-centre caption: 'BALANCED RHYTHM'")
  })

  test('shifts the prompt tone when the user has been mostly still', () => {
    const prompt = openai.generatePrompt({
      minutesSittingStill: 720,
      minutesMoving: 5,
      minutesActive: 0,
      averageSittingStillPeriod: 95,
      overallJournalEntries: 0,
      ...promptContext,
    })

    expect(prompt).toContain('Movement is sparse.')
    expect(prompt).toContain('Active minutes are minimal.')
    expect(prompt).toContain('Long sitting bouts dominate.')
    expect(prompt).toContain('Journal reporting is sparse.')
    expect(prompt).toContain("Bottom-centre caption: 'QUIET RECOVERY'")
  })
})
