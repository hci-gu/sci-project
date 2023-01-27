import { Accelerometer } from 'accelerometer'
import { memory } from 'system'
import calculateCounts from './counts'
const ACCEL_FREQUENCY = 30

const initialDate = Date.now()

let initialReadingOffset
let accelData = []

export default (callback) => {
  if (!Accelerometer) return
  const accel = new Accelerometer({
    frequency: ACCEL_FREQUENCY,
    batch: ACCEL_FREQUENCY,
  })
  accel.addEventListener('reading', () => {
    if (!initialReadingOffset)
      initialReadingOffset = accel.readings.timestamp[0]
    console.log('JS memory: ' + memory.js.used + '/' + memory.js.total)
    console.log(accelData.length)

    // we have a full minute of data, calculate counts and clear array
    if (accelData.length >= 5400) {
      const acc = calculateCounts(accelData)
      callback(start, acc)
      accelData = []
      let start =
        initialDate + (accel.readings.timestamp[0] - initialReadingOffset)
    }

    for (let index = 0; index < accel.readings.timestamp.length; index++) {
      accelData.push(accel.readings.x[index])
      accelData.push(accel.readings.y[index])
      accelData.push(accel.readings.z[index])
    }
  })

  accel.start()
}
