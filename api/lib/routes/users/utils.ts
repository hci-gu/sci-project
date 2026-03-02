import * as redis from '../../adapters/redis.js'
import AccelCountModel from '../../db/models/AccelCount.js'

import { calculateCounts } from '../../adapters/counts.js'

import * as utils from '../../utils/index.js'
import { type AccelData } from '../../db/models/Accel.js'
import { type HeartRateData } from '../../db/models/HeartRate.js'

export const countsCacheKey = (userId: string, minute: string) =>
  `${userId}-${minute}`

export const checkAndSaveCounts = async (
  userId: string,
  accelDataPoints: AccelData[],
  hrDataPoints: HeartRateData[]
) => {
  const accMinutes = utils.group(accelDataPoints, (d) => utils.getMinute(d.t))
  const hrMinutes = utils.group(hrDataPoints, (d) => utils.getMinute(d.t))

  const minuteEntries = Object.entries(accMinutes).sort(
    (a, b) => new Date(a[1][0].t).getTime() - new Date(b[1][0].t).getTime()
  )

  for (const [minute, minuteAccel] of minuteEntries) {
    const cacheKey = countsCacheKey(userId, minute)
    let cached = await redis.get(cacheKey)
    if (!cached) cached = { hr: [], accel: [] }

    const accel = [...cached.accel, ...minuteAccel]
    const hr = [...cached.hr, ...(hrMinutes[minute] ? hrMinutes[minute] : [])]
    if (accel.length < 1800) {
      await redis.set(cacheKey, {
        accel,
        hr,
      })
      continue
    }

    const counts = await calculateCounts({ accel, hr })
    if (counts.length > 0) {
      await AccelCountModel.save(counts, userId)
      // Minute bucket is complete and persisted; clear cache to avoid re-saving.
      await redis.del(cacheKey)
      continue
    }

    await redis.set(cacheKey, {
      accel,
      hr,
    })
  }
}
