import { HeartRateSensor } from 'heart-rate'

const HRM_FREQUENCY = 1
const HRM_BATCH = HRM_FREQUENCY * 60
const initialDate = Date.now()

export default (callback) => {
  if (!HeartRateSensor) return
  const hrm = new HeartRateSensor({
    frequency: HRM_FREQUENCY,
    batch: HRM_BATCH,
  })
  hrm.addEventListener('reading', () => {
    if (!initialReadingOffset) initialReadingOffset = hrm.readings.timestamp[0]

    let timestamp =
      initialDate + (hrm.readings.timestamp[0] - initialReadingOffset)
    const heartrate =
      hrm.readings.heartRate.reduce((acc, curr) => acc + curr, 0) /
      hrm.readings.heartRate.length

    callback(timestamp, heartrate)
  })

  hrm.start()
}
