import clock from 'clock'
import { me } from 'appbit'
import * as document from 'document'
import { peerSocket } from 'messaging'
import { HeartRateSensor } from 'heart-rate'
import { Accelerometer } from 'accelerometer'
import { memory } from 'system'

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
}, secondsRemaining)

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
let initialAccReading
let accTimestamp
let accelData = []

const accel = new Accelerometer({
  frequency: ACCEL_FREQUENCY,
  batch: ACCEL_FREQUENCY,
})
accel.addEventListener('reading', () => {
  if (!initialAccReading) {
    initialAccReading = accel.readings.timestamp[0]
    accTimestamp =
      initialDate + (accel.readings.timestamp[0] - initialAccReading)
  }

  // we have a full minute of data, calculate counts and clear array
  if (accelData.length >= 5400) {
    const acc = calculateCounts(accelData)
    sendData({
      type: 'acc',
      timestamp: accTimestamp,
      value: acc,
    })
    accelData = []
    accTimestamp =
      initialDate + (accel.readings.timestamp[0] - initialAccReading)
  }

  for (let index = 0; index < accel.readings.timestamp.length; index++) {
    accelData.push(accel.readings.x[index])
    accelData.push(accel.readings.y[index])
    accelData.push(accel.readings.z[index])
  }
})

/*
  Counts
*/
const getCounts = (values) => {
  return values
}

const calculateCounts = (acc) => {
  const x = acc.reduce((a, b, i) => a + (i % 3 === 0 ? b : 0))
  const y = acc.reduce((a, b, i) => a + (i % 3 === 1 ? b : 0))
  const z = acc.reduce((a, b, i) => a + (i % 3 === 2 ? b : 0))
  const accVM = Math.sqrt(x * x + y * y + z * z)

  return accVM
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
