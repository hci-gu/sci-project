const moment = require('moment')
const { User, Accel, AccelCount, HeartRate } = require('../../db/models')

const { getEnergy } = require('../../adapters/energy')
const { calculateCounts } = require('../../adapters/counts')

const INACTIVE_THRESHOLD = 3000

const checkAndSaveCounts = async (userId, overWriteFrom) => {
  const now = new Date()
  const from = overWriteFrom
    ? overWriteFrom
    : new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate(),
        now.getHours(),
        now.getMinutes() - 1
      )
  const to = new Date(
    from.getFullYear(),
    from.getMonth(),
    from.getDate(),
    from.getHours(),
    from.getMinutes(),
    59
  )

  const accelCounts = await AccelCount.find({
    userId,
    from,
    to,
  })

  if (!!accelCounts.length) {
    return
  }

  const [accel, hr] = await Promise.all([
    Accel.find({ userId, from, to }),
    HeartRate.find({ userId, from, to }),
  ])

  if (accel.length < 1800) {
    return
  }
  const counts = await calculateCounts({ accel, hr })

  if (!overWriteFrom) {
    await AccelCount.save(counts, userId)
  }
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
