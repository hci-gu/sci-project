const moment = require('moment')
const redis = require('../../adapters/redis')
const { User, AccelCount } = require('../../db/models')

const { getEnergy } = require('../../adapters/energy')
const { calculateCounts } = require('../../adapters/counts')

const INACTIVE_THRESHOLD = 3000

const group = (data, f) => {
  const groups = {}
  data.forEach((d) => {
    const key = f(d)
    if (!groups[key]) groups[key] = []
    groups[key].push(d)
  })
  return groups
}

const getMinute = (ts) => {
  const d = new Date(ts)
  return `${d.getFullYear()}-${
    d.getMonth() + 1
  }-${d.getDate()} ${d.getHours()}:${d.getMinutes()}`
}

const countsCacheKey = (userId, minute) => `${userId}-${minute}`

const checkAndSaveCounts = async (userId, accelDataPoints, hrDataPoints) => {
  const accMinutes = group(accelDataPoints, (d) => getMinute(d.t))
  const hrMinutes = group(hrDataPoints, (d) => getMinute(d.t))

  Object.keys(accMinutes).forEach(async (minute) => {
    const cacheKey = countsCacheKey(userId, minute)
    const cached = await redis.get(cacheKey)

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
    await AccelCount.save(counts, userId)
  })
}

const energyForPeriod = async ({ from, to, id, activity, watt, overwrite }) => {
  const user = await User.get(id)
  const counts = await AccelCount.find({
    userId: id,
    from: new Date(from).toISOString(),
    to: new Date(to).toISOString(),
  })
  return getEnergy({ counts, ...user.dataValues, ...overwrite, activity, watt })
}

const activityForPeriod = async ({ from, to, id }) => {
  const counts = await AccelCount.find({
    userId: id,
    from: new Date(from).toISOString(),
    to: new Date(to).toISOString(),
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
    .reduce(
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

const promiseSeries = (items, method) => {
  const results = []

  function runMethod(item) {
    return new Promise((resolve, reject) => {
      method(item)
        .then((res) => {
          results.push(res)
          resolve(res)
        })
        .catch((err) => reject(err))
    })
  }

  return items
    .reduce(
      (promise, item) => promise.then(() => runMethod(item)),
      Promise.resolve()
    )
    .then(() => results)
}

module.exports = {
  checkAndSaveCounts,
  energyForPeriod,
  activityForPeriod,
  promiseSeries,
}
