import { useEffect, useState } from 'react'

const MINUTES_PER_DAY = 1440

type CountRow = {
  t: string
  hr: number
  a: number
}

type TelemetryRow = {
  t: string
  accelMinutesCount?: number
  sentToServer?: boolean
  backgroundSync?: boolean
  batteryPercent?: number
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

type UserData = {
  minutes: boolean[]
  minutesWithData: number
  lastDataAt: Date | null
  bouts: BoutSegment[]
  boutMinutesTotal: number
  telemetryTicks: number[]
  batteryPoints: Array<{ index: number; percent: number }>
}

type UserState = {
  loading: boolean
  error: string | null
  data: UserData
}

type UserExportState = UserState & {
  updatedAt: Date | null
}

const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL ?? '').trim()
const apiKey = (import.meta.env.VITE_API_KEY ?? '').trim()
const userIds = (import.meta.env.VITE_USER_IDS ?? '')
  .split(',')
  .map((id: string) => id.trim())
  .filter(Boolean)

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

const toInputDate = (date: Date) => {
  const year = date.getFullYear()
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  const day = `${date.getDate()}`.padStart(2, '0')
  return `${year}-${month}-${day}`
}

const addDays = (date: Date, delta: number) => {
  const next = new Date(date)
  next.setDate(next.getDate() + delta)
  return next
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

const emptyUserData = (): UserData => ({
  minutes: Array.from({ length: MINUTES_PER_DAY }, () => false),
  minutesWithData: 0,
  lastDataAt: null,
  bouts: [],
  boutMinutesTotal: 0,
  telemetryTicks: [],
  batteryPoints: [],
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

const parseBatteryPercent = (value: unknown): number | null => {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.min(100, Math.max(0, value))
  }
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value)
    if (Number.isFinite(parsed)) {
      return Math.min(100, Math.max(0, parsed))
    }
  }
  return null
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

  const telemetryUrl = new URL(`${base}/telemetry/${userId}`)
  telemetryUrl.searchParams.set('from', start.toISOString())
  telemetryUrl.searchParams.set('to', end.toISOString())

  const headers: Record<string, string> = {}
  if (apiKey) headers['x-api-key'] = apiKey

  const [countsResponse, boutsResponse, telemetryResponse] = await Promise.all([
    fetch(countsUrl.toString(), { headers }),
    fetch(boutsUrl.toString(), { headers }),
    fetch(telemetryUrl.toString(), { headers }),
  ])

  if (!countsResponse.ok) {
    throw new Error(`Counts request failed: ${countsResponse.status}`)
  }

  if (!boutsResponse.ok) {
    throw new Error(`Bouts request failed: ${boutsResponse.status}`)
  }

  if (!telemetryResponse.ok) {
    throw new Error(`Telemetry request failed: ${telemetryResponse.status}`)
  }

  const rows = (await countsResponse.json()) as CountRow[]
  const bouts = (await boutsResponse.json()) as BoutRow[]
  const telemetry = (await telemetryResponse.json()) as TelemetryRow[]
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

  const telemetryIndexSet = new Set<number>()
  const batteryPoints: Array<{ index: number; percent: number }> = []
  for (const item of telemetry) {
    const timestamp = new Date(item.t)
    if (Number.isNaN(timestamp.getTime())) continue
    if (timestamp < start || timestamp > end) continue
    const index = Math.floor((timestamp.getTime() - start.getTime()) / 60000)
    if (index < 0 || index >= MINUTES_PER_DAY) continue
    telemetryIndexSet.add(index)

    const percent = parseBatteryPercent(item.batteryPercent)
    if (percent != null) {
      batteryPoints.push({
        index,
        percent,
      })
    }
  }

  const telemetryTicks = Array.from(telemetryIndexSet).sort((a, b) => a - b)

  return {
    minutes,
    minutesWithData,
    lastDataAt,
    bouts: boutSegments,
    boutMinutesTotal,
    telemetryTicks,
    batteryPoints: batteryPoints.sort((a, b) => a.index - b.index),
  }
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
}) => {
  const [state, setState] = useState<UserExportState>({
    loading: true,
    error: null,
    data: emptyUserData(),
    updatedAt: null,
  })

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
  const batteryPoints = state.data.batteryPoints
  const batteryPath =
    batteryPoints.length > 0
      ? (() => {
          const first = batteryPoints[0]
          const last = batteryPoints[batteryPoints.length - 1]
          const firstY = 40 - (first.percent / 100) * 40
          const lastY = 40 - (last.percent / 100) * 40
          const commands = [`M 0 ${firstY}`, `L ${first.index} ${firstY}`]

          batteryPoints.forEach((point, idx) => {
            if (idx === 0) return
            const x = point.index
            const y = 40 - (point.percent / 100) * 40
            commands.push(`L ${x} ${y}`)
          })

          commands.push(`L ${MINUTES_PER_DAY} ${lastY}`)
          return commands.join(' ')
        })()
      : ''

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

      if (state.data.telemetryTicks.length === 0) {
        lines.push('Telemetry events: none')
      } else {
        const times = state.data.telemetryTicks.map((index) =>
          formatTime(dateFromIndex(selectedDate, index))
        )
        lines.push(`Telemetry events (${times.length}): ${times.join(', ')}`)
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
        <div className="track">
          <span className="track-label">Battery</span>
          <svg
            className="battery-svg"
            viewBox={`0 0 ${MINUTES_PER_DAY} 40`}
            role="img"
          >
            <rect
              x="0"
              y="0"
              width={MINUTES_PER_DAY}
              height="40"
              rx="6"
              fill="var(--battery-bg)"
            />
            {batteryPath ? (
              <path
                d={batteryPath}
                fill="none"
                stroke="var(--battery-line)"
                strokeWidth="2"
                vectorEffect="non-scaling-stroke"
              />
            ) : null}
            {batteryPoints.map((point) => (
              <circle
                key={`battery-${point.index}`}
                cx={point.index}
                cy={40 - (point.percent / 100) * 40}
                r="2"
                className="battery-point"
              />
            ))}
            {currentMinuteIndex != null ? (
              <line
                x1={currentMinuteIndex}
                y1="0"
                x2={currentMinuteIndex}
                y2="40"
                className="current-time-line"
              />
            ) : null}
          </svg>
        </div>
        <div className="track">
          <span className="track-label">Telemetry</span>
          <svg viewBox={`0 0 ${MINUTES_PER_DAY} 12`} role="img">
            <rect
              x="0"
              y="0"
              width={MINUTES_PER_DAY}
              height="12"
              rx="6"
              fill="var(--telemetry-bg)"
            />
            {state.data.telemetryTicks.map((index) => (
              <rect
                key={`telemetry-${index}`}
                x={index}
                y="1"
                width="2"
                height="10"
                className="telemetry-tick"
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
        <button type="button" onClick={handleExportUser}>
          Export TXT
        </button>
      </footer>
    </section>
  )
}

const App = () => {
  const [refreshToken, setRefreshToken] = useState(0)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [selectedDate, setSelectedDate] = useState<Date>(() => new Date())

  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone

  useEffect(() => {
    setLastUpdated(new Date())
  }, [refreshToken])

  useEffect(() => {
    const interval = setInterval(() => {
      setRefreshToken((value) => value + 1)
    }, 60000)

    return () => clearInterval(interval)
  }, [])

  const handleRefresh = () => setRefreshToken((value) => value + 1)

  const todayLabel = formatDate(selectedDate)
  const inputValue = toInputDate(selectedDate)
  const today = new Date()
  const maxDate = toInputDate(today)
  const isToday = toInputDate(selectedDate) === maxDate

  return (
    <div className="app">
      <header className="app-header">
        <div>
          <p className="eyebrow">Accel Minutes Sync</p>
          <h1>Daily coverage</h1>
          <p className="subtitle">
            {todayLabel} · {timezone}
          </p>
        </div>
        <div className="actions">
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
          <button type="button" onClick={handleRefresh}>
            Refresh
          </button>
          <div className="meta">
            <span>Auto-refresh every 60s</span>
            {lastUpdated ? (
              <span>Updated {formatTime(lastUpdated)}</span>
            ) : null}
          </div>
        </div>
      </header>

      {!apiBaseUrl ? (
        <section className="empty-state">
          <h2>Missing API base URL</h2>
          <p>
            Set <code>VITE_API_BASE_URL</code> in your{' '}
            <code>.env</code> file to point at the API.
          </p>
        </section>
      ) : userIds.length === 0 ? (
        <section className="empty-state">
          <h2>No users configured</h2>
          <p>
            Add a comma-separated list to <code>VITE_USER_IDS</code> in your{' '}
            <code>.env</code> file.
          </p>
        </section>
      ) : (
        <main className="grid">
          {userIds.map((userId, index) => (
            <UserCard
              key={userId}
              userId={userId}
              refreshToken={refreshToken}
              index={index}
              selectedDate={selectedDate}
              timezone={timezone}
            />
          ))}
        </main>
      )}
    </div>
  )
}

export default App
