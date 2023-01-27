import { me as companion } from 'companion'
import * as messaging from 'messaging'
import { settingsStorage } from 'settings'

// const API_URL = 'https://sci-api.prod.appadem.in'
const API_URL = 'http://192.168.0.33:4000'
let userId
let lastSync

if (!companion.permissions.granted('run_background')) {
  console.warn("We're not allowed to access to run in the background!")
}

// Messaging
function sendVal(data) {
  switch (data.key) {
    case 'userId':
      if (data.newValue) {
        try {
          userId = JSON.parse(data.newValue).name
        } catch (e) {
          userId = data.newValue
        }
        console.log('set userId to', `"${userId}"`)
      }
      break
    case 'weight':
      if (data.newValue) {
        const weight = JSON.parse(data.newValue).name
        patchUser({ weight: weight })
      }
      break
    // info/error display on watch
    case 'lastSync':
    case 'error':
    // watch styles
    case 'text':
    case 'background':
      if (messaging.peerSocket.readyState === messaging.peerSocket.OPEN) {
        messaging.peerSocket.send(data)
      }
      break
    default:
      break
  }
}

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

const postRequestWithRetries = async (data, retries = 1) => {
  try {
    const body = JSON.stringify(data)
    const res = await fetch(`${API_URL}/users/${userId}/data`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    })
    if (res.status !== 200) {
      await wait(1000)
      if (retries > 0) return postData(data, retries - 1)
      throw new Error(`Error posting data: ${res.status}`)
    }
    // all good
    lastSync = new Date()
    sendVal({
      key: 'lastSync',
      newValue: `${lastSync.toLocaleDateString()} ${lastSync.toLocaleTimeString()}`,
    })
  } catch (e) {
    await wait(1000)
    if (retries > 0) return postData(data, retries - 1)
    throw e
  }
}

let backlog = []
async function postData(data) {
  // if we have something in the backlog try it first
  if (backlog.length > 0) {
    console.log('Sending backlog', backlog)
  }

  try {
    await postRequestWithRetries(data)
  } catch (e) {
    sendVal({
      key: 'error',
      newValue: e.message,
    })
    setSettings('error', e.toString())
    backlog.push(data)
  }
}

function patchUser(data) {
  const body = JSON.stringify(data)
  fetch(`${API_URL}/users/${userId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
    },
    body: body,
  })
    .then((res) => {
      if (res.status === 200) {
        console.log('patch weight success')
      }
    })
    .catch((e) => {
      console.log('patch weight error', e)
      setSettings('error', e.toString())
    })
}

messaging.peerSocket.addEventListener('open', (evt) => {
  console.log('companion messaging ready')
  restoreSettings()
})

let cache = {}
messaging.peerSocket.addEventListener('message', (evt) => {
  // if (!userId) {
  //   return
  // }
  const event = JSON.parse(evt.data)
  const minute = Math.round(event.timestamp / 60000) * 60000
  if (!cache[minute]) {
    cache[minute] = {}
  }
  cache[minute][event.type] = event.value

  if (cache[minute].acc && cache[minute].hr) {
    postData({
      t: minute,
      a: cache[minute].acc,
      hr: cache[minute].hr,
    })
    delete cache[minute]
  }
})

// Settings
settingsStorage.onchange = (evt) => {
  console.log('settings.onchange', evt.key, evt.newValue)
  let data = {
    key: evt.key,
    newValue: evt.newValue,
  }
  sendVal(data)
}

function restoreSettings() {
  for (let index = 0; index < settingsStorage.length; index++) {
    let key = settingsStorage.key(index)
    if (key) {
      let data = {
        key: key,
        newValue: settingsStorage.getItem(key),
      }
      sendVal(data)
    }
  }
}

function setSettings(key, value) {
  settingsStorage(key, value)
}
