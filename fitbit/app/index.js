import clock from 'clock'
import { me } from 'appbit'
import * as document from 'document'
import { peerSocket } from 'messaging'
import { HeartRateSensor } from 'heart-rate'
import { Accelerometer } from 'accelerometer'
import { memory } from 'system'
import calculateCounts from './counts'

const initialDate = Date.now()
clock.granularity = 'minutes'
me.appTimeoutEnabled = false // Disable timeout this keeps the app alive always.

peerSocket.addEventListener('open', (evt) => {
  console.log('Ready to send or receive messages')
})
peerSocket.onmessage = (evt) => {
  switch (evt.data.key) {
    case 'text':
    case 'background':
    case 'lastSync':
    case 'error':
      try {
        updateClockSettings(evt.data)
      } catch (e) {}
      break
    default:
      break
  }
}

let backlog = []
const sendData = async (payload) => {
  console.log(JSON.stringify(payload, null, 2))
  return
  try {
    if (backlog.length > 0) {
      console.log('Sending backlog', backlog)
      backlog.forEach((b) => {
        peerSocket.send(JSON.stringify(b))
      })
      backlog = []
    }
    peerSocket.send(JSON.stringify(payload))
  } catch (e) {
    console.log('Error sending data', e)
    backlog.push(payload)
  }
}

let time = new Date()
let secondsRemaining = (60 - time.getSeconds()) * 1000

setTimeout(() => {
  console.log('START COLLECTION', new Date())
  accel.start()
  hrm.start()
}, 0)

/*
  Clock
*/
let background = document.getElementById('background')
let label = document.getElementById('text')
let statusLabel = document.getElementById('status')
function zeroPad(i) {
  if (i < 10) {
    i = '0' + i
  }
  return i
}
function updateClock() {
  let today = new Date()
  let hours = today.getHours()
  let mins = zeroPad(today.getMinutes())

  label.text = `${hours}:${mins}`
}

function updateClockSettings({ key, newValue }) {
  if (key === 'background' && newValue) {
    let color = JSON.parse(newValue)
    console.log(`Setting background color: ${color}`)
    background.style.fill = color
  }
  if (key === 'text' && newValue) {
    let color = JSON.parse(newValue)
    console.log(`Setting background color: ${color}`)
    label.style.fill = color
  }
  if (key === 'lastSync' && newValue) {
    statusLabel.text = newValue
    statusLabel.style.fill = 'white'
  }
  if (key === 'error') {
    statusLabel.text = newValue ? newValue : 'error'
    statusLabel.style.fill = 'red'
  }
}

clock.ontick = () => updateClock()

/*
  Accel
*/
const ACCEL_FREQUENCY = 30
const ACCEL_LENGTH = 600
let initialAccReading
let accTimestamp
let accelDataX = new Float32Array(ACCEL_LENGTH)
let accelDataY = new Float32Array(ACCEL_LENGTH)
let accelDataZ = new Float32Array(ACCEL_LENGTH)
let accelIndex = 0

const accel = new Accelerometer({
  frequency: ACCEL_FREQUENCY,
  batch: ACCEL_FREQUENCY,
})
accel.addEventListener('reading', async () => {
  if (!initialAccReading) {
    initialAccReading = accel.readings.timestamp[0]
    accTimestamp =
      initialDate + (accel.readings.timestamp[0] - initialAccReading)
  }

  // we have a full minute of data, calculate counts and clear array
  console.log(
    'JS memory: ' +
      memory.js.used +
      '/' +
      memory.js.total +
      ', index:' +
      accelIndex
  )
  //  if (accelData.length >= 5400) {
  if (accelIndex >= ACCEL_LENGTH) {
    console.log(new Date())
    const acc = calculateCounts(accelDataX, accelDataY, accelDataZ)
    console.log(new Date())
    sendData({
      type: 'acc',
      timestamp: accTimestamp,
      value: acc,
    })
    accelIndex = 0
    accelDataX = new Float32Array(ACCEL_LENGTH)
    accelDataY = new Float32Array(ACCEL_LENGTH)
    accelDataZ = new Float32Array(ACCEL_LENGTH)

    accTimestamp =
      initialDate + (accel.readings.timestamp[0] - initialAccReading)
  }

  for (let index = 0; index < accel.readings.timestamp.length; index++) {
    accelDataX[accelIndex] = accel.readings.x[index] / 9.82
    accelDataY[accelIndex] = accel.readings.y[index] / 9.82
    accelDataZ[accelIndex] = accel.readings.z[index] / 9.82
    accelIndex++
  }
})

/*
  Counts
*/
const getCounts = (values) => {
  return values
}

/*
  HR 
*/

const HRM_FREQUENCY = 1
const HRM_BATCH = HRM_FREQUENCY * 60
let initialHrReading

const hrm = new HeartRateSensor({
  frequency: HRM_FREQUENCY,
  batch: HRM_BATCH,
})
hrm.addEventListener('reading', () => {
  if (!initialHrReading) initialHrReading = hrm.readings.timestamp[0]

  let timestamp = initialDate + (hrm.readings.timestamp[0] - initialHrReading)
  const heartrate =
    hrm.readings.heartRate.reduce((acc, curr) => acc + curr, 0) /
    hrm.readings.heartRate.length

  sendData({
    type: 'hr',
    timestamp,
    value: heartrate,
  })
})
