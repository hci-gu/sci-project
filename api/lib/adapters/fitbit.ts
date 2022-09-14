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

type HeartRate = {
  t: number
  hr: number
}
type Accel = {
  t: number
  x: number
  y: number
  z: number
}

const handleData = (batches: FitbitDataBatch[]) => {
  let accelDataPoints: Accel[] = []
  let hrDataPoints: HeartRate[] = []
  batches.forEach(({ type, data }) => {
    if (type === FitbitDataType.HeartRate) {
      hrDataPoints = [
        ...hrDataPoints,
        ...(data as FitbitHeartRate[]).map(([t, hr]) => ({ t, hr })),
      ]
    } else if (type === FitbitDataType.Accel) {
      accelDataPoints = [
        ...accelDataPoints,
        ...(data as FitbitAccel[]).map(([t, x, y, z]) => ({ t, x, y, z })),
      ]
    }
  })

  return { accelDataPoints, hrDataPoints }
}

export default handleData
