import clock from 'clock'
import { me } from "appbit";
import { Accelerometer } from "accelerometer";
import { display } from "display";
import * as document from "document";
import * as messaging from "messaging";
import { outbox } from "file-transfer";
import { HeartRateSensor } from "heart-rate";

const accelLabel = document.getElementById("accel-label");
const accelData = document.getElementById("accel-data");

const hrmLabel = document.getElementById("hrm-label");
const hrmData = document.getElementById("hrm-data");

const ACCEL_FREQUENCY = 30
const ACCEL_BATCH = 10
const HRM_FREQUENCY = 1
const HRM_BATCH = HRM_FREQUENCY * 10

clock.granularity = "minutes"
me.appTimeoutEnabled = false; // Disable timeout this keeps the app alive always.

messaging.peerSocket.addEventListener("open", (evt) => {
  console.log("Ready to send or receive messages");
});
messaging.peerSocket.onmessage = evt => {
  switch(evt.data.key) {
    case 'text':
    case 'background':
    case 'lastSync':
    case 'error':
       try {
          updateClockSettings(evt.data) 
       } catch(e) {}
      break
    default:
      break
  }
}
const initialDate = Date.now()
let initialReadingOffset

console.log('STARTING', new Date(initialDate))
var time = new Date(),
    secondsRemaining = (60 - time.getSeconds()) * 1000;

let accel
let hrm
setTimeout(() => {
  console.log('START COLLECTION', new Date())
  accel.start();
  hrm.start();
}, secondsRemaining);

const sendData = async (payload) => {
  messaging.peerSocket.send(JSON.stringify(payload));
}

if (Accelerometer) {
  accel = new Accelerometer({ frequency: ACCEL_FREQUENCY, batch: ACCEL_BATCH });
  accel.addEventListener("reading", () => {
    if (!initialReadingOffset) initialReadingOffset = accel.readings.timestamp[0]
    let accelData = []
    let start = initialDate + (accel.readings.timestamp[0] - initialReadingOffset)
    
    for (let index = 0; index < accel.readings.timestamp.length; index++) {
      let t = initialDate + (accel.readings.timestamp[index] - initialReadingOffset)
      accelData.push([t, accel.readings.x[index], accel.readings.y[index], accel.readings.z[index]])
    }
    sendData({
      type: 'accel',
      data: accelData
    })
  });
} else {
  accelLabel.style.display = "none";
  accelData.style.display = "none";
}

if (HeartRateSensor) {
  hrm = new HeartRateSensor({ frequency: HRM_FREQUENCY, batch: HRM_BATCH });
  hrm.addEventListener("reading", () => {
    if (!initialReadingOffset) initialReadingOffset = accel.readings.timestamp[0]
    
    let hrmData = []
    for (let index = 0; index < hrm.readings.timestamp.length; index++) {
      let t = initialDate + (hrm.readings.timestamp[index] - initialReadingOffset)
      hrmData.push([t, hrm.readings.heartRate[index]])
    }
    sendData({
      type: 'heartRate',
      data: hrmData
    })
  });
} else {
  hrmLabel.style.display = "none";
  hrmData.style.display = "none";
}

/*
Clock
*/
let background = document.getElementById("background");
let label = document.getElementById("text")
let statusLabel = document.getElementById("status")
function zeroPad(i) {
  if (i < 10) {
    i = "0" + i;
  }
  return i;
}
function updateClock() {
  let today = new Date()
  let hours = today.getHours()
  let mins = zeroPad(today.getMinutes())
  
  label.text = `${hours}:${mins}`
}

function updateClockSettings({ key, newValue }) {
   if (key === 'background' && newValue) {
     let color = JSON.parse(newValue);
     console.log(`Setting background color: ${color}`);
     background.style.fill = color;
   }
   if (key === 'text' && newValue) {
     let color = JSON.parse(newValue);
     console.log(`Setting background color: ${color}`);
     label.style.fill = color;
   }
   if (key === 'lastSync' && newValue) {
     statusLabel.text = newValue;
     statusLabel.style.fill = 'white';
   }
   if (key === 'error') {
     statusLabel.text = newValue ? newValue : 'error';
     statusLabel.style.fill = 'red';
   }
}

clock.ontick = () => updateClock()