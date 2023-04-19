import clock from 'clock'
import { me } from 'appbit'
import * as document from 'document'
import { peerSocket } from 'messaging'
import { HeartRateSensor } from 'heart-rate'
import { Accelerometer } from 'accelerometer'
import calculateCounts from './counts'

const initialDate = Date.now()
clock.granularity = 'minutes'
me.appTimeoutEnabled = false // Disable timeout this keeps the app alive always.

peerSocket.addEventListener('open', (evt) => {
  console.log('Ready to send or receive messages')
})
peerSocket.onmessage = (evt) => {
  switch (evt.data.key) {
    case 'colorScheme':
    case 'lastSync':
    case 'error':
      try {
        updateClockSettings(evt.data)
      } catch (e) {
        console.log(e)
      }
      break
    default:
      break
  }
}

let backlog = []
const sendData = async (payload) => {
  let dataToSend =
    backlog.length > 0
      ? [...backlog.splice(0, Math.min(backlog.length, 5)), payload]
      : [payload]

  try {
    peerSocket.send(JSON.stringify(dataToSend))
  } catch (e) {
    console.log('Error sending data', e)
    backlog = [...backlog, ...dataToSend]
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
  ClockFace
*/
let background = document.getElementById('background')
let timeLabel = document.getElementById('time')
let dateLabel = document.getElementById('date')
let statusLabel = document.getElementById('statusLabel')
let statusIcon = document.getElementById('statusIcon')
let hrLabel = document.getElementById('hrLabel')
let stillLabel = document.getElementById('stillLabel')
let stillIcon = document.getElementById('stillIcon')
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
  let month = today.getMonth()
  let weekDay = today.getDay()
  dateLabel.text = `${weekDays[weekDay]} ${day} ${monthNames[month]}`
}

let darkMode = true
function updateClockSettings({ key, newValue }) {
  if (key === 'colorScheme') {
    console.log(`set colorScheme: ${newValue}`)
    darkMode = newValue == 'Dark' || newValue == 'Dark mono'
    if (darkMode) {
      background.style.fill = 'black'
      timeLabel.style.fill = '#D5454F'
      dateLabel.style.fill = 'white'
      hrLabel.style.fill = 'white'
      statusLabel.style.fill = 'white'
      stillLabel.style.fill = 'white'
      stillIcon.style.fill = 'white'
    } else {
      background.style.fill = 'white'
      timeLabel.style.fill = '#D5454F'
      dateLabel.style.fill = '#333333'
      hrLabel.style.fill = '#333333'
      statusLabel.style.fill = '#333333'
      stillLabel.style.fill = '#333333'
      stillIcon.style.fill = '#333333'
    }
    if (newValue === 'Dark mono') {
      timeLabel.style.fill = 'white'
    } else if (newValue === 'Light mono') {
      timeLabel.style.fill = '#333333'
    }
  }
  if (key === 'lastSync' && newValue) {
    statusLabel.text = newValue
    statusLabel.style.fill = darkMode ? 'white' : '#333333'
    statusLabel.x = 32
    statusIcon.style.fill = '#118A2E'
    statusIcon.x = 0
  }
  if (key === 'error') {
    statusLabel.text = newValue ? newValue : 'error'
    statusLabel.style.fill = 'red'
    statusLabel.x = 64
    statusIcon.style.fill = 'red'
    statusIcon.x = -80
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
let stillMinutes = 0
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
          t: accTimestamp,
          a: acc,
          hr: avgHr,
        })
        accelIndex = 0
        accelDataX = new Float32Array(ACCEL_LENGTH)
        accelDataY = new Float32Array(ACCEL_LENGTH)
        accelDataZ = new Float32Array(ACCEL_LENGTH)

        // update stillLabel
        if (acc > 2700) {
          stillMinutes = 0
          stillIcon.href = 'img/moving.png'
          stillIcon.x = 32
          stillLabel.text = ''
        } else {
          stillIcon.href = 'img/still.png'
          stillIcon.x = 0
          stillMinutes++
          stillLabel.text = stillMinutes + ' m'
        }
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
    hrLabel.text = avgHr.toFixed(0)
    accumHr = 0
    hrReadings = 0
  }
})
