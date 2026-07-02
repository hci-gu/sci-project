import { type MouseEvent, useEffect, useRef, useState } from 'react'

import actigraphDataSource from './data/actigraph_2026_02_24.json'

const MINUTES_PER_DAY = 1440
const MAX_CALENDAR_DAY_FILL_MINUTES = 12 * 60
const HOURS_PER_IMPACT_WINDOW = 24
const HOURS_PER_IMPACT_SHORT_WINDOW = 6
const MILLISECONDS_PER_HOUR = 60 * 60 * 1000
const RECENT_ACTIVITY_DAYS = 7
const GENERATED_IMAGES_STORAGE_KEY = 'accel-sync-dashboard-generated-images-v1'
const IMAGE_GENERATION_SETTINGS_STORAGE_KEY =
  'accel-sync-dashboard-image-generation-settings-v1'
const IMAGE_BUCKETS: ImageSummaryBucket[] = ['morning', 'day', 'evening']

type CountRow = {
  t: string
  hr: number
  a: number
}

type BoutRow = {
  t: string
  minutes: number
  activity: string
}

type BoutSegment = {
  start: number
  length: number
  activity: string
}

type DashboardView = 'overview' | 'sync' | 'impact' | 'actigraph'

type ActivityBucket = 'sedentary' | 'moving' | 'active' | 'exercise'
type ImageSummaryBucket = 'morning' | 'day' | 'evening'
type DashboardImageModel =
  | 'gpt-image-1-mini'
  | 'gemini-2.5-flash-image'
  | 'gemini-3.1-flash-image-preview'
type DashboardImageQuality = 'low' | 'medium' | 'high'
type DashboardImageGenerationSettings = {
  model: DashboardImageModel
  quality: DashboardImageQuality
}
type StoredGeneratedImageRecord = {
  requestDate: string
  generatedAt: string
}

type MonthlyEnergyRow = {
  t: string
  activity: string
  minutes?: number | string
}

type JournalRow = {
  t: string
  type?: string
}

type NotificationEventRow = {
  timestamp: string
  reason: string
  title: string
  body: string
}

type MonthlyActivityRow = {
  month: string
  sedentary: number
  moving: number
  active: number
  exercise: number
  total: number
  days: Array<{
    date: string
    day: number
    hasData: boolean
    totalMinutes: number
    journalEntries: number
  }>
}

type UserSummaryRow = {
  id: string
  createdAt?: string
}

type UserData = {
  minutes: boolean[]
  minutesWithData: number
  lastDataAt: Date | null
  bouts: BoutSegment[]
  boutMinutesTotal: number
  journalEntries: Array<{ index: number; type: string }>
}

type UserState = {
  loading: boolean
  error: string | null
  data: UserData
}

type UserExportState = UserState & {
  updatedAt: Date | null
}

type UserOverviewData = {
  months: MonthlyActivityRow[]
  createdAt: Date | null
  daysWithDataSinceStart: number
  movementTotal: number
  averageSedentaryPerDayWithData: number
  averageMovementPerDayWithData: number
  averageActivePerDayWithData: number
  focusedMonth: string
}

type UserOverviewState = {
  loading: boolean
  error: string | null
  data: UserOverviewData
  updatedAt: Date | null
}

type ImpactDayRow = {
  date: string
  notifications: number
  journalEntries: number
  respondedNotifications: number
}

type ImpactEventRow = {
  timestamp: Date
  reason: string
  title: string
  body: string
  journalEntriesBefore24h: number
  journalEntriesAfter6h: number
  journalEntriesAfter24h: number
  respondedWithin6h: boolean
  respondedWithin24h: boolean
  targetedResponseWithin24h: boolean | null
  firstJournalAfterHours: number | null
}

type ImpactReasonSummary = {
  reason: string
  total: number
  respondedWithin6h: number
  respondedWithin24h: number
  targetableNotifications: number
  targetedResponseWithin24h: number
  avgBefore24h: number
  avgAfter24h: number
  avgDelta24h: number
}

type UserImpactData = {
  notifications: number
  journalEntries: number
  responseRate6h: number
  responseRate24h: number
  targetableNotifications: number
  targetedResponseRate24h: number | null
  avgBefore24h: number
  avgAfter24h: number
  avgDelta24h: number
  notificationDays: number
  quietDays: number
  avgJournalEntriesOnNotificationDay: number
  avgJournalEntriesOnQuietDay: number
  days: ImpactDayRow[]
  reasons: ImpactReasonSummary[]
  recentEvents: ImpactEventRow[]
}

type UserImpactState = {
  loading: boolean
  error: string | null
  data: UserImpactData
  updatedAt: Date | null
}

type ActigraphMinuteRow = [
  minuteOffset: number,
  recordedSeconds: number,
  avgVmMg: number,
  peakVmMg: number,
]

type ActigraphSecondRow = [
  secondOffset: number,
  recorded: number,
  avgVmMg: number,
  peakVmMg: number,
]

type ActigraphData = {
  metadata: {
    fileName: string
    subjectName: string
    deviceType: string
    serialNumber: string
    firmware: string
    sampleRateHz: number
    scaleCountsPerG: number
    timeZone: string
    startIso: string
    stopIso: string
    durationSeconds: number
    recordedSeconds: number
    packetCountsByType: Record<string, number>
    calibration: Record<string, boolean | number | string>
  }
  overview: {
    averageVmMg: number
    peakVmMg: number
    activeMinutes: number
    gapMinutes: number
  }
  minutes: ActigraphMinuteRow[]
  seconds: ActigraphSecondRow[]
}

type ActigraphComparisonMinute = {
  minuteOffset: number
  timestamp: Date
  recordedSeconds: number
  actigraphAvgVmMg: number
  actigraphPeakVmMg: number
  userCount: number | null
  userHeartRate: number | null
  normalizedActigraph: number
  normalizedUser: number | null
}

type ActigraphComparisonData = {
  userId: string
  matchedMinutes: number
  missingUserMinutes: number
  averageUserCount: number
  peakUserCount: number
  correlation: number | null
  minutes: ActigraphComparisonMinute[]
}

type ActigraphComparisonState = {
  loading: boolean
  error: string | null
  data: ActigraphComparisonData | null
  updatedAt: Date | null
}

type UserDiscoveryState = {
  loading: boolean
  error: string | null
  updatedAt: Date | null
}

const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL ?? '').trim()
const apiKey = (import.meta.env.VITE_API_KEY ?? '').trim()
const configuredUserIds = (import.meta.env.VITE_USER_IDS ?? '')
  .split(',')
  .map((id: string) => id.trim())
  .filter(Boolean)
const actigraphUserId = String(
  import.meta.env.VITE_ACTIGRAPH_USERID ??
    import.meta.env.VITE_ACTIGRAPH_USER_ID ??
    ''
).trim()
const actigraphData = actigraphDataSource as ActigraphData

const startOfDay = (date: Date) => {
  const start = new Date(date)
  start.setHours(0, 0, 0, 0)
  return start
}

const endOfDay = (date: Date) => {
  const end = new Date(date)
  end.setHours(23, 59, 59, 999)
  return end
}

const startOfMonth = (date: Date) => {
  const start = new Date(date)
  start.setDate(1)
  start.setHours(0, 0, 0, 0)
  return start
}

const endOfMonth = (date: Date) => {
  const end = new Date(date.getFullYear(), date.getMonth() + 1, 0)
  end.setHours(23, 59, 59, 999)
  return end
}

const toInputDate = (date: Date) => {
  const year = date.getFullYear()
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  const day = `${date.getDate()}`.padStart(2, '0')
  return `${year}-${month}-${day}`
}

const toInputMonth = (date: Date) => {
  const year = date.getFullYear()
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  return `${year}-${month}`
}

const parseInputDate = (value: string) => {
  const [year, month, day] = value.split('-').map(Number)
  const date = new Date()
  date.setFullYear(year, month - 1, day)
  date.setHours(0, 0, 0, 0)
  return date
}

