import { type AccelData } from '../db/models/Accel.ts'
import { type HeartRateData } from '../db/models/HeartRate.ts'

enum FitbitDataType {
  HeartRate = 'heartRate',
  Accel = 'accel',
}

type FitbitDataBatch = {
  type: FitbitDataType
  data: FitbitHeartRate[] | FitbitAccel[]
}

type FitbitHeartRate = [number, number]
type FitbitAccel = [number, number, number, number]

const handleData = (batches: FitbitDataBatch[]) => {
  let accelDataPoints: AccelData[] = []
  let hrDataPoints: HeartRateData[] = []
  batches.forEach(({ type, data }) => {
    if (type === FitbitDataType.HeartRate) {
      hrDataPoints = [
        ...hrDataPoints,
        ...(data as FitbitHeartRate[]).map(([t, hr]) => ({
          t: new Date(t),
          hr,
        })),
      ]
    } else if (type === FitbitDataType.Accel) {
      accelDataPoints = [
        ...accelDataPoints,
        ...(data as FitbitAccel[]).map(([t, x, y, z]) => ({
          t: new Date(t),
          x,
          y,
          z,
        })),
      ]
    }
  })

  return { accelDataPoints, hrDataPoints }
}

export default handleData
