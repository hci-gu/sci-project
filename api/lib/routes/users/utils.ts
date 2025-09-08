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
