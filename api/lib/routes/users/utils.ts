import moment from 'moment'
import * as redis from '../../adapters/redis'
import UserModel from '../../db/models/User'
import AccelCountModel, { AccelCount } from '../../db/models/AccelCount'

import { Activity, getEnergy } from '../../adapters/energy'
import { calculateCounts } from '../../adapters/counts'

import * as utils from '../../utils'
import { Accel } from '../../db/models/Accel'
import { HeartRate } from '../../db/models/HeartRate'

const INACTIVE_THRESHOLD = 3000

export const countsCacheKey = (userId: string, minute: string) =>
  `${userId}-${minute}`

export const checkAndSaveCounts = async (
  userId: string,
  accelDataPoints: Accel[],
  hrDataPoints: HeartRate[]
) => {
  const accMinutes = utils.group(accelDataPoints, (d) => utils.getMinute(d.t))
  const hrMinutes = utils.group(hrDataPoints, (d) => utils.getMinute(d.t))

  Object.keys(accMinutes).forEach(async (minute) => {
    const cacheKey = countsCacheKey(userId, minute)
    let cached = await redis.get(cacheKey)
    if (!cached) cached = { hr: [], accel: [] }

    const accel = [...cached.accel, ...accMinutes[minute]]
    const hr = [...cached.hr, ...(hrMinutes[minute] ? hrMinutes[minute] : [])]
    if (accel.length < 1800) {
      redis.set(cacheKey, {
        accel,
        hr,
      })
      return
    }

    const counts = await calculateCounts({ accel, hr })
    await AccelCountModel.save(counts, userId)
  })
}

export const energyForPeriod = async ({
  from,
  to,
  id,
  activity,
  watt,
  overwrite,
}: {
  from: Date
  to: Date
  id: string
  activity: Activity
  watt?: number
  overwrite?: any
}) => {
  const user = await UserModel.get(id)
  const counts = await AccelCountModel.find({
    userId: id,
    from,
    to,
  })
  return getEnergy({ counts, ...user, ...overwrite, activity, watt })
}

export const activityForPeriod = async ({
  from,
  to,
  id,
}: {
  from: Date
  to: Date
  id: string
}) => {
  const counts = await AccelCountModel.find({
    userId: id,
    from,
    to,
  })

  // minutes inactive
  const firstActiveIndexReversed = counts
    .reverse()
    .findIndex(({ a }) => a > INACTIVE_THRESHOLD)
  const minutesInactive = moment(to).diff(
    firstActiveIndexReversed >= 0 ? counts[firstActiveIndexReversed].t : from,
    'minutes'
  )

  // average inactive duration
  const inactiveIntervals = counts
    .reduce<AccelCount[][]>(
      (intervals, count) => {
        if (count.a < INACTIVE_THRESHOLD) {
          intervals[intervals.length - 1].push(count)
        } else if (intervals[intervals.length - 1].length >= 0) {
          intervals.push([])
        }
        return intervals
      },
      [[]]
    )
    .filter((x) => x.length > 0)
  const averageInactiveDuration =
    inactiveIntervals.reduce(
      (sum, interval) =>
        sum +
        moment(interval[0].t).diff(interval[interval.length - 1].t, 'minutes') +
        1,
      0
    ) / (inactiveIntervals.length || 1)

  return {
    minutesInactive,
    averageInactiveDuration,
  }
}

export const fromToForDate = (date: Date) => {
  const from = new Date(date.setHours(0, 0, 0, 0))
  const to = new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
    23,
    59,
    59
  )
  return [from, to]
}
