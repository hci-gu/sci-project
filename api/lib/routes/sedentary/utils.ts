import moment from 'moment'
import { SEDENTARY_THRESHOLD } from '../../constants.ts'
import { AccelCount } from '../../db/classes.ts'
import AccelCountModel from '../../db/models/AccelCount.ts'

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
  const lastActiveIndex = counts
    .reverse()
    .findIndex(({ a }) => a > SEDENTARY_THRESHOLD)

  const minutesInactive = moment(to).diff(
    lastActiveIndex >= 0 ? counts[lastActiveIndex].t : from,
    'minutes'
  )

  // average inactive duration
  const inactiveIntervals = counts
    .reduce<AccelCount[][]>(
      (intervals, count) => {
        if (count.a < SEDENTARY_THRESHOLD) {
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
