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
let timeLabel = document.getElementById('time')
let dateLabel = document.getElementById('date')
let statusLabel = document.getElementById('status')
function zeroPad(i) {
  if (i < 10) {
    i = '0' + i
  }
  return i
}
const weekDays = ['Sön', 'Mån', 'Tis', 'Ons', 'Tor', 'Fre', 'Lör']
const monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Maj',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Okt',
  'Nov',
  'Dec',
]
function updateClock() {
  let today = new Date()
  let hours = today.getHours()
  let mins = zeroPad(today.getMinutes())

  timeLabel.text = `${hours}:${mins}`

  let day = today.getDate()
  let month = today.getMonth() + 1
  let weekDay = today.getDay()
  dateLabel.text = `${weekDays[weekDay]} ${day} ${monthNames[month - 1]}`
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
const ACCEL_LENGTH = 1800
let initialAccReading
let accTimestamp
let accelDataX = new Float32Array(ACCEL_LENGTH)
let accelDataY = new Float32Array(ACCEL_LENGTH)
let accelDataZ = new Float32Array(ACCEL_LENGTH)
let accelIndex = 0
const accel = new Accelerometer({
  frequency: ACCEL_FREQUENCY,
  batch: ACCEL_FREQUENCY * 20,
})
accel.addEventListener('reading', async () => {
  if (!initialAccReading) {
    initialAccReading = accel.readings.timestamp[0]
  }
  if (accelIndex === 0) {
    accTimestamp =
      initialDate + (accel.readings.timestamp[0] - initialAccReading)
  }

  for (let index = 0; index < accel.readings.timestamp.length; index++) {
    accelDataX[accelIndex] = accel.readings.x[index] / 9.82
    accelDataY[accelIndex] = accel.readings.y[index] / 9.82
    accelDataZ[accelIndex] = accel.readings.z[index] / 9.82
    accelIndex++
  }
  if (accelIndex >= ACCEL_LENGTH) {
    const acc = calculateCounts(accelDataX, accelDataY, accelDataZ).then(
      (acc) => {
        if (avgHr == 0) return
        sendData({
          type: 'count',
          timestamp: accTimestamp,
          acc: acc,
          hr: avgHr,
        })
        accelIndex = 0
        accelDataX = new Float32Array(ACCEL_LENGTH)
        accelDataY = new Float32Array(ACCEL_LENGTH)
        accelDataZ = new Float32Array(ACCEL_LENGTH)
      }
    )
  }
})

/*
  HR 
*/
const HRM_FREQUENCY = 1
const HRM_BATCH = HRM_FREQUENCY * 5
let accumHr = 0
let avgHr = 0
let hrReadings = 0

const hrm = new HeartRateSensor({
  frequency: HRM_FREQUENCY,
  batch: HRM_BATCH,
})
hrm.addEventListener('reading', () => {
  for (let i = 0; i < hrm.readings.timestamp.length; i++) {
    accumHr += hrm.readings.heartRate[i]
    hrReadings++
  }
  if (hrReadings >= 60) {
    avgHr = accumHr / hrReadings
    accumHr = 0
    hrReadings = 0
  }
})