const toLocalIsoDateTime = (date: Date) => {
  const year = date.getFullYear()
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  const day = `${date.getDate()}`.padStart(2, '0')
  const hours = `${date.getHours()}`.padStart(2, '0')
  const minutes = `${date.getMinutes()}`.padStart(2, '0')
  const seconds = `${date.getSeconds()}`.padStart(2, '0')
  return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}`
}

const DEFAULT_IMAGE_GENERATION_SETTINGS: DashboardImageGenerationSettings = {
  model: 'gpt-image-1-mini',
  quality: 'medium',
}

const IMAGE_MODEL_OPTIONS: Array<{
  label: string
  value: DashboardImageModel
}> = [
  { label: 'GPT Image 1 Mini', value: 'gpt-image-1-mini' },
  { label: 'Gemini 2.5 Flash Image', value: 'gemini-2.5-flash-image' },
  {
    label: 'Gemini 3.1 Flash Image Preview',
    value: 'gemini-3.1-flash-image-preview',
  },
]

const IMAGE_QUALITY_OPTIONS: DashboardImageQuality[] = ['low', 'medium', 'high']

const isDashboardImageModel = (
  value: string
): value is DashboardImageModel =>
  IMAGE_MODEL_OPTIONS.some((option) => option.value === value)

const isDashboardImageQuality = (
  value: string
): value is DashboardImageQuality =>
  IMAGE_QUALITY_OPTIONS.includes(value as DashboardImageQuality)

const imageProviderForModel = (model: DashboardImageModel) =>
  model.startsWith('gemini') ? 'gemini' : 'openai'

const imageSettingsKey = (settings: DashboardImageGenerationSettings) =>
  `${imageProviderForModel(settings.model)}-${settings.model}-${settings.quality}`

const readImageGenerationSettings = (): DashboardImageGenerationSettings => {
  if (typeof window === 'undefined') return DEFAULT_IMAGE_GENERATION_SETTINGS

  try {
    const raw = window.localStorage.getItem(IMAGE_GENERATION_SETTINGS_STORAGE_KEY)
    if (!raw) return DEFAULT_IMAGE_GENERATION_SETTINGS

    const parsed = JSON.parse(raw) as Partial<DashboardImageGenerationSettings>
    if (
      typeof parsed.model === 'string' &&
      isDashboardImageModel(parsed.model) &&
      typeof parsed.quality === 'string' &&
      isDashboardImageQuality(parsed.quality)
    ) {
      return {
        model: parsed.model,
        quality: parsed.quality,
      }
    }
  } catch (_) {
    return DEFAULT_IMAGE_GENERATION_SETTINGS
  }

  return DEFAULT_IMAGE_GENERATION_SETTINGS
}

const writeImageGenerationSettings = (
  settings: DashboardImageGenerationSettings
) => {
  if (typeof window === 'undefined') return
  window.localStorage.setItem(
    IMAGE_GENERATION_SETTINGS_STORAGE_KEY,
    JSON.stringify(settings)
  )
}

const generatedImageRecordKey = (
  userId: string,
  selectedDate: Date,
  bucket: ImageSummaryBucket,
  settings: DashboardImageGenerationSettings
) => `${userId}-${toInputDate(selectedDate)}-${bucket}-${imageSettingsKey(settings)}`

const readGeneratedImageRecords = (): Record<string, StoredGeneratedImageRecord> => {
  if (typeof window === 'undefined') return {}

  try {
    const raw = window.localStorage.getItem(GENERATED_IMAGES_STORAGE_KEY)
    if (!raw) return {}

    const parsed = JSON.parse(raw) as Record<string, StoredGeneratedImageRecord>
    return parsed && typeof parsed === 'object' ? parsed : {}
  } catch (_) {
    return {}
  }
}

const writeGeneratedImageRecords = (
  records: Record<string, StoredGeneratedImageRecord>
) => {
  if (typeof window === 'undefined') return
  window.localStorage.setItem(GENERATED_IMAGES_STORAGE_KEY, JSON.stringify(records))
}

const getGeneratedImageRecord = (
  userId: string,
  selectedDate: Date,
  bucket: ImageSummaryBucket,
  settings: DashboardImageGenerationSettings
) =>
  readGeneratedImageRecords()[
    generatedImageRecordKey(userId, selectedDate, bucket, settings)
  ] ?? null

const setGeneratedImageRecord = (
  userId: string,
  selectedDate: Date,
  bucket: ImageSummaryBucket,
  settings: DashboardImageGenerationSettings,
  record: StoredGeneratedImageRecord
) => {
  const records = readGeneratedImageRecords()
  records[generatedImageRecordKey(userId, selectedDate, bucket, settings)] =
    record
  writeGeneratedImageRecords(records)
}

const addDays = (date: Date, delta: number) => {
  const next = new Date(date)
  next.setDate(next.getDate() + delta)
  return next
}

const imageReferenceDateForBucket = (
  selectedDate: Date,
  bucket: ImageSummaryBucket
) => {
  if (bucket === 'morning') {
    const nextMorning = addDays(startOfDay(selectedDate), 1)
    nextMorning.setHours(8, 0, 0, 0)
    return nextMorning
  }

  const sameDay = startOfDay(selectedDate)
  if (bucket === 'day') {
    sameDay.setHours(12, 0, 0, 0)
    return sameDay
  }

  sameDay.setHours(20, 0, 0, 0)
  return sameDay
}

const addMonths = (date: Date, delta: number) => {
  const next = new Date(date)
  next.setMonth(next.getMonth() + delta)
  return next
}

const parseMonthInput = (value: string, edge: 'start' | 'end') => {
  const [year, month] = value.split('-').map(Number)
  const date = new Date()
  date.setFullYear(year, month - 1, 1)
  return edge === 'start' ? startOfMonth(date) : endOfMonth(date)
}

const dateFromIndex = (base: Date, index: number) =>
  new Date(startOfDay(base).getTime() + index * 60000)

const formatDate = (date: Date) =>
  new Intl.DateTimeFormat('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(date)

const formatTime = (date: Date) =>
  new Intl.DateTimeFormat('en-US', {
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)

const formatMonthLabel = (month: string) => {
  const [year, monthIndex] = month.split('-').map(Number)
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    year: '2-digit',
  }).format(new Date(year, monthIndex - 1, 1))
}

const formatHours = (minutes: number) => `${(minutes / 60).toFixed(1)} h`

const formatDurationFromSeconds = (totalSeconds: number) => {
  const totalMinutes = Math.round(totalSeconds / 60)
  const hours = Math.floor(totalMinutes / 60)
  const minutes = totalMinutes % 60
  if (hours === 0) return `${minutes}m`
  if (minutes === 0) return `${hours}h`
  return `${hours}h ${minutes}m`
}

const formatInteger = (value: number) =>
  new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 }).format(value)

const formatMagnitude = (value: number) => `${formatInteger(value)} mg`

const formatCountValue = (value: number) =>
  new Intl.NumberFormat('en-US', {
    minimumFractionDigits: value >= 100 ? 0 : 1,
    maximumFractionDigits: value >= 100 ? 0 : 1,
  }).format(value)

const formatMonthTitle = (date: Date) =>
  new Intl.DateTimeFormat('en-US', {
    month: 'long',
    year: 'numeric',
  }).format(date)

const formatDateTime = (date: Date) =>
  new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)

const formatDateTimeFull = (date: Date) =>
  new Intl.DateTimeFormat('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)

const monthDateFromKey = (month: string) => {
  const [year, monthIndex] = month.split('-').map(Number)
  return new Date(year, monthIndex - 1, 1)
}

const getMonthKey = (date: Date) => {
  const year = date.getFullYear()
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  return `${year}-${month}`
}

const getDayKey = (date: Date) => toInputDate(date)

const buildDayKeys = (from: Date, to: Date) => {
  const keys: string[] = []
  let cursor = startOfDay(from)
  const end = startOfDay(to)

  while (cursor <= end) {
    keys.push(getDayKey(cursor))
    cursor = addDays(cursor, 1)
  }

  return keys
}

const buildMonthKeys = (from: Date, to: Date) => {
  const keys: string[] = []
  let cursor = startOfMonth(from)
  const lastMonthStart = startOfMonth(to)

  while (cursor <= lastMonthStart) {
    keys.push(getMonthKey(cursor))
    cursor = addMonths(cursor, 1)
  }

  return keys
}

const getCalendarOffset = (month: string) => {
  const firstDay = monthDateFromKey(month)
  return firstDay.getDay()
}

const activityBucketFor = (activity: string): ActivityBucket => {
  switch (activity) {
    case 'sedentary':
      return 'sedentary'
    case 'moving':
      return 'moving'
    case 'active':
      return 'active'
    case 'weights':
    case 'skiErgo':
    case 'armErgo':
    case 'rollOutside':
      return 'exercise'
    default:
      return 'moving'
  }
}

const average = (values: number[]) =>
  values.length > 0
    ? values.reduce((total, value) => total + value, 0) / values.length
    : 0

const formatSigned = (value: number) => {
  const rounded = value.toFixed(2)
  return value > 0 ? `+${rounded}` : rounded
}

const minuteKey = (date: Date) => date.toISOString().slice(0, 16)

const pearsonCorrelation = (pairs: Array<[number, number]>) => {
  if (pairs.length < 2) return null

  const meanLeft = average(pairs.map(([left]) => left))
  const meanRight = average(pairs.map(([, right]) => right))
  const numerator = pairs.reduce(
    (total, [left, right]) =>
      total + (left - meanLeft) * (right - meanRight),
    0
  )
  const leftDenominator = Math.sqrt(
    pairs.reduce(
      (total, [left]) => total + (left - meanLeft) * (left - meanLeft),
      0
    )
  )
  const rightDenominator = Math.sqrt(
    pairs.reduce(
      (total, [, right]) => total + (right - meanRight) * (right - meanRight),
      0
    )
  )

  if (leftDenominator === 0 || rightDenominator === 0) {
    return null
  }

  return numerator / (leftDenominator * rightDenominator)
}

const buildLinePath = (
  points: Array<number | null>,
  chartHeight: number,
  top: number
) => {
  let path = ''
  let started = false

  points.forEach((value, index) => {
    if (value == null) {
      started = false
      return
    }

    const x = index + 0.5
    const y = top + chartHeight - value * chartHeight
    path += started ? ` L ${x} ${y}` : `M ${x} ${y}`
    started = true
  })

  return path
}

const calendarDayFillStrength = (totalMinutes: number) =>
  Math.max(0, Math.min(totalMinutes / MAX_CALENDAR_DAY_FILL_MINUTES, 1))

const formatReasonLabel = (reason: string) => {
  switch (reason) {
    case 'activity':
      return 'Activity reminder'
    case 'data':
      return 'Missing data reminder'
    case 'journal':
      return 'Journal reminder'
    case 'pain-smell':
      return 'Pain / smell reminder'
    case 'uti-status':
      return 'UTI status reminder'
    case 'ab-pressure-release':
      return 'A/B pressure release'
    case 'ab-pressure-release:pressure-ulcer':
      return 'A/B pressure release (ulcer)'
    case 'ab-pain-level':
      return 'A/B pain level'
    case 'goal:pressureRelease':
      return 'Goal reminder: pressure release'
    case 'goal:bladderEmptying':
      return 'Goal reminder: bladder emptying'
    default:
      return reason
  }
}

const targetJournalTypesForReason = (reason: string) => {
  switch (reason) {
    case 'journal':
      return [] as string[]
    case 'pain-smell':
      return ['painLevel', 'neuropathicPain']
    case 'uti-status':
      return ['urinaryTractInfection']
    case 'ab-pressure-release':
    case 'ab-pressure-release:pressure-ulcer':
    case 'goal:pressureRelease':
      return ['pressureRelease']
    case 'ab-pain-level':
      return ['painLevel']
    case 'goal:bladderEmptying':
      return ['bladderEmptying']
    default:
      return null
  }
}

const emptyOverviewData = (): UserOverviewData => ({
  months: [],
  createdAt: null,
  daysWithDataSinceStart: 0,
  movementTotal: 0,
  averageSedentaryPerDayWithData: 0,
  averageMovementPerDayWithData: 0,
  averageActivePerDayWithData: 0,
  focusedMonth: '',
})

const emptyImpactData = (): UserImpactData => ({
  notifications: 0,
  journalEntries: 0,
  responseRate6h: 0,
  responseRate24h: 0,
  targetableNotifications: 0,
  targetedResponseRate24h: null,
  avgBefore24h: 0,
  avgAfter24h: 0,
  avgDelta24h: 0,
  notificationDays: 0,
  quietDays: 0,
  avgJournalEntriesOnNotificationDay: 0,
  avgJournalEntriesOnQuietDay: 0,
  days: [],
  reasons: [],
  recentEvents: [],
})

const requestHeaders = () => {
  const headers: Record<string, string> = {}
  if (apiKey) headers['x-api-key'] = apiKey
  return headers
}

const hasRecentUserActivity = async (userId: string, from: Date, to: Date) => {
  const base = apiBaseUrl.replace(/\/$/, '')
  const headers = requestHeaders()

  const countsUrl = new URL(`${base}/counts/${userId}`)
  countsUrl.searchParams.set('from', from.toISOString())
  countsUrl.searchParams.set('to', to.toISOString())
  countsUrl.searchParams.set('group', 'day')

  const journalUrl = new URL(`${base}/journal/${userId}`)
  journalUrl.searchParams.set('from', from.toISOString())
  journalUrl.searchParams.set('to', to.toISOString())

  const [countsResponse, journalResponse] = await Promise.all([
    fetch(countsUrl.toString(), { headers }),
    fetch(journalUrl.toString(), { headers }),
  ])

  if (!countsResponse.ok) {
    throw new Error(`Counts request failed: ${countsResponse.status}`)
  }

  if (!journalResponse.ok) {
    throw new Error(`Journal request failed: ${journalResponse.status}`)
  }

  const [counts, journalRows] = (await Promise.all([
    countsResponse.json(),
    journalResponse.json(),
  ])) as [CountRow[], JournalRow[]]

  return counts.length > 0 || journalRows.length > 0
}

const fetchRecentActiveUserIds = async () => {
  const base = apiBaseUrl.replace(/\/$/, '')

  if (!base) {
    throw new Error('VITE_API_BASE_URL is not set')
  }

  const usersResponse = await fetch(`${base}/users`, {
    headers: requestHeaders(),
  })

  if (!usersResponse.ok) {
    throw new Error(
      usersResponse.status === 403
        ? 'Users request failed: 403. Set VITE_API_KEY or VITE_USER_IDS.'
        : `Users request failed: ${usersResponse.status}`
    )
  }

  const users = (await usersResponse.json()) as UserSummaryRow[]
  const candidateUserIds = Array.from(
    new Set(
      users
        .map((user) => user.id)
        .filter((id): id is string => typeof id === 'string' && id.length > 0)
    )
  )
  const to = new Date()
  const from = addDays(to, -RECENT_ACTIVITY_DAYS)
  const activeUserIds = new Set<string>()

  await Promise.all(
    candidateUserIds.map(async (userId) => {
      if (await hasRecentUserActivity(userId, from, to)) {
        activeUserIds.add(userId)
      }
    })
  )

  return candidateUserIds.filter((userId) => activeUserIds.has(userId))
}

const emptyUserData = (): UserData => ({
  minutes: Array.from({ length: MINUTES_PER_DAY }, () => false),
  minutesWithData: 0,
  lastDataAt: null,
  bouts: [],
  boutMinutesTotal: 0,
  journalEntries: [],
})

const buildSegments = (minutes: boolean[]) => {
  const segments: Array<{ start: number; length: number }> = []
  let start = -1

  for (let i = 0; i < minutes.length; i += 1) {
    const hasData = minutes[i]
    if (hasData && start === -1) start = i

    const isLast = i === minutes.length - 1
    if ((!hasData || isLast) && start !== -1) {
      const end = hasData && isLast ? i : i - 1
      segments.push({ start, length: end - start + 1 })
      start = -1
    }
  }

  return segments
}

const computeCoverage = (minutes: boolean[]) => {
  const firstIndex = minutes.findIndex(Boolean)
  if (firstIndex === -1) {
    return {
      coverage: 0,
      expectedSpan: 0,
      startIndex: null as number | null,
      endIndex: null as number | null,
      minutesInWindow: 0,
    }
  }

  const lastIndexFromEnd = [...minutes].reverse().findIndex(Boolean)
  const lastIndex =
    lastIndexFromEnd === -1 ? firstIndex : MINUTES_PER_DAY - 1 - lastIndexFromEnd

  const endIndex = lastIndex >= 21 * 60 ? MINUTES_PER_DAY - 1 : lastIndex
  const expectedSpan = Math.max(1, endIndex - firstIndex + 1)
  let minutesInWindow = 0
  for (let i = firstIndex; i <= endIndex; i += 1) {
    if (minutes[i]) minutesInWindow += 1
  }

  const coverage = Math.round((minutesInWindow / expectedSpan) * 100)

  return {
    coverage,
    expectedSpan,
    startIndex: firstIndex,
    endIndex,
    minutesInWindow,
  }
}

const activityClass = (activity: string) => {
  switch (activity) {
    case 'active':
      return 'bout-active'
    case 'moving':
      return 'bout-moving'
    case 'sedentary':
      return 'bout-sedentary'
    case 'sleeping':
      return 'bout-sleeping'
    default:
      return 'bout-other'
  }
}

const JOURNAL_LEGEND_ITEMS = [
  {
    label: 'Pressure release',
    className: 'journal-entry-pressure-release',
  },
  {
    label: 'Pain',
    className: 'journal-entry-pain',
  },
  {
    label: 'Care',
    className: 'journal-entry-care',
  },
  {
    label: 'Activity',
    className: 'journal-entry-activity',
  },
  {
    label: 'Other',
    className: 'journal-entry-other',
  },
] as const

const journalEntryClass = (type: string) => {
  switch (type) {
    case 'pressureRelease':
      return 'journal-entry-pressure-release'
    case 'painLevel':
    case 'neuropathicPain':
      return 'journal-entry-pain'
    case 'urinaryTractInfection':
    case 'bladderEmptying':
    case 'bowelEmptying':
      return 'journal-entry-care'
    case 'exercise':
    case 'selfAssessedPhysicalActivity':
      return 'journal-entry-activity'
    default:
      return 'journal-entry-other'
  }
}

const fetchUserData = async (
  userId: string,
  selectedDate: Date
): Promise<UserData> => {
  const base = apiBaseUrl.replace(/\/$/, '')
  const start = startOfDay(selectedDate)
  const end = endOfDay(selectedDate)

  if (!base) {
    throw new Error('VITE_API_BASE_URL is not set')
  }

  const countsUrl = new URL(`${base}/counts/${userId}`)
  countsUrl.searchParams.set('from', start.toISOString())
  countsUrl.searchParams.set('to', end.toISOString())

  const boutsUrl = new URL(`${base}/bouts/${userId}`)
  boutsUrl.searchParams.set('from', start.toISOString())
  boutsUrl.searchParams.set('to', end.toISOString())

  const journalUrl = new URL(`${base}/journal/${userId}`)
  journalUrl.searchParams.set('from', start.toISOString())
  journalUrl.searchParams.set('to', end.toISOString())

  const headers: Record<string, string> = {}
  Object.assign(headers, requestHeaders())

  const [countsResponse, boutsResponse, journalResponse] = await Promise.all([
    fetch(countsUrl.toString(), { headers }),
    fetch(boutsUrl.toString(), { headers }),
    fetch(journalUrl.toString(), { headers }),
  ])

  if (!countsResponse.ok) {
    throw new Error(`Counts request failed: ${countsResponse.status}`)
  }

  if (!boutsResponse.ok) {
    throw new Error(`Bouts request failed: ${boutsResponse.status}`)
  }

  if (!journalResponse.ok) {
    throw new Error(`Journal request failed: ${journalResponse.status}`)
  }

  const rows = (await countsResponse.json()) as CountRow[]
  const bouts = (await boutsResponse.json()) as BoutRow[]
  const journalRows = (await journalResponse.json()) as JournalRow[]
  const minutes = Array.from({ length: MINUTES_PER_DAY }, () => false)
  let lastDataAt: Date | null = null

  for (const row of rows) {
    const timestamp = new Date(row.t)
    if (Number.isNaN(timestamp.getTime())) continue
    if (timestamp < start || timestamp > end) continue

    const index = Math.floor((timestamp.getTime() - start.getTime()) / 60000)
    if (index < 0 || index >= MINUTES_PER_DAY) continue
    minutes[index] = true

    if (!lastDataAt || timestamp > lastDataAt) {
      lastDataAt = timestamp
    }
  }

  const minutesWithData = minutes.reduce(
    (total, hasData) => total + (hasData ? 1 : 0),
    0
  )

  const boutSegments: BoutSegment[] = []
  let boutMinutesTotal = 0

  for (const bout of bouts) {
    const startTime = new Date(bout.t)
    if (Number.isNaN(startTime.getTime())) continue

    const rawEnd = new Date(startTime.getTime() + bout.minutes * 60000)
    const clampedStart = startTime < start ? start : startTime
    const clampedEnd = rawEnd > end ? end : rawEnd
    if (clampedEnd <= clampedStart) continue

    const startIndex = Math.max(
      0,
      Math.floor((clampedStart.getTime() - start.getTime()) / 60000)
    )
    const endIndex = Math.min(
      MINUTES_PER_DAY - 1,
      Math.ceil((clampedEnd.getTime() - start.getTime()) / 60000) - 1
    )
    const length = Math.max(1, endIndex - startIndex + 1)

    boutSegments.push({
      start: startIndex,
      length,
      activity: bout.activity,
    })
    boutMinutesTotal += length
  }

  const journalEntries: Array<{ index: number; type: string }> = []
  for (const row of journalRows) {
    const timestamp = new Date(row.t)
    if (Number.isNaN(timestamp.getTime())) continue
    if (timestamp < start || timestamp > end) continue
    const index = Math.floor((timestamp.getTime() - start.getTime()) / 60000)
    if (index < 0 || index >= MINUTES_PER_DAY) continue
    journalEntries.push({ index, type: row.type ?? 'other' })
  }

  return {
    minutes,
    minutesWithData,
    lastDataAt,
    bouts: boutSegments,
    boutMinutesTotal,
    journalEntries: journalEntries.sort((a, b) => a.index - b.index),
  }
}

const fetchGeneratedImage = async (
  userId: string,
  selectedDate: Date,
  bucket: ImageSummaryBucket,
  settings: DashboardImageGenerationSettings
) => {
  const requestDate = toLocalIsoDateTime(
    imageReferenceDateForBucket(selectedDate, bucket)
  )
  return fetchGeneratedImageForRequest(userId, requestDate, settings)
}

const fetchGeneratedImageForRequest = async (
  userId: string,
  requestDate: string,
  settings: DashboardImageGenerationSettings
) => {
  const base = apiBaseUrl.replace(/\/$/, '')
  if (!base) {
    throw new Error('VITE_API_BASE_URL is not set')
  }

  const imageUrl = new URL(`${base}/chat/${userId}/image`)
  imageUrl.searchParams.set('date', requestDate)
  imageUrl.searchParams.set('provider', imageProviderForModel(settings.model))
  imageUrl.searchParams.set('model', settings.model)
  if (imageProviderForModel(settings.model) === 'openai') {
    imageUrl.searchParams.set('quality', settings.quality)
  }

  const response = await fetch(imageUrl.toString(), {
    headers: {
      Accept: 'image/*,application/octet-stream,application/json,text/plain',
      ...requestHeaders(),
    },
  })

  if (!response.ok) {
    const body = await response.text().catch(() => '')
    throw new Error(
      `Image request failed: ${response.status}${body ? ` ${body}` : ''}`
    )
  }

  return response.blob()
}

const fetchActigraphComparisonData = async (
  userId: string
): Promise<ActigraphComparisonData> => {
  const base = apiBaseUrl.replace(/\/$/, '')

  if (!userId) {
    throw new Error('Set VITE_ACTIGRAPH_USERID in .env to compare against a user')
  }

  if (!base) {
    throw new Error('VITE_API_BASE_URL is not set')
  }

  const recordingStart = new Date(actigraphData.metadata.startIso)
  const dayStart = startOfDay(recordingStart)
  const dayEnd = endOfDay(recordingStart)
  const countsUrl = new URL(`${base}/counts/${userId}`)
  countsUrl.searchParams.set('from', dayStart.toISOString())
  countsUrl.searchParams.set('to', dayEnd.toISOString())

  const response = await fetch(countsUrl.toString(), {
    headers: requestHeaders(),
  })

  if (!response.ok) {
    throw new Error(`Counts request failed: ${response.status}`)
  }

  const rows = (await response.json()) as CountRow[]
  const minuteBuckets = new Map<
    string,
    { totalCount: number; totalHeartRate: number; heartRateSamples: number; samples: number }
  >()

  for (const row of rows) {
    const timestamp = new Date(row.t)
    const countValue = Number(row.a)
    const heartRateValue = Number(row.hr)

    if (Number.isNaN(timestamp.getTime()) || !Number.isFinite(countValue)) {
      continue
    }

    const key = minuteKey(timestamp)
    const bucket = minuteBuckets.get(key) ?? {
      totalCount: 0,
      totalHeartRate: 0,
      heartRateSamples: 0,
      samples: 0,
    }
    bucket.totalCount += countValue
    bucket.samples += 1
    if (Number.isFinite(heartRateValue) && heartRateValue > 0) {
      bucket.totalHeartRate += heartRateValue
      bucket.heartRateSamples += 1
    }
    minuteBuckets.set(key, bucket)
  }

  const countByMinute = new Map<string, { a: number; hr: number | null }>(
    Array.from(minuteBuckets.entries()).map(([key, bucket]) => [
      key,
      {
        a: bucket.totalCount / Math.max(bucket.samples, 1),
        hr:
          bucket.heartRateSamples > 0
            ? bucket.totalHeartRate / bucket.heartRateSamples
            : null,
      },
    ])
  )

  const rawMinutes = actigraphData.minutes.map(
    ([minuteOffset, recordedSeconds, actigraphAvgVmMg, actigraphPeakVmMg]) => {
      const timestamp = new Date(recordingStart.getTime() + minuteOffset * 60000)
      const alignedCount = countByMinute.get(minuteKey(timestamp))

      return {
        minuteOffset,
        timestamp,
        recordedSeconds,
        actigraphAvgVmMg,
        actigraphPeakVmMg,
        userCount: alignedCount?.a ?? null,
        userHeartRate: alignedCount?.hr ?? null,
      }
    }
  )

  const maxActigraphValue = Math.max(
    ...rawMinutes.map((row) => row.actigraphAvgVmMg),
    1
  )
  const maxUserCount = Math.max(
    ...rawMinutes.map((row) => row.userCount ?? 0),
    1
  )
  const minutes = rawMinutes.map((row) => ({
    ...row,
    normalizedActigraph: row.actigraphAvgVmMg / maxActigraphValue,
    normalizedUser:
      row.userCount == null ? null : Math.max(0, row.userCount) / maxUserCount,
  }))
  const matchedMinutes = minutes.filter((row) => row.userCount != null)
  const correlation = pearsonCorrelation(
    matchedMinutes.map((row) => [row.actigraphAvgVmMg, row.userCount ?? 0])
  )

  return {
    userId,
    matchedMinutes: matchedMinutes.length,
    missingUserMinutes: minutes.length - matchedMinutes.length,
    averageUserCount:
      matchedMinutes.length > 0
        ? average(matchedMinutes.map((row) => row.userCount ?? 0))
        : 0,
    peakUserCount: Math.max(...matchedMinutes.map((row) => row.userCount ?? 0), 0),
    correlation,
    minutes,
  }
}

const fetchOverviewData = async (
  userId: string,
  rangeStart: Date,
  rangeEnd: Date,
  focusedMonthDate: Date
): Promise<UserOverviewData> => {
  const base = apiBaseUrl.replace(/\/$/, '')

  if (!base) {
    throw new Error('VITE_API_BASE_URL is not set')
  }

  const userUrl = new URL(`${base}/users/${userId}`)

  const userResponse = await fetch(userUrl.toString(), {
    headers: requestHeaders(),
  })

  if (!userResponse.ok) {
    throw new Error(`User request failed: ${userResponse.status}`)
  }

  const user = (await userResponse.json()) as UserSummaryRow
  const parsedCreatedAt = user.createdAt ? new Date(user.createdAt) : null
  const createdAt =
    parsedCreatedAt && !Number.isNaN(parsedCreatedAt.getTime())
      ? parsedCreatedAt
      : null
  const summaryStart = createdAt ? startOfDay(createdAt) : startOfMonth(rangeStart)
  const summaryEnd = endOfMonth(rangeEnd)

  const energyUrl = new URL(`${base}/energy/${userId}`)
  energyUrl.searchParams.set('from', summaryStart.toISOString())
  energyUrl.searchParams.set('to', summaryEnd.toISOString())
  energyUrl.searchParams.set('group', 'day')

  const journalUrl = new URL(`${base}/journal/${userId}`)
  journalUrl.searchParams.set('from', startOfMonth(rangeStart).toISOString())
  journalUrl.searchParams.set('to', endOfMonth(rangeEnd).toISOString())

  const [response, journalResponse] = await Promise.all([
    fetch(energyUrl.toString(), {
      headers: requestHeaders(),
    }),
    fetch(journalUrl.toString(), {
      headers: requestHeaders(),
    }),
  ])

  if (!response.ok) {
    throw new Error(`Daily activity request failed: ${response.status}`)
  }

  if (!journalResponse.ok) {
    throw new Error(`Journal request failed: ${journalResponse.status}`)
  }

  const rows = (await response.json()) as MonthlyEnergyRow[]
  const journalRows = (await journalResponse.json()) as JournalRow[]
  const monthKeys = buildMonthKeys(rangeStart, rangeEnd)
  const months = monthKeys.map<MonthlyActivityRow>((month) => ({
    month,
    sedentary: 0,
    moving: 0,
    active: 0,
    exercise: 0,
    total: 0,
    days: Array.from(
      { length: endOfMonth(monthDateFromKey(month)).getDate() },
      (_, index) => ({
        date: `${month}-${`${index + 1}`.padStart(2, '0')}`,
        day: index + 1,
        hasData: false,
        totalMinutes: 0,
        journalEntries: 0,
      })
    ),
  }))
  const monthMap = new Map(months.map((month) => [month.month, month]))
  const daysWithDataMap = new Map<
    string,
    {
      sedentary: number
      moving: number
      active: number
      exercise: number
      total: number
    }
  >()

  for (const row of rows) {
    const bucket = activityBucketFor(row.activity)
    const minutes = Number(row.minutes ?? 0)
    if (!Number.isFinite(minutes) || minutes <= 0) continue

    const timestamp = new Date(row.t)
    const dayKey = getDayKey(timestamp)
    const daySummary = daysWithDataMap.get(dayKey) ?? {
      sedentary: 0,
      moving: 0,
      active: 0,
      exercise: 0,
      total: 0,
    }

    daySummary[bucket] += minutes
    daySummary.total += minutes
    daysWithDataMap.set(dayKey, daySummary)

    if (timestamp < startOfMonth(rangeStart) || timestamp > endOfMonth(rangeEnd)) {
      continue
    }

    const monthKey = getMonthKey(timestamp)
    const month = monthMap.get(monthKey)
    if (!month) continue

    month[bucket] += minutes
    month.total += minutes

    const dayIndex = timestamp.getDate() - 1
    const day = month.days[dayIndex]
    if (day) {
      day.hasData = true
      day.totalMinutes += minutes
    }
  }

  for (const row of journalRows) {
    const timestamp = new Date(row.t)
    const monthKey = getMonthKey(timestamp)
    const month = monthMap.get(monthKey)
    if (!month) continue

    const dayIndex = timestamp.getDate() - 1
    const day = month.days[dayIndex]
    if (day) {
      day.journalEntries += 1
    }
  }

  const totals = Array.from(daysWithDataMap.values()).reduce(
    (acc, day) => {
      acc.sedentary += day.sedentary
      acc.moving += day.moving
      acc.active += day.active
      acc.exercise += day.exercise
      acc.total += day.total
      return acc
    },
    {
      sedentary: 0,
      moving: 0,
      active: 0,
      exercise: 0,
      total: 0,
    }
  )

  const movementTotal = totals.moving + totals.active + totals.exercise
  const daysWithDataSinceStart = Array.from(daysWithDataMap.values()).filter(
    (day) => day.total > 0
  ).length

  return {
    months,
    createdAt,
    daysWithDataSinceStart,
    movementTotal,
    averageSedentaryPerDayWithData:
      daysWithDataSinceStart > 0 ? totals.sedentary / daysWithDataSinceStart : 0,
    averageMovementPerDayWithData:
      daysWithDataSinceStart > 0 ? totals.moving / daysWithDataSinceStart : 0,
    averageActivePerDayWithData:
      daysWithDataSinceStart > 0
        ? (totals.active + totals.exercise) / daysWithDataSinceStart
        : 0,
    focusedMonth: getMonthKey(focusedMonthDate),
  }
}

const fetchImpactData = async (
  userId: string,
  rangeStart: Date,
  rangeEnd: Date
): Promise<UserImpactData> => {
  const base = apiBaseUrl.replace(/\/$/, '')

  if (!base) {
    throw new Error('VITE_API_BASE_URL is not set')
  }

  const start = startOfDay(rangeStart)
  const end = endOfDay(rangeEnd)
  const journalUrl = new URL(`${base}/journal/${userId}`)
  journalUrl.searchParams.set('from', start.toISOString())
  journalUrl.searchParams.set('to', end.toISOString())

  const notificationUrl = new URL(`${base}/notification-events/${userId}`)
  notificationUrl.searchParams.set('from', start.toISOString())
  notificationUrl.searchParams.set('to', end.toISOString())

  const [journalResponse, notificationResponse] = await Promise.all([
    fetch(journalUrl.toString(), {
      headers: requestHeaders(),
    }),
    fetch(notificationUrl.toString(), {
      headers: requestHeaders(),
    }),
  ])

  if (!journalResponse.ok) {
    throw new Error(`Journal request failed: ${journalResponse.status}`)
  }

  if (!notificationResponse.ok) {
    throw new Error(
      `Notification events request failed: ${notificationResponse.status}`
    )
  }

  const journalRows = (await journalResponse.json()) as JournalRow[]
  const notificationRows =
    (await notificationResponse.json()) as NotificationEventRow[]

  const dayMap = new Map(
    buildDayKeys(start, end).map((date) => [
      date,
      {
        date,
        notifications: 0,
        journalEntries: 0,
        respondedNotifications: 0,
      } satisfies ImpactDayRow,
    ])
  )

  const journalEntries = journalRows
    .map((row) => ({
      timestamp: new Date(row.t),
      type: row.type ?? '',
    }))
    .filter((row) => !Number.isNaN(row.timestamp.getTime()))
    .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime())

  for (const journal of journalEntries) {
    const day = dayMap.get(getDayKey(journal.timestamp))
    if (day) {
      day.journalEntries += 1
    }
  }

  const notificationEvents = notificationRows
    .map((row) => ({
      timestamp: new Date(row.timestamp),
      reason: row.reason,
      title: row.title,
      body: row.body,
    }))
    .filter((row) => !Number.isNaN(row.timestamp.getTime()))
    .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime())

  const recentEvents: ImpactEventRow[] = []

  for (const notification of notificationEvents) {
    const notificationMs = notification.timestamp.getTime()
    const beforeStartMs =
      notificationMs - HOURS_PER_IMPACT_WINDOW * MILLISECONDS_PER_HOUR
    const shortAfterEndMs =
      notificationMs + HOURS_PER_IMPACT_SHORT_WINDOW * MILLISECONDS_PER_HOUR
    const afterEndMs =
      notificationMs + HOURS_PER_IMPACT_WINDOW * MILLISECONDS_PER_HOUR
    const targetTypes = targetJournalTypesForReason(notification.reason)

    let journalEntriesBefore24h = 0
    let journalEntriesAfter6h = 0
    let journalEntriesAfter24h = 0
    let firstJournalAfterHours: number | null = null
    let targetedResponseWithin24h = targetTypes === null ? null : false

    for (const journal of journalEntries) {
      const journalMs = journal.timestamp.getTime()

      if (journalMs >= beforeStartMs && journalMs < notificationMs) {
        journalEntriesBefore24h += 1
      }

      if (journalMs > notificationMs && journalMs <= afterEndMs) {
        journalEntriesAfter24h += 1

        if (firstJournalAfterHours == null) {
          firstJournalAfterHours =
            (journalMs - notificationMs) / MILLISECONDS_PER_HOUR
        }

        if (journalMs <= shortAfterEndMs) {
          journalEntriesAfter6h += 1
        }

        if (targetTypes) {
          if (
            targetTypes.length === 0 ||
            targetTypes.includes(journal.type)
          ) {
            targetedResponseWithin24h = true
          }
        }
      }
    }

    const event: ImpactEventRow = {
      timestamp: notification.timestamp,
      reason: notification.reason,
      title: notification.title,
      body: notification.body,
      journalEntriesBefore24h,
      journalEntriesAfter6h,
      journalEntriesAfter24h,
      respondedWithin6h: journalEntriesAfter6h > 0,
      respondedWithin24h: journalEntriesAfter24h > 0,
      targetedResponseWithin24h,
      firstJournalAfterHours,
    }

    recentEvents.push(event)

    const day = dayMap.get(getDayKey(notification.timestamp))
    if (day) {
      day.notifications += 1
      if (event.respondedWithin24h) {
        day.respondedNotifications += 1
      }
    }
  }

  const reasonMap = new Map<
    string,
    {
      total: number
      respondedWithin6h: number
      respondedWithin24h: number
      targetableNotifications: number
      targetedResponseWithin24h: number
      beforeValues: number[]
      afterValues: number[]
    }
  >()

  for (const event of recentEvents) {
    const existing = reasonMap.get(event.reason) ?? {
      total: 0,
      respondedWithin6h: 0,
      respondedWithin24h: 0,
      targetableNotifications: 0,
      targetedResponseWithin24h: 0,
      beforeValues: [],
      afterValues: [],
    }

    existing.total += 1
    existing.respondedWithin6h += event.respondedWithin6h ? 1 : 0
    existing.respondedWithin24h += event.respondedWithin24h ? 1 : 0
    existing.beforeValues.push(event.journalEntriesBefore24h)
    existing.afterValues.push(event.journalEntriesAfter24h)

    if (event.targetedResponseWithin24h != null) {
      existing.targetableNotifications += 1
      existing.targetedResponseWithin24h += event.targetedResponseWithin24h
        ? 1
        : 0
    }

    reasonMap.set(event.reason, existing)
  }

  const reasons = Array.from(reasonMap.entries())
    .map<ImpactReasonSummary>(([reason, data]) => {
      const avgBefore24h = average(data.beforeValues)
      const avgAfter24h = average(data.afterValues)

      return {
        reason,
        total: data.total,
        respondedWithin6h: data.respondedWithin6h,
        respondedWithin24h: data.respondedWithin24h,
        targetableNotifications: data.targetableNotifications,
        targetedResponseWithin24h: data.targetedResponseWithin24h,
        avgBefore24h,
        avgAfter24h,
        avgDelta24h: avgAfter24h - avgBefore24h,
      }
    })
    .sort(
      (a, b) =>
        b.total - a.total || b.avgDelta24h - a.avgDelta24h || a.reason.localeCompare(b.reason)
    )

  const days = Array.from(dayMap.values())
  const notificationDays = days.filter((day) => day.notifications > 0)
  const quietDays = days.filter((day) => day.notifications === 0)
  const targetableNotifications = recentEvents.filter(
    (event) => event.targetedResponseWithin24h != null
  ).length
  const targetedResponseWithin24h = recentEvents.filter(
    (event) => event.targetedResponseWithin24h === true
  ).length
  const avgBefore24h = average(
    recentEvents.map((event) => event.journalEntriesBefore24h)
  )
  const avgAfter24h = average(
    recentEvents.map((event) => event.journalEntriesAfter24h)
  )

  return {
    notifications: recentEvents.length,
    journalEntries: journalEntries.length,
    responseRate6h:
      recentEvents.length > 0
        ? Math.round(
            (recentEvents.filter((event) => event.respondedWithin6h).length /
              recentEvents.length) *
              100
          )
        : 0,
    responseRate24h:
      recentEvents.length > 0
        ? Math.round(
            (recentEvents.filter((event) => event.respondedWithin24h).length /
              recentEvents.length) *
              100
          )
        : 0,
    targetableNotifications,
    targetedResponseRate24h:
      targetableNotifications > 0
        ? Math.round((targetedResponseWithin24h / targetableNotifications) * 100)
        : null,
    avgBefore24h,
    avgAfter24h,
    avgDelta24h: avgAfter24h - avgBefore24h,
    notificationDays: notificationDays.length,
    quietDays: quietDays.length,
    avgJournalEntriesOnNotificationDay:
      notificationDays.length > 0
        ? average(notificationDays.map((day) => day.journalEntries))
        : 0,
    avgJournalEntriesOnQuietDay:
      quietDays.length > 0
        ? average(quietDays.map((day) => day.journalEntries))
        : 0,
    days,
    reasons,
    recentEvents: [...recentEvents]
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
      .slice(0, 10),
  }
}

const SyncDetailCard = ({
  userId,
  refreshToken,
  selectedDate,
  timezone,
  className,
  onClose,
  showImageActions = false,
  imageGenerationSettings = DEFAULT_IMAGE_GENERATION_SETTINGS,
}: {
  userId: string
  refreshToken: number
  selectedDate: Date
  timezone: string
  className?: string
  onClose?: () => void
  showImageActions?: boolean
  imageGenerationSettings?: DashboardImageGenerationSettings
}) => {
  const [state, setState] = useState<UserExportState>({
    loading: true,
    error: null,
    data: emptyUserData(),
    updatedAt: null,
  })
  const [imageRequestState, setImageRequestState] = useState<{
    loadingBucket: ImageSummaryBucket | null
    error: string | null
  }>({
    loadingBucket: null,
    error: null,
  })
  const [generatedImageRecords, setGeneratedImageRecords] = useState<
    Partial<Record<ImageSummaryBucket, StoredGeneratedImageRecord>>
  >({})
  const [generatedImagePreviews, setGeneratedImagePreviews] = useState<
    Partial<
      Record<
        ImageSummaryBucket,
        {
          loading: boolean
          src: string | null
          error: string | null
        }
      >
    >
  >({})
  const previewUrlsRef = useRef<Partial<Record<ImageSummaryBucket, string>>>({})

  useEffect(() => {
    let active = true

    const load = async () => {
      const loadingState = {
        loading: true,
        error: null,
        data: emptyUserData(),
        updatedAt: new Date(),
      }
      setState(loadingState)
      try {
        const data = await fetchUserData(userId, selectedDate)
        if (!active) return
        const nextState = {
          loading: false,
          error: null,
          data,
          updatedAt: new Date(),
        }
        setState(nextState)
      } catch (error) {
        if (!active) return
        const message =
          error instanceof Error ? error.message : 'Unknown error'
        const nextState = {
          loading: false,
          error: message,
          data: emptyUserData(),
          updatedAt: new Date(),
        }
        setState(nextState)
      }
    }

    load()

    return () => {
      active = false
    }
  }, [userId, refreshToken, selectedDate])

  useEffect(() => {
    return () => {
      Object.values(previewUrlsRef.current).forEach((url) => {
        if (url) URL.revokeObjectURL(url)
      })
      previewUrlsRef.current = {}
    }
  }, [])

  useEffect(() => {
    Object.values(previewUrlsRef.current).forEach((url) => {
      if (url) URL.revokeObjectURL(url)
    })
    previewUrlsRef.current = {}

    const nextRecords = Object.fromEntries(
      IMAGE_BUCKETS.map((bucket) => {
        const record = getGeneratedImageRecord(
          userId,
          selectedDate,
          bucket,
          imageGenerationSettings
        )
        return [bucket, record]
      }).filter(([, record]) => record != null)
    ) as Partial<Record<ImageSummaryBucket, StoredGeneratedImageRecord>>

    setGeneratedImageRecords(nextRecords)
    setGeneratedImagePreviews(
      Object.fromEntries(
        IMAGE_BUCKETS.filter((bucket) => nextRecords[bucket] != null).map(
          (bucket) => [
            bucket,
            {
              loading: true,
              src: null,
              error: null,
            },
          ]
        )
      ) as Partial<
        Record<
          ImageSummaryBucket,
          {
            loading: boolean
            src: string | null
            error: string | null
          }
        >
      >
    )

    let active = true

    void Promise.all(
      IMAGE_BUCKETS.filter((bucket) => nextRecords[bucket] != null).map(
        async (bucket) => {
          const record = nextRecords[bucket]
          if (!record) return

          try {
            const imageBlob = await fetchGeneratedImageForRequest(
              userId,
              record.requestDate,
              imageGenerationSettings
            )
            if (!active) return

            const imageUrl = URL.createObjectURL(imageBlob)
            previewUrlsRef.current[bucket] = imageUrl
            setGeneratedImagePreviews((current) => ({
              ...current,
              [bucket]: {
                loading: false,
                src: imageUrl,
                error: null,
              },
            }))
          } catch (error) {
            if (!active) return

            setGeneratedImagePreviews((current) => ({
              ...current,
              [bucket]: {
                loading: false,
                src: null,
                error:
                  error instanceof Error
                    ? error.message
                    : 'Failed to load generated image',
              },
            }))
          }
        }
      )
    )

    return () => {
      active = false
      Object.values(previewUrlsRef.current).forEach((url) => {
        if (url) URL.revokeObjectURL(url)
      })
      previewUrlsRef.current = {}
    }
  }, [imageGenerationSettings, selectedDate, userId])

  const coverage = Math.round(
    (state.data.minutesWithData / MINUTES_PER_DAY) * 100
  )
  const hourMarkers = Array.from({ length: 25 }, (_, hour) => hour)
  const isSelectedToday = toInputDate(selectedDate) === toInputDate(new Date())
  const currentMinuteIndex = isSelectedToday
    ? new Date().getHours() * 60 + new Date().getMinutes()
    : null
  const coverageWindow = computeCoverage(state.data.minutes)
  const coverageValue =
    coverageWindow.expectedSpan > 0 ? coverageWindow.coverage : coverage
  const segments = buildSegments(state.data.minutes)
  const journalEntries = state.data.journalEntries

  const handleExportUser = () => {
    const dateLabel = toInputDate(selectedDate)
    const lines: string[] = []
    lines.push('Accel Sync Report')
    lines.push(`Date: ${dateLabel}`)
    lines.push(`Timezone: ${timezone}`)
    lines.push('')
    lines.push(`User: ${userId}`)

    if (state.loading) {
      lines.push('Status: loading')
    } else if (state.error) {
      lines.push(`Status: error (${state.error})`)
    } else {
      if (
        coverageWindow.startIndex == null ||
        coverageWindow.endIndex == null ||
        coverageWindow.expectedSpan === 0
      ) {
        lines.push(`Coverage: ${coverageValue}% (no data window)`)
      } else {
        const windowStart = formatTime(
          dateFromIndex(selectedDate, coverageWindow.startIndex)
        )
        const windowEnd = formatTime(
          dateFromIndex(selectedDate, coverageWindow.endIndex)
        )
        lines.push(
          `Coverage: ${coverageValue}% (window ${windowStart}–${windowEnd}, ${coverageWindow.expectedSpan} min)`
        )
      }

      lines.push(`Counts minutes: ${state.data.minutesWithData}`)
      const countSegments = buildSegments(state.data.minutes)
      if (countSegments.length === 0) {
        lines.push('Counts segments: none')
      } else {
        lines.push(`Counts segments (${countSegments.length}):`)
        for (const segment of countSegments) {
          const segStart = formatTime(
            dateFromIndex(selectedDate, segment.start)
          )
          const segEnd = formatTime(
            dateFromIndex(selectedDate, segment.start + segment.length - 1)
          )
          lines.push(
            `Counts segment: ${segStart}–${segEnd} (${segment.length} min)`
          )
        }
      }

      if (journalEntries.length === 0) {
        lines.push('Journal entries: none')
      } else {
        const entries = journalEntries.map((entry) =>
          `${entry.type} ${formatTime(dateFromIndex(selectedDate, entry.index))}`
        )
        lines.push(`Journal entries (${entries.length}): ${entries.join(', ')}`)
      }

      if (state.data.bouts.length === 0) {
        lines.push('Bouts: none')
      } else {
        lines.push(`Bouts (${state.data.bouts.length}):`)
        for (const bout of state.data.bouts) {
          const boutStart = formatTime(
            dateFromIndex(selectedDate, bout.start)
          )
          const boutEnd = formatTime(
            dateFromIndex(selectedDate, bout.start + bout.length - 1)
          )
          lines.push(
            `Bout: ${bout.activity} ${boutStart}–${boutEnd} (${bout.length} min)`
          )
        }
      }
    }

    lines.push('')

    const blob = new Blob([lines.join('\n')], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `accel-sync-${userId}-${dateLabel}.txt`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)
  }

  const handleGenerateImage = async (bucket: ImageSummaryBucket) => {
    const popup = window.open('', '_blank', 'noopener,noreferrer')
    if (popup) {
      popup.document.title = `Generating ${bucket} image...`
      popup.document.body.innerHTML = '<p style="font-family: sans-serif; padding: 24px;">Generating image...</p>'
    }

    setImageRequestState({
      loadingBucket: bucket,
      error: null,
    })

    try {
      const imageBlob = await fetchGeneratedImage(
        userId,
        selectedDate,
        bucket,
        imageGenerationSettings
      )
      const imageUrl = URL.createObjectURL(imageBlob)
      const requestDate = toLocalIsoDateTime(
        imageReferenceDateForBucket(selectedDate, bucket)
      )

      if (previewUrlsRef.current[bucket]) {
        URL.revokeObjectURL(previewUrlsRef.current[bucket]!)
      }
      previewUrlsRef.current[bucket] = imageUrl

      const record = {
        requestDate,
        generatedAt: new Date().toISOString(),
      }
      setGeneratedImageRecord(
        userId,
        selectedDate,
        bucket,
        imageGenerationSettings,
        record
      )
      setGeneratedImageRecords((current) => ({
        ...current,
        [bucket]: record,
      }))
      setGeneratedImagePreviews((current) => ({
        ...current,
        [bucket]: {
          loading: false,
          src: imageUrl,
          error: null,
        },
      }))

      if (popup) {
        popup.location.href = imageUrl
      } else {
        window.open(imageUrl, '_blank', 'noopener,noreferrer')
      }

      setImageRequestState({
        loadingBucket: null,
        error: null,
      })
    } catch (error) {
      if (popup) {
        popup.close()
      }
      setImageRequestState({
        loadingBucket: null,
        error: error instanceof Error ? error.message : 'Failed to generate image',
      })
    }
  }

  return (
    <section
      className={className ?? 'user-card'}
    >
      <header className="user-header">
        <div className="sync-detail-header-row">
          <div>
            <p className="eyebrow">User</p>
            <h2>{userId}</h2>
            <p className="sync-detail-date">{formatDate(selectedDate)}</p>
          </div>
          {onClose ? (
            <button
              type="button"
              className="icon-button sync-detail-close"
              onClick={onClose}
              aria-label="Close detail"
            >
              &#x2715;
            </button>
          ) : null}
        </div>
        <div className="stats">
          <div>
            <p className="stat-label">Minutes with data</p>
            <p className="stat-value">{state.data.minutesWithData}</p>
          </div>
          <div>
            <p className="stat-label">Coverage</p>
            <p className="stat-value">{coverageValue}%</p>
          </div>
          <div>
            <p className="stat-label">Bout minutes</p>
            <p className="stat-value">{state.data.boutMinutesTotal}</p>
          </div>
        </div>
      </header>

      <div className="timeline">
        <div className="track track-journal">
          <span className="track-label">Journal</span>
          <div className="journal-track-wrap">
            <svg viewBox={`0 0 ${MINUTES_PER_DAY} 24`} role="img">
              <rect
                x="0"
                y="7"
                width={MINUTES_PER_DAY}
                height="10"
                rx="5"
                fill="var(--journal-bg)"
              />
              {journalEntries.map((entry, index) => (
                <circle
                  key={`journal-${entry.index}-${entry.type}-${index}`}
                  cx={entry.index}
                  cy="12"
                  r="4"
                  className={`journal-entry-tick ${journalEntryClass(entry.type)}`}
                />
              ))}
              {currentMinuteIndex != null ? (
                <line
                  x1={currentMinuteIndex}
                  y1="0"
                  x2={currentMinuteIndex}
                  y2="24"
                  className="current-time-line"
                />
              ) : null}
            </svg>
            <div className="journal-legend" aria-label="Journal entry legend">
              {JOURNAL_LEGEND_ITEMS.map((item) => (
                <span className="journal-legend-item" key={item.label}>
                  <i className={`journal-legend-swatch ${item.className}`} />
                  {item.label}
                </span>
              ))}
            </div>
          </div>
        </div>
        <div className="track">
          <span className="track-label">Counts</span>
          <svg viewBox={`0 0 ${MINUTES_PER_DAY} 12`} role="img">
            <rect
              x="0"
              y="0"
              width={MINUTES_PER_DAY}
              height="12"
              rx="6"
              fill="var(--bar-bg)"
            />
            {segments.map((segment) => (
              <rect
                key={`${segment.start}-${segment.length}`}
                x={segment.start}
                y="0"
                width={segment.length}
                height="12"
                fill="var(--bar-fill)"
              />
            ))}
            {currentMinuteIndex != null ? (
              <line
                x1={currentMinuteIndex}
                y1="0"
                x2={currentMinuteIndex}
                y2="12"
                className="current-time-line"
              />
            ) : null}
          </svg>
        </div>
        <div className="track">
          <span className="track-label">Bouts</span>
          <svg viewBox={`0 0 ${MINUTES_PER_DAY} 12`} role="img">
            <rect
              x="0"
              y="0"
              width={MINUTES_PER_DAY}
              height="12"
              rx="6"
              fill="var(--bout-bg)"
            />
            {state.data.bouts.map((segment, index) => (
              <rect
                key={`${segment.start}-${segment.length}-${index}`}
                x={segment.start}
                y="0"
                width={segment.length}
                height="12"
                className={`bout-seg ${activityClass(segment.activity)}`}
              />
            ))}
            {currentMinuteIndex != null ? (
              <line
                x1={currentMinuteIndex}
                y1="0"
                x2={currentMinuteIndex}
                y2="12"
                className="current-time-line"
              />
            ) : null}
          </svg>
        </div>
        <div className="hour-labels">
          {hourMarkers.map((hour) => {
            const isMajor = hour % 6 === 0 || hour === 24
            return (
              <span
                key={hour}
                className={isMajor ? 'hour-major' : 'hour-minor'}
              >
                {hour.toString().padStart(2, '0')}
              </span>
            )
          })}
        </div>
      </div>

      <footer className="user-footer">
        <div className="sync-detail-footer-meta">
          {state.loading ? (
            <span className="pill">Loading...</span>
          ) : state.error ? (
            <span className="pill pill-error">{state.error}</span>
          ) : state.data.lastDataAt ? (
            <span className="pill">
              Last data at {formatTime(state.data.lastDataAt)}
            </span>
          ) : (
            <span className="pill pill-warn">No data yet today</span>
          )}
          {imageRequestState.error ? (
            <span className="pill pill-error">{imageRequestState.error}</span>
          ) : null}
        </div>
        <div className="sync-detail-footer-actions">
          {showImageActions ? (
            <div className="sync-detail-image-actions">
              {IMAGE_BUCKETS.map((bucket) => {
                const preview = generatedImagePreviews[bucket]
                const record = generatedImageRecords[bucket]
                const title = `${bucket[0].toUpperCase()}${bucket.slice(1)} image`

                if (record) {
                  return (
                    <div className="generated-image-card" key={bucket}>
                      <p className="generated-image-title">{title}</p>
                      {preview?.src ? (
                        <button
                          type="button"
                          className="generated-image-button"
                          onClick={() => {
                            window.open(
                              preview.src ?? '',
                              '_blank',
                              'noopener,noreferrer'
                            )
                          }}
                        >
                          <img
                            className="generated-image-preview"
                            src={preview.src}
                            alt={`${title} for ${toInputDate(selectedDate)}`}
                          />
                        </button>
                      ) : preview?.loading ? (
                        <span className="pill">Loading {bucket}...</span>
                      ) : (
                        <span className="pill pill-warn">
                          {preview?.error ?? 'Generated image unavailable'}
                        </span>
                      )}
                    </div>
                  )
                }

                return (
                  <button
                    key={bucket}
                    type="button"
                    className="secondary-button"
                    disabled={imageRequestState.loadingBucket != null}
                    onClick={() => {
                      void handleGenerateImage(bucket)
                    }}
                  >
                    {imageRequestState.loadingBucket === bucket
                      ? `Generating ${bucket}...`
                      : `Generate ${bucket}`}
                  </button>
                )
              })}
            </div>
          ) : null}
          <button type="button" onClick={handleExportUser}>
            Export TXT
          </button>
        </div>
      </footer>
    </section>
  )
}

const UserCard = ({
  userId,
  refreshToken,
  index,
  selectedDate,
  timezone,
}: {
  userId: string
  refreshToken: number
  index: number
  selectedDate: Date
  timezone: string
}) => (
  <SyncDetailCard
    userId={userId}
    refreshToken={refreshToken}
    selectedDate={selectedDate}
    timezone={timezone}
    className="user-card"
  />
)

const OverviewUserCard = ({
  userId,
  refreshToken,
  index,
  rangeStart,
  rangeEnd,
  focusedMonthDate,
  imageGenerationSettings,
}: {
  userId: string
  refreshToken: number
  index: number
  rangeStart: Date
  rangeEnd: Date
  focusedMonthDate: Date
  imageGenerationSettings: DashboardImageGenerationSettings
}) => {
  const [state, setState] = useState<UserOverviewState>({
    loading: true,
    error: null,
    data: emptyOverviewData(),
    updatedAt: null,
  })
  const [selectedDetailDateKey, setSelectedDetailDateKey] = useState<string | null>(
    null
  )

  useEffect(() => {
    let active = true

    const load = async () => {
      setState({
        loading: true,
        error: null,
        data: emptyOverviewData(),
        updatedAt: new Date(),
      })

      try {
        const data = await fetchOverviewData(
          userId,
          rangeStart,
          rangeEnd,
          focusedMonthDate
        )
        if (!active) return
        setState({
          loading: false,
          error: null,
          data,
          updatedAt: new Date(),
        })
      } catch (error) {
        if (!active) return
        setState({
          loading: false,
          error: error instanceof Error ? error.message : 'Unknown error',
          data: emptyOverviewData(),
          updatedAt: new Date(),
        })
      }
    }

    load()

    return () => {
      active = false
    }
  }, [userId, refreshToken, rangeStart, rangeEnd, focusedMonthDate])

  const maxMonthTotal = state.data.months.reduce(
    (max, month) => Math.max(max, month.total),
    0
  )
  const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S']
  const todayKey = toInputDate(new Date())
  const userStartDayKey = state.data.createdAt
    ? toInputDate(state.data.createdAt)
    : null
  const visibleMonths = state.data.months.filter((month) =>
    month.days.some((day) => day.hasData)
  )

  useEffect(() => {
    if (!selectedDetailDateKey) {
      return
    }

    const isVisible = visibleMonths.some((month) =>
      month.days.some((day) => day.date === selectedDetailDateKey)
    )

    if (!isVisible) {
      setSelectedDetailDateKey(null)
    }
  }, [selectedDetailDateKey, visibleMonths])

  return (
    <section
      className="user-card"
      style={{ animationDelay: `${index * 80}ms` }}
    >
      <header className="user-header">
        <div>
          <p className="eyebrow">User</p>
          <h2>{userId}</h2>
        </div>
        <div className="stats">
          <div>
            <p className="stat-label">Start date</p>
            <p className="stat-value">
              {state.data.createdAt ? toInputDate(state.data.createdAt) : 'n/a'}
            </p>
          </div>
          <div>
            <p className="stat-label">Days with data since start</p>
            <p className="stat-value">{state.data.daysWithDataSinceStart}</p>
          </div>
          <div>
            <p className="stat-label">Movement total</p>
            <p className="stat-value">
              {formatHours(state.data.movementTotal)}
            </p>
          </div>
          <div>
            <p className="stat-label">Still / data day</p>
            <p className="stat-value">
              {formatHours(state.data.averageSedentaryPerDayWithData)}
            </p>
          </div>
          <div>
            <p className="stat-label">Movement / data day</p>
            <p className="stat-value">
              {formatHours(state.data.averageMovementPerDayWithData)}
            </p>
          </div>
          <div>
            <p className="stat-label">Active / data day</p>
            <p className="stat-value">
              {formatHours(state.data.averageActivePerDayWithData)}
            </p>
          </div>
        </div>
      </header>

      {state.loading ? (
        <div className="overview-empty">Loading monthly activity...</div>
      ) : state.error ? (
        <div className="overview-empty overview-error">{state.error}</div>
      ) : visibleMonths.length === 0 ? (
        <div className="overview-empty">No months in selected range.</div>
      ) : (
        <div className="overview-panel">
          <div className="overview-legend">
            <span>
              <i className="legend-swatch legend-light-data" />
              Low data
            </span>
            <span>
              <i className="legend-swatch legend-has-data" />
              12h+ data
            </span>
            <span>
              <i className="legend-swatch legend-missing-data" />
              Missing day
            </span>
          </div>
          <div
            className="overview-calendar-list"
            aria-label={`Monthly activity calendar for ${userId}`}
          >
            {visibleMonths.map((month) => {
              const daysWithData = month.days.filter((day) => day.hasData).length
              const calendarOffset = getCalendarOffset(month.month)
              const isFocusedMonth = month.month === state.data.focusedMonth
              const selectedDetailDay = month.days.find(
                (day) => day.date === selectedDetailDateKey
              )
              return (
                <section
                  className={
                    selectedDetailDay
                      ? 'month-calendar-shell month-calendar-shell-expanded'
                      : 'month-calendar-shell'
                  }
                  key={month.month}
                >
                  <div
                    className={
                      isFocusedMonth
                        ? 'month-calendar month-calendar-focused'
                        : 'month-calendar'
                    }
                  >
                    <div className="month-calendar-header">
                      <div>
                        <h3>{formatMonthTitle(monthDateFromKey(month.month))}</h3>
                        <p>{daysWithData} days with data</p>
                      </div>
                      <span className="month-calendar-total">
                        {formatHours(month.total)}
                      </span>
                    </div>
                    <div className="month-calendar-weekdays">
                      {weekdayLabels.map((label, index) => (
                        <span key={`${month.month}-weekday-${index}`}>{label}</span>
                      ))}
                    </div>
                    <div className="month-calendar-grid">
                      {Array.from({ length: calendarOffset }, (_, index) => (
                        <span
                          key={`${month.month}-blank-${index}`}
                          className="month-calendar-empty"
                        />
                      ))}
                      {month.days.map((day) => {
                        const fillStrength = calendarDayFillStrength(
                          day.totalMinutes
                        )
                        const hasStrongFill = fillStrength >= 0.52

                        return (
                          <button
                            key={day.date}
                            type="button"
                            className={[
                              'month-calendar-day',
                              day.hasData
                                ? 'month-calendar-day-with-data'
                                : 'month-calendar-day-empty',
                              day.date === userStartDayKey
                                ? 'month-calendar-day-start-date'
                                : '',
                              day.date === todayKey
                                ? 'month-calendar-day-today'
                                : '',
                              day.date === selectedDetailDateKey
                                ? 'month-calendar-day-selected'
                                : '',
                            ]
                              .filter(Boolean)
                              .join(' ')}
                            style={
                              day.hasData
                                ? {
                                    backgroundColor: `rgba(31, 138, 112, ${0.1 + fillStrength * 0.9})`,
                                    color: hasStrongFill ? '#fff' : 'var(--ink)',
                                  }
                                : undefined
                            }
                            title={`${day.date}: ${
                              day.hasData
                                ? `${formatHours(day.totalMinutes)} recorded`
                                : 'no data'
                            }, ${day.journalEntries} journal ${
                              day.journalEntries === 1 ? 'entry' : 'entries'
                            }`}
                            aria-pressed={day.date === selectedDetailDateKey}
                            onClick={() =>
                              setSelectedDetailDateKey((current) =>
                                current === day.date ? null : day.date
                              )
                            }
                          >
                            <span className="month-calendar-day-number">
                              {day.day}
                            </span>
                            <span className="month-calendar-day-journal">
                              {day.journalEntries}
                            </span>
                          </button>
                        )
                      })}
                    </div>
                  </div>
                  {selectedDetailDay ? (
                    <SyncDetailCard
                      userId={userId}
                      refreshToken={refreshToken}
                      selectedDate={parseInputDate(selectedDetailDay.date)}
                      timezone={Intl.DateTimeFormat().resolvedOptions().timeZone}
                      className="user-card sync-detail-card sync-detail-card-embedded"
                      onClose={() => setSelectedDetailDateKey(null)}
                      showImageActions
                      imageGenerationSettings={imageGenerationSettings}
                    />
                  ) : null}
                </section>
              )
            })}
          </div>
        </div>
      )}

      <footer className="user-footer">
        {state.updatedAt ? (
          <span className="pill">Updated {formatTime(state.updatedAt)}</span>
        ) : (
          <span className="pill">Waiting for data</span>
        )}
      </footer>
    </section>
  )
}

const ImpactUserCard = ({
  userId,
  refreshToken,
  index,
  rangeStart,
  rangeEnd,
}: {
  userId: string
  refreshToken: number
  index: number
  rangeStart: Date
  rangeEnd: Date
}) => {
  const [state, setState] = useState<UserImpactState>({
    loading: true,
    error: null,
    data: emptyImpactData(),
    updatedAt: null,
  })

  useEffect(() => {
    let active = true

    const load = async () => {
      setState({
        loading: true,
        error: null,
        data: emptyImpactData(),
        updatedAt: new Date(),
      })

      try {
        const data = await fetchImpactData(userId, rangeStart, rangeEnd)
        if (!active) return
        setState({
          loading: false,
          error: null,
          data,
          updatedAt: new Date(),
        })
      } catch (error) {
        if (!active) return
        setState({
          loading: false,
          error: error instanceof Error ? error.message : 'Unknown error',
          data: emptyImpactData(),
          updatedAt: new Date(),
        })
      }
    }

    load()

    return () => {
      active = false
    }
  }, [userId, refreshToken, rangeStart, rangeEnd])

  const impactDirection =
    state.data.avgDelta24h > 0
      ? 'Positive signal'
      : state.data.avgDelta24h < 0
        ? 'Negative signal'
        : 'Neutral signal'
  const impactDescription =
    state.data.avgDelta24h > 0
      ? 'Users log more journal entries in the 24 hours after a notification than in the 24 hours before.'
      : state.data.avgDelta24h < 0
        ? 'Users log fewer journal entries in the 24 hours after a notification than in the 24 hours before.'
        : 'Journal activity is flat before and after sent notifications in this range.'
  const activeDays = state.data.days
    .filter((day) => day.notifications > 0 || day.journalEntries > 0)
    .slice(-12)
    .reverse()
  const maxNotifications = activeDays.reduce(
    (max, day) => Math.max(max, day.notifications),
    0
  )
  const maxJournalEntries = activeDays.reduce(
    (max, day) => Math.max(max, day.journalEntries),
    0
  )

  return (
    <section
      className="user-card"
      style={{ animationDelay: `${index * 80}ms` }}
    >
      <header className="user-header">
        <div>
          <p className="eyebrow">User</p>
          <h2>{userId}</h2>
        </div>
        <div className="stats">
          <div>
            <p className="stat-label">Notifications</p>
            <p className="stat-value">{state.data.notifications}</p>
          </div>
          <div>
            <p className="stat-label">Journal entries</p>
            <p className="stat-value">{state.data.journalEntries}</p>
          </div>
          <div>
            <p className="stat-label">24h response</p>
            <p className="stat-value">{state.data.responseRate24h}%</p>
          </div>
          <div>
            <p className="stat-label">24h delta</p>
            <p className="stat-value">{formatSigned(state.data.avgDelta24h)}</p>
          </div>
          <div>
            <p className="stat-label">Prompt match</p>
            <p className="stat-value">
              {state.data.targetedResponseRate24h == null
                ? 'n/a'
                : `${state.data.targetedResponseRate24h}%`}
            </p>
          </div>
        </div>
      </header>

      {state.loading ? (
        <div className="overview-empty">Loading notification impact...</div>
      ) : state.error ? (
        <div className="overview-empty overview-error">{state.error}</div>
      ) : state.data.notifications === 0 ? (
        <div className="overview-empty">
          No notification events in the selected range.
        </div>
      ) : (
        <div className="impact-panel">
          <section className="impact-callout">
            <div>
              <p className="eyebrow">Signal</p>
              <h3>{impactDirection}</h3>
              <p>{impactDescription}</p>
            </div>
            <div className="impact-callout-metrics">
              <div>
                <span>Before</span>
                <strong>{state.data.avgBefore24h.toFixed(2)}</strong>
              </div>
              <div>
                <span>After</span>
                <strong>{state.data.avgAfter24h.toFixed(2)}</strong>
              </div>
              <div>
                <span>Notified day avg</span>
                <strong>
                  {state.data.avgJournalEntriesOnNotificationDay.toFixed(2)}
                </strong>
              </div>
              <div>
                <span>Quiet day avg</span>
                <strong>
                  {state.data.avgJournalEntriesOnQuietDay.toFixed(2)}
                </strong>
              </div>
            </div>
          </section>

          <section className="impact-section">
            <div className="impact-section-header">
              <h3>By reminder type</h3>
              <p>
                Response rates and journal deltas per notification reason.
              </p>
            </div>
            <div className="impact-reason-grid">
              {state.data.reasons.map((reason) => (
                <article className="impact-reason-card" key={reason.reason}>
                  <div className="impact-reason-topline">
                    <h4>{formatReasonLabel(reason.reason)}</h4>
                    <span>{reason.total} sent</span>
                  </div>
                  <div className="impact-reason-stats">
                    <span>6h: {Math.round((reason.respondedWithin6h / reason.total) * 100)}%</span>
                    <span>24h: {Math.round((reason.respondedWithin24h / reason.total) * 100)}%</span>
                    <span>Delta: {formatSigned(reason.avgDelta24h)}</span>
                    <span>
                      Prompt match:{' '}
                      {reason.targetableNotifications > 0
                        ? `${Math.round(
                            (reason.targetedResponseWithin24h /
                              reason.targetableNotifications) *
                              100
                          )}%`
                        : 'n/a'}
                    </span>
                  </div>
                </article>
              ))}
            </div>
          </section>

          <section className="impact-section">
            <div className="impact-section-header">
              <h3>Recent active days</h3>
              <p>
                Daily notification volume against journal activity in the same
                range.
              </p>
            </div>
            {activeDays.length === 0 ? (
              <div className="overview-empty">No active days in this range.</div>
            ) : (
              <div className="impact-day-list">
                {activeDays.map((day) => (
                  <article className="impact-day-row" key={day.date}>
                    <div className="impact-day-meta">
                      <strong>{day.date}</strong>
                      <span>
                        {day.notifications} notifications, {day.journalEntries}{' '}
                        journal entries
                      </span>
                    </div>
                    <div className="impact-day-bars">
                      <div className="impact-day-bar-group">
                        <span>Notifications</span>
                        <div className="impact-day-bar-track">
                          <div
                            className="impact-day-bar impact-day-bar-notifications"
                            style={{
                              width:
                                maxNotifications > 0
                                  ? `${(day.notifications / maxNotifications) * 100}%`
                                  : '0%',
                            }}
                          />
                        </div>
                      </div>
                      <div className="impact-day-bar-group">
                        <span>Journal</span>
                        <div className="impact-day-bar-track">
                          <div
                            className="impact-day-bar impact-day-bar-journal"
                            style={{
                              width:
                                maxJournalEntries > 0
                                  ? `${(day.journalEntries / maxJournalEntries) * 100}%`
                                  : '0%',
                            }}
                          />
                        </div>
                      </div>
                    </div>
                  </article>
                ))}
              </div>
            )}
          </section>

          <section className="impact-section">
            <div className="impact-section-header">
              <h3>Latest notifications</h3>
              <p>
                Each row compares journal activity in the 24h before and after
                the notification.
              </p>
            </div>
            <div className="impact-event-list">
              {state.data.recentEvents.map((event) => (
                <article className="impact-event-card" key={`${event.reason}-${event.timestamp.toISOString()}`}>
                  <div className="impact-event-header">
                    <div>
                      <h4>{formatReasonLabel(event.reason)}</h4>
                      <p>{formatDateTime(event.timestamp)}</p>
                    </div>
                    <span
                      className={
                        event.respondedWithin24h
                          ? 'pill impact-pill-positive'
                          : 'pill impact-pill-neutral'
                      }
                    >
                      {event.respondedWithin24h ? 'Journaled in 24h' : 'No journal in 24h'}
                    </span>
                  </div>
                  <p className="impact-event-title">{event.title}</p>
                  <div className="impact-event-metrics">
                    <span>Before: {event.journalEntriesBefore24h}</span>
                    <span>6h: {event.journalEntriesAfter6h}</span>
                    <span>24h: {event.journalEntriesAfter24h}</span>
                    <span>
                      First response:{' '}
                      {event.firstJournalAfterHours == null
                        ? 'none'
                        : `${event.firstJournalAfterHours.toFixed(1)}h`}
                    </span>
                  </div>
                </article>
              ))}
            </div>
          </section>
        </div>
      )}

      <footer className="user-footer">
        {state.updatedAt ? (
          <span className="pill">Updated {formatTime(state.updatedAt)}</span>
        ) : (
          <span className="pill">Waiting for data</span>
        )}
        <span className="pill">
          {state.data.notificationDays} notified days / {state.data.quietDays}{' '}
          quiet days
        </span>
      </footer>
    </section>
  )
}

const ActigraphView = () => {
  const metadata = actigraphData.metadata
  const overview = actigraphData.overview
  const minutes = actigraphData.minutes
  const seconds = actigraphData.seconds
  const startDate = new Date(metadata.startIso)
  const stopDate = new Date(metadata.stopIso)
  const totalMinutes = Math.max(minutes.length, 1)
  const maxMinuteAverage = Math.max(...minutes.map((row) => row[2]), 1)
  const baseComparisonMinutes = minutes.map(
    ([minuteOffset, recordedSeconds, actigraphAvgVmMg, actigraphPeakVmMg]) => ({
      minuteOffset,
      timestamp: new Date(startDate.getTime() + minuteOffset * 60000),
      recordedSeconds,
      actigraphAvgVmMg,
      actigraphPeakVmMg,
      userCount: null,
      userHeartRate: null,
      normalizedActigraph: actigraphAvgVmMg / maxMinuteAverage,
      normalizedUser: null,
    })
  )
  const [comparisonState, setComparisonState] = useState<ActigraphComparisonState>(
    () =>
      actigraphUserId
        ? {
            loading: true,
            error: null,
            data: null,
            updatedAt: null,
          }
        : {
            loading: false,
            error: 'Set VITE_ACTIGRAPH_USERID in .env to compare against a user',
            data: null,
            updatedAt: null,
          }
  )

  const [selectedMinuteIndex, setSelectedMinuteIndex] = useState(() => {
    let bestIndex = 0
    for (let index = 1; index < minutes.length; index += 1) {
      if (minutes[index][2] > minutes[bestIndex][2]) {
        bestIndex = index
      }
    }
    return bestIndex
  })

  useEffect(() => {
    let active = true

    if (!actigraphUserId) {
      setComparisonState({
        loading: false,
        error: 'Set VITE_ACTIGRAPH_USERID in .env to compare against a user',
        data: null,
        updatedAt: null,
      })
      return () => {
        active = false
      }
    }

    setComparisonState({
      loading: true,
      error: null,
      data: null,
      updatedAt: new Date(),
    })

    fetchActigraphComparisonData(actigraphUserId)
      .then((data) => {
        if (!active) return
        setComparisonState({
          loading: false,
          error: null,
          data,
          updatedAt: new Date(),
        })
      })
      .catch((error) => {
        if (!active) return
        setComparisonState({
          loading: false,
          error: error instanceof Error ? error.message : 'Unknown error',
          data: null,
          updatedAt: new Date(),
        })
      })

    return () => {
      active = false
    }
  }, [])

  const clampedMinuteIndex = Math.max(
    0,
    Math.min(selectedMinuteIndex, minutes.length - 1)
  )
  const comparisonMinutes = comparisonState.data?.minutes ?? baseComparisonMinutes
  const selectedMinute =
    comparisonMinutes[clampedMinuteIndex] ?? baseComparisonMinutes[0]
  const selectedMinuteStart = new Date(
    startDate.getTime() + clampedMinuteIndex * 60 * 1000
  )
  const selectedMinuteEnd = new Date(
    Math.min(stopDate.getTime(), selectedMinuteStart.getTime() + 60 * 1000)
  )
  const selectedSeconds = seconds.slice(
    clampedMinuteIndex * 60,
    clampedMinuteIndex * 60 + 60
  )
  const maxSecondMagnitude = Math.max(
    ...selectedSeconds.map((row) => Math.max(row[2], row[3])),
    1
  )
  const coveragePercent =
    metadata.durationSeconds > 0
      ? Math.round((metadata.recordedSeconds / metadata.durationSeconds) * 100)
      : 0
  const topMinutes = [...minutes]
    .sort((left, right) => right[2] - left[2])
    .slice(0, 5)
  const packetSummary = Object.entries(metadata.packetCountsByType).sort(
    ([left], [right]) => Number(left) - Number(right)
  )
  const userComparisonPath = buildLinePath(
    comparisonMinutes.map((row) => row.normalizedUser),
    80,
    12
  )
  const selectedMinuteUserCount =
    selectedMinute?.userCount == null
      ? 'No aligned count'
      : formatCountValue(selectedMinute.userCount)
  const selectedMinuteHeartRate =
    selectedMinute?.userHeartRate == null
      ? 'No HR'
      : `${formatCountValue(selectedMinute.userHeartRate)} bpm`

  const handleMinuteChartClick = (event: MouseEvent<SVGSVGElement>) => {
    const bounds = event.currentTarget.getBoundingClientRect()
    if (bounds.width === 0) return
    const rawRatio = (event.clientX - bounds.left) / bounds.width
    const clampedRatio = Math.max(0, Math.min(rawRatio, 0.9999))
    setSelectedMinuteIndex(Math.floor(clampedRatio * minutes.length))
  }

  return (
    <section className="actigraph-view">
      <section className="user-card actigraph-hero-card">
        <header className="user-header actigraph-hero">
          <div>
            <p className="eyebrow">ActiGraph capture</p>
            <h2>{metadata.subjectName || metadata.fileName}</h2>
            <p className="sync-detail-date">
              {formatDateTimeFull(startDate)} to {formatTime(stopDate)}
            </p>
          </div>
          <div className="actigraph-hero-badge">
            {formatDurationFromSeconds(metadata.durationSeconds)}
          </div>
        </header>

        <div className="stats">
          <div>
            <p className="stat-label">Coverage</p>
            <p className="stat-value">{coveragePercent}%</p>
          </div>
          <div>
            <p className="stat-label">Recorded seconds</p>
            <p className="stat-value">{formatInteger(metadata.recordedSeconds)}</p>
          </div>
          <div>
            <p className="stat-label">Avg vector mag</p>
            <p className="stat-value">{formatMagnitude(overview.averageVmMg)}</p>
          </div>
          <div>
            <p className="stat-label">Peak vector mag</p>
            <p className="stat-value">{formatMagnitude(overview.peakVmMg)}</p>
          </div>
          <div>
            <p className="stat-label">Active minutes</p>
            <p className="stat-value">{formatInteger(overview.activeMinutes)}</p>
          </div>
          <div>
            <p className="stat-label">Gap minutes</p>
            <p className="stat-value">{formatInteger(overview.gapMinutes)}</p>
          </div>
        </div>

        <div className="actigraph-meta-inline">
          <span>{metadata.deviceType}</span>
          <span>{metadata.serialNumber}</span>
          <span>{metadata.sampleRateHz} Hz</span>
          <span>Firmware {metadata.firmware}</span>
          <span>{metadata.fileName}</span>
        </div>

        <section className="actigraph-compare-callout">
          <div>
            <p className="eyebrow">Counts comparison</p>
            <h3>{actigraphUserId || 'No comparison user configured'}</h3>
            <p>
              {comparisonState.loading
                ? 'Loading aligned minute counts for the ActiGraph recording day.'
                : comparisonState.error
                  ? comparisonState.error
                  : 'User minute counts are aligned against the ActiGraph recording window using exact minute timestamps.'}
            </p>
          </div>
          {comparisonState.data ? (
            <div className="actigraph-compare-metrics">
              <div>
                <span>Matched minutes</span>
                <strong>{formatInteger(comparisonState.data.matchedMinutes)}</strong>
              </div>
              <div>
                <span>Avg count</span>
                <strong>{formatCountValue(comparisonState.data.averageUserCount)}</strong>
              </div>
              <div>
                <span>Peak count</span>
                <strong>{formatCountValue(comparisonState.data.peakUserCount)}</strong>
              </div>
              <div>
                <span>Correlation</span>
                <strong>
                  {comparisonState.data.correlation == null
                    ? 'n/a'
                    : comparisonState.data.correlation.toFixed(2)}
                </strong>
              </div>
            </div>
          ) : null}
        </section>
      </section>

      <div className="actigraph-grid">
        <section className="user-card actigraph-panel">
          <div className="actigraph-panel-header">
            <div>
              <p className="eyebrow">Minute overview</p>
              <h3>ActiGraph vector magnitude vs app counts</h3>
              <p>Click anywhere on the chart to inspect the aligned minute.</p>
            </div>
          </div>

          <div className="actigraph-chart-shell">
            <svg
              viewBox={`0 0 ${totalMinutes} 124`}
              role="img"
              aria-label="ActiGraph minute-by-minute activity"
              className="actigraph-minute-chart"
              onClick={handleMinuteChartClick}
            >
              <rect
                x="0"
                y="8"
                width={totalMinutes}
                height="92"
                rx="6"
                className="actigraph-chart-bg"
              />
              {Array.from(
                { length: Math.floor(totalMinutes / 60) + 1 },
                (_, index) => (
                  <line
                    key={`minute-guide-${index}`}
                    x1={index * 60}
                    y1="8"
                    x2={index * 60}
                    y2="100"
                    className="actigraph-guide-line"
                  />
                )
              )}
              {minutes.map(([minuteOffset, recordedSeconds, avgVmMg]) => {
                const barHeight = Math.max((avgVmMg / maxMinuteAverage) * 80, 1)
                const barY = 92 - barHeight
                const opacity = 0.16 + (recordedSeconds / 60) * 0.84

                return (
                  <g key={`minute-${minuteOffset}`}>
                    {minuteOffset === clampedMinuteIndex ? (
                      <rect
                        x={minuteOffset - 0.2}
                        y="6"
                        width="1.4"
                        height="96"
                        rx="0.7"
                        className="actigraph-selection-frame"
                      />
                    ) : null}
                    <rect
                      x={minuteOffset + 0.1}
                      y={barY}
                      width="0.8"
                      height={barHeight}
                      rx="0.35"
                      style={{ fill: `rgba(31, 138, 112, ${opacity})` }}
                    />
                  </g>
                )
              })}
              {userComparisonPath ? (
                <path d={userComparisonPath} className="actigraph-compare-path" />
              ) : null}
            </svg>
            <div className="actigraph-axis actigraph-hour-axis">
              {Array.from(
                { length: Math.floor(totalMinutes / 60) + 1 },
                (_, index) => {
                  const tickDate = new Date(
                    startDate.getTime() + index * 60 * 60 * 1000
                  )
                  return (
                    <span key={`hour-${index}`}>
                      {index === Math.floor(totalMinutes / 60)
                        ? formatTime(stopDate)
                        : formatTime(tickDate)}
                    </span>
                  )
                }
              )}
            </div>
          </div>

          <div className="actigraph-legend">
            <span>
              <i className="actigraph-legend-swatch actigraph-legend-swatch-bars" />
              Green bars show ActiGraph vector magnitude
            </span>
            <span>
              <i className="actigraph-legend-swatch actigraph-legend-swatch-faint" />
              Lighter fill means fewer recorded seconds in that minute
            </span>
            <span>
              <i className="actigraph-legend-swatch actigraph-legend-swatch-compare" />
              Orange line shows normalized app counts for the same minute
            </span>
            <span>
              <i className="actigraph-legend-swatch actigraph-legend-swatch-selected" />
              Highlighted band is the selected minute
            </span>
          </div>
        </section>

        <section className="user-card actigraph-panel">
          <div className="sync-detail-header-row">
            <div>
              <p className="eyebrow">Selected minute</p>
              <h3>
                {formatTime(selectedMinuteStart)} to {formatTime(selectedMinuteEnd)}
              </h3>
              <p className="sync-detail-date">
                {selectedMinute.recordedSeconds} / 60 recorded seconds · avg{' '}
                {formatMagnitude(selectedMinute.actigraphAvgVmMg)} · peak{' '}
                {formatMagnitude(selectedMinute.actigraphPeakVmMg)}
              </p>
            </div>
            <div className="actigraph-minute-nav">
              <button
                type="button"
                className="icon-button"
                onClick={() =>
                  setSelectedMinuteIndex((current) => Math.max(0, current - 1))
                }
                disabled={clampedMinuteIndex === 0}
                aria-label="Previous minute"
              >
                &#x2039;
              </button>
              <button
                type="button"
                className="icon-button"
                onClick={() =>
                  setSelectedMinuteIndex((current) =>
                    Math.min(minutes.length - 1, current + 1)
                  )
                }
                disabled={clampedMinuteIndex === minutes.length - 1}
                aria-label="Next minute"
              >
                &#x203A;
              </button>
            </div>
          </div>

          <div className="actigraph-chart-shell">
            <svg
              viewBox="0 0 60 124"
              role="img"
              aria-label="Second-by-second detail for the selected minute"
              className="actigraph-second-chart"
            >
              <rect
                x="0"
                y="8"
                width="60"
                height="92"
                rx="6"
                className="actigraph-chart-bg"
              />
              {Array.from({ length: 7 }, (_, index) => (
                <line
                  key={`second-guide-${index}`}
                  x1={index * 10}
                  y1="8"
                  x2={index * 10}
                  y2="100"
                  className="actigraph-guide-line"
                />
              ))}
              {selectedSeconds.map(
                ([secondOffset, recorded, avgVmMg, peakVmMg], secondIndex) => {
                  const avgHeight = recorded
                    ? Math.max((avgVmMg / maxSecondMagnitude) * 70, 1)
                    : 0
                  const peakHeight = recorded
                    ? Math.max(
                        (peakVmMg / maxSecondMagnitude) * 82,
                        avgHeight + 4
                      )
                    : 0

                  return (
                    <g key={`second-${secondOffset}`}>
                      {recorded ? (
                        <>
                          <line
                            x1={secondIndex + 0.5}
                            y1={92 - peakHeight}
                            x2={secondIndex + 0.5}
                            y2="92"
                            className="actigraph-peak-line"
                          />
                          <rect
                            x={secondIndex + 0.14}
                            y={92 - avgHeight}
                            width="0.72"
                            height={avgHeight}
                            rx="0.3"
                            className="actigraph-second-bar"
                          />
                        </>
                      ) : (
                        <rect
                          x={secondIndex + 0.16}
                          y="90"
                          width="0.68"
                          height="2"
                          rx="0.3"
                          className="actigraph-gap-bar"
                        />
                      )}
                    </g>
                  )
                }
              )}
            </svg>
            <div className="actigraph-axis actigraph-second-axis">
              {Array.from({ length: 7 }, (_, index) => (
                <span key={`second-label-${index}`}>{index * 10}s</span>
              ))}
            </div>
          </div>

          <div className="stats actigraph-selected-stats">
            <div>
              <p className="stat-label">App count</p>
              <p className="stat-value">{selectedMinuteUserCount}</p>
            </div>
            <div>
              <p className="stat-label">Heart rate</p>
              <p className="stat-value">{selectedMinuteHeartRate}</p>
            </div>
            <div>
              <p className="stat-label">Minute time</p>
              <p className="stat-value">{formatDateTime(selectedMinute.timestamp)}</p>
            </div>
          </div>

          <div className="actigraph-legend">
            <span>
              <i className="actigraph-legend-swatch actigraph-legend-swatch-bars" />
              Dark bars show average vector magnitude each second
            </span>
            <span>
              <i className="actigraph-legend-swatch actigraph-legend-swatch-peak" />
              Thin stems show that second&apos;s peak magnitude
            </span>
            <span>
              <i className="actigraph-legend-swatch actigraph-legend-swatch-gap" />
              Short gray marks indicate missing seconds
            </span>
          </div>

          <div className="actigraph-top-minutes">
            <p className="eyebrow">Highest-load minutes</p>
            <div className="actigraph-top-minute-list">
              {topMinutes.map(([minuteOffset, recordedSeconds, avgVmMg]) => {
                const minuteDate = new Date(
                  startDate.getTime() + minuteOffset * 60 * 1000
                )
                const isSelected = minuteOffset === clampedMinuteIndex
                const comparedMinute = comparisonMinutes[minuteOffset]

                return (
                  <button
                    key={`top-minute-${minuteOffset}`}
                    type="button"
                    className={
                      isSelected
                        ? 'actigraph-top-minute-button is-active'
                        : 'actigraph-top-minute-button'
                    }
                    onClick={() => setSelectedMinuteIndex(minuteOffset)}
                  >
                    <strong>{formatTime(minuteDate)}</strong>
                    <span>{recordedSeconds}s recorded</span>
                    <span>{formatMagnitude(avgVmMg)}</span>
                    <span>
                      Count{' '}
                      {comparedMinute?.userCount == null
                        ? 'n/a'
                        : formatCountValue(comparedMinute.userCount)}
                    </span>
                  </button>
                )
              })}
            </div>
          </div>
        </section>
      </div>

      <section className="user-card actigraph-packets-card">
        <div className="actigraph-panel-header">
          <div>
            <p className="eyebrow">Packet summary</p>
            <h3>Raw GT3X packet mix for this file</h3>
            <p>Type `0` is the decoded activity stream used for the charts above.</p>
          </div>
        </div>
        <div className="actigraph-packet-grid">
          {packetSummary.map(([packetType, count]) => (
            <div className="actigraph-packet-card" key={`packet-${packetType}`}>
              <p className="stat-label">Packet type</p>
              <p className="stat-value">{packetType}</p>
              <p className="sync-detail-date">{formatInteger(count)} packets</p>
            </div>
          ))}
        </div>
      </section>
    </section>
  )
}

const App = () => {
  const [view, setView] = useState<DashboardView>('overview')
  const [refreshToken, setRefreshToken] = useState(0)
  const [impactUserIndex, setImpactUserIndex] = useState(0)
  const [selectedDate, setSelectedDate] = useState<Date>(() => new Date())
  const [overviewStartDate, setOverviewStartDate] = useState<Date>(() =>
    startOfMonth(addMonths(new Date(), -1))
  )
  const [overviewEndDate, setOverviewEndDate] = useState<Date>(() =>
    endOfMonth(new Date())
  )
  const [overviewFocusMonthDate, setOverviewFocusMonthDate] = useState<Date>(() =>
    startOfMonth(new Date())
  )
  const [imageGenerationSettings, setImageGenerationSettings] =
    useState<DashboardImageGenerationSettings>(() =>
      readImageGenerationSettings()
    )
  const [discoveredUserIds, setDiscoveredUserIds] = useState<string[]>(
    () => configuredUserIds
  )
  const [userDiscoveryState, setUserDiscoveryState] =
    useState<UserDiscoveryState>(() => ({
      loading: configuredUserIds.length === 0 && Boolean(apiBaseUrl),
      error: null,
      updatedAt: null,
    }))

  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone

  const handleRefresh = () => setRefreshToken((value) => value + 1)

  const todayLabel = formatDate(selectedDate)
  const inputValue = toInputDate(selectedDate)
  const today = new Date()
  const maxDate = toInputDate(today)
  const isToday = toInputDate(selectedDate) === maxDate
  const overviewStartInput = toInputMonth(overviewStartDate)
  const overviewEndInput = toInputMonth(overviewEndDate)
  const overviewFocusInput = toInputMonth(overviewFocusMonthDate)
  const rangeSubtitle =
    overviewStartInput === overviewEndInput
      ? formatMonthTitle(overviewStartDate)
      : `${formatMonthTitle(overviewStartDate)} to ${formatMonthTitle(
          overviewEndDate
        )}`
  const actigraphStartDate = new Date(actigraphData.metadata.startIso)
  const actigraphStopDate = new Date(actigraphData.metadata.stopIso)
  const actigraphSubtitle = `${formatDateTimeFull(
    actigraphStartDate
  )} to ${formatTime(actigraphStopDate)} · ${actigraphData.metadata.deviceType}${
    actigraphUserId ? ` · compare ${actigraphUserId}` : ''
  }`
  const visibleUserIds =
    configuredUserIds.length > 0 ? configuredUserIds : discoveredUserIds

  useEffect(() => {
    let active = true

    if (configuredUserIds.length > 0) {
      setDiscoveredUserIds(configuredUserIds)
      setUserDiscoveryState({
        loading: false,
        error: null,
        updatedAt: null,
      })
      return () => {
        active = false
      }
    }

    if (!apiBaseUrl) {
      setDiscoveredUserIds([])
      setUserDiscoveryState({
        loading: false,
        error: null,
        updatedAt: null,
      })
      return () => {
        active = false
      }
    }

    setUserDiscoveryState({
      loading: true,
      error: null,
      updatedAt: new Date(),
    })

    fetchRecentActiveUserIds()
      .then((activeUserIds) => {
        if (!active) return
        setDiscoveredUserIds(activeUserIds)
        setUserDiscoveryState({
          loading: false,
          error: null,
          updatedAt: new Date(),
        })
      })
      .catch((error) => {
        if (!active) return
        setDiscoveredUserIds([])
        setUserDiscoveryState({
          loading: false,
          error: error instanceof Error ? error.message : 'Unknown error',
          updatedAt: new Date(),
        })
      })

    return () => {
      active = false
    }
  }, [refreshToken])

  useEffect(() => {
    if (overviewFocusMonthDate < startOfMonth(overviewStartDate)) {
      setOverviewFocusMonthDate(startOfMonth(overviewStartDate))
      return
    }

    if (overviewFocusMonthDate > startOfMonth(overviewEndDate)) {
      setOverviewFocusMonthDate(startOfMonth(overviewEndDate))
    }
  }, [overviewEndDate, overviewFocusMonthDate, overviewStartDate])

  useEffect(() => {
    if (visibleUserIds.length === 0) {
      if (impactUserIndex !== 0) {
        setImpactUserIndex(0)
      }
      return
    }

    if (impactUserIndex > visibleUserIds.length - 1) {
      setImpactUserIndex(visibleUserIds.length - 1)
    }
  }, [impactUserIndex, visibleUserIds.length])

  const setOverviewRangeMonths = (months: number) => {
    const end = endOfMonth(new Date())
    const start = startOfMonth(addMonths(end, -(months - 1)))
    setOverviewStartDate(start)
    setOverviewEndDate(end)
    setOverviewFocusMonthDate(startOfMonth(end))
    setRefreshToken((current) => current + 1)
  }

  const selectedImpactUserId =
    visibleUserIds[
      Math.min(impactUserIndex, Math.max(visibleUserIds.length - 1, 0))
    ] ?? null
  const canGoToPreviousImpactUser = impactUserIndex > 0
  const canGoToNextImpactUser = impactUserIndex < visibleUserIds.length - 1
  const isOpenAIImageModel =
    imageProviderForModel(imageGenerationSettings.model) === 'openai'
  const imageQualityLabel = isOpenAIImageModel
    ? 'Image quality'
    : 'Image quality (OpenAI only)'

  return (
    <div className="app">
      <header className="app-header">
        <div>
          <p className="eyebrow">Accel Minutes Sync</p>
          <h1>
            {view === 'overview'
              ? 'Activity overview'
              : view === 'impact'
                ? 'Self-report impact'
                : view === 'actigraph'
                  ? 'ActiGraph visualization'
                  : 'Daily coverage'}
          </h1>
          <p className="subtitle">
            {view === 'overview'
              ? `${formatMonthTitle(overviewFocusMonthDate)} focus month · ${timezone}`
              : view === 'impact'
                ? `${rangeSubtitle} · ${timezone}${
                    selectedImpactUserId
                      ? ` · ${
                          impactUserIndex + 1
                        } / ${visibleUserIds.length} · ${selectedImpactUserId}`
                      : ''
                  }`
                : view === 'actigraph'
                  ? actigraphSubtitle
                  : `${todayLabel} · ${timezone}`}
          </p>
        </div>
        <div className="actions">
          <div className="view-toggle" role="tablist" aria-label="Dashboard view">
            <button
              type="button"
              className={view === 'overview' ? 'toggle-button is-active' : 'toggle-button'}
              onClick={() => setView('overview')}
            >
              Overview
            </button>
            <button
              type="button"
              className={view === 'impact' ? 'toggle-button is-active' : 'toggle-button'}
              onClick={() => setView('impact')}
            >
              Impact
            </button>
            <button
              type="button"
              className={view === 'sync' ? 'toggle-button is-active' : 'toggle-button'}
              onClick={() => setView('sync')}
            >
              Sync detail
            </button>
            <button
              type="button"
              className={view === 'actigraph' ? 'toggle-button is-active' : 'toggle-button'}
              onClick={() => setView('actigraph')}
            >
              ActiGraph
            </button>
          </div>
          <div className="image-settings-panel">
            <label className="date-picker" htmlFor="image-model-select">
              <span>Image model</span>
              <select
                id="image-model-select"
                value={imageGenerationSettings.model}
                onChange={(event) => {
                  const nextModel = event.target.value
                  if (!isDashboardImageModel(nextModel)) return

                  const nextSettings = {
                    ...imageGenerationSettings,
                    model: nextModel,
                  }
                  setImageGenerationSettings(nextSettings)
                  writeImageGenerationSettings(nextSettings)
                }}
              >
                {IMAGE_MODEL_OPTIONS.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </label>
            <label className="date-picker" htmlFor="image-quality-select">
              <span>{imageQualityLabel}</span>
              <select
                id="image-quality-select"
                value={imageGenerationSettings.quality}
                disabled={!isOpenAIImageModel}
                title={
                  isOpenAIImageModel
                    ? 'Select OpenAI image quality'
                    : 'Quality is only used for OpenAI image models'
                }
                onChange={(event) => {
                  const nextQuality = event.target.value
                  if (!isDashboardImageQuality(nextQuality)) return

                  const nextSettings = {
                    ...imageGenerationSettings,
                    quality: nextQuality,
                  }
                  setImageGenerationSettings(nextSettings)
                  writeImageGenerationSettings(nextSettings)
                }}
              >
                {IMAGE_QUALITY_OPTIONS.map((quality) => (
                  <option key={quality} value={quality}>
                    {quality[0].toUpperCase()}
                    {quality.slice(1)}
                  </option>
                ))}
              </select>
            </label>
          </div>
          {view === 'sync' ? (
            <div className="date-nav">
              <button
                type="button"
                className="icon-button"
                onClick={() => {
                  const next = addDays(selectedDate, -1)
                  next.setHours(0, 0, 0, 0)
                  setSelectedDate(next)
                  setRefreshToken((current) => current + 1)
                }}
                aria-label="Previous day"
              >
                &#x2039;
              </button>
              <label className="date-picker" htmlFor="date-input">
                <span>Date</span>
                <input
                  id="date-input"
                  type="date"
                  value={inputValue}
                  max={maxDate}
                  onChange={(event) => {
                    const value = event.target.value
                    if (!value) return
                    const [year, month, day] = value.split('-').map(Number)
                    const next = new Date(selectedDate)
                    next.setFullYear(year, month - 1, day)
                    next.setHours(0, 0, 0, 0)
                    setSelectedDate(next)
                    setRefreshToken((current) => current + 1)
                  }}
                />
              </label>
              <button
                type="button"
                className="icon-button"
                onClick={() => {
                  const next = addDays(selectedDate, 1)
                  next.setHours(0, 0, 0, 0)
                  setSelectedDate(next)
                  setRefreshToken((current) => current + 1)
                }}
                disabled={isToday}
                aria-label="Next day"
              >
                &#x203A;
              </button>
            </div>
          ) : view === 'overview' || view === 'impact' ? (
            <div className="overview-controls">
              <label className="date-picker" htmlFor="overview-start">
                <span>From month</span>
                <input
                  id="overview-start"
                  type="month"
                  value={overviewStartInput}
                  max={overviewEndInput}
                  onChange={(event) => {
                    const nextStart = parseMonthInput(event.target.value, 'start')
                    if (nextStart > overviewEndDate) {
                      setOverviewEndDate(endOfMonth(nextStart))
                    }
                    setOverviewStartDate(nextStart)
                    setRefreshToken((current) => current + 1)
                  }}
                />
              </label>
              <label className="date-picker" htmlFor="overview-end">
                <span>To month</span>
                <input
                  id="overview-end"
                  type="month"
                  value={overviewEndInput}
                  max={toInputMonth(new Date())}
                  min={overviewStartInput}
                  onChange={(event) => {
                    const nextEnd = parseMonthInput(event.target.value, 'end')
                    if (nextEnd < overviewStartDate) {
                      setOverviewStartDate(startOfMonth(nextEnd))
                    }
                    setOverviewEndDate(nextEnd)
                    setRefreshToken((current) => current + 1)
                  }}
                />
              </label>
              {view === 'overview' ? (
                <label className="date-picker" htmlFor="overview-focus">
                  <span>Focus month</span>
                  <input
                    id="overview-focus"
                    type="month"
                    value={overviewFocusInput}
                    min={overviewStartInput}
                    max={overviewEndInput}
                    onChange={(event) => {
                      setOverviewFocusMonthDate(
                        parseMonthInput(event.target.value, 'start')
                      )
                      setRefreshToken((current) => current + 1)
                    }}
                  />
                </label>
              ) : null}
              <div className="range-shortcuts">
                {(view === 'impact' ? [3, 6, 12] : [6, 12, 24]).map((months) => (
                  <button
                    key={months}
                    type="button"
                    className="shortcut-button"
                    onClick={() => setOverviewRangeMonths(months)}
                  >
                    {months}m
                  </button>
                ))}
              </div>
            </div>
          ) : null}
          {view !== 'actigraph' ? (
            <button type="button" onClick={handleRefresh}>
              Refresh
            </button>
          ) : null}
        </div>
      </header>

      {view === 'actigraph' ? (
        <main className="actigraph-layout">
          <ActigraphView />
        </main>
      ) : !apiBaseUrl ? (
        <section className="empty-state">
          <h2>Missing API base URL</h2>
          <p>
            Set <code>VITE_API_BASE_URL</code> in your{' '}
            <code>.env</code> file to point at the API.
          </p>
        </section>
      ) : userDiscoveryState.loading ? (
        <section className="empty-state">
          <h2>Finding active users</h2>
          <p>
            Checking the last {RECENT_ACTIVITY_DAYS} days for journal entries or
            accel count data.
          </p>
        </section>
      ) : userDiscoveryState.error ? (
        <section className="empty-state">
          <h2>Could not load active users</h2>
          <p>{userDiscoveryState.error}</p>
        </section>
      ) : visibleUserIds.length === 0 ? (
        <section className="empty-state">
          <h2>No recent active users</h2>
          <p>
            No users had journal entries or accel count data in the last{' '}
            {RECENT_ACTIVITY_DAYS} days. Set <code>VITE_USER_IDS</code> to show a
            fixed list.
          </p>
        </section>
      ) : (
        view === 'impact' ? (
          <main className="impact-browser">
            <button
              type="button"
              className="icon-button impact-nav-button"
              onClick={() =>
                setImpactUserIndex((current) => Math.max(0, current - 1))
              }
              disabled={!canGoToPreviousImpactUser}
              aria-label="Previous user"
            >
              &#x2039;
            </button>
            <div className="impact-browser-card">
              {selectedImpactUserId ? (
                <ImpactUserCard
                  key={selectedImpactUserId}
                  userId={selectedImpactUserId}
                  refreshToken={refreshToken}
                  index={0}
                  rangeStart={overviewStartDate}
                  rangeEnd={overviewEndDate}
                />
              ) : null}
            </div>
            <button
              type="button"
              className="icon-button impact-nav-button"
              onClick={() =>
                setImpactUserIndex((current) =>
                  Math.min(visibleUserIds.length - 1, current + 1)
                )
              }
              disabled={!canGoToNextImpactUser}
              aria-label="Next user"
            >
              &#x203A;
            </button>
          </main>
        ) : (
          <main className="grid">
            {visibleUserIds.map((userId, index) => (
              view === 'overview' ? (
              <OverviewUserCard
                key={userId}
                userId={userId}
                refreshToken={refreshToken}
                index={index}
                rangeStart={overviewStartDate}
                rangeEnd={overviewEndDate}
                focusedMonthDate={overviewFocusMonthDate}
                imageGenerationSettings={imageGenerationSettings}
              />
            ) : view === 'impact' ? (
              <ImpactUserCard
                key={userId}
                userId={userId}
                refreshToken={refreshToken}
                index={index}
                rangeStart={overviewStartDate}
                rangeEnd={overviewEndDate}
              />
            ) : (
              <UserCard
                key={userId}
                userId={userId}
                refreshToken={refreshToken}
                index={index}
                selectedDate={selectedDate}
                timezone={timezone}
              />
              )
            ))}
          </main>
        )
      )}
    </div>
  )
}

export default App
