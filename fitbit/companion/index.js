import { me as companion } from 'companion'
import * as messaging from 'messaging'
import { settingsStorage } from 'settings'

const API_URL = 'https://sci-api.prod.appadem.in'
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
      if (messaging.peerSocket.readyState === messaging.peerSocket.OPEN) {
        messaging.peerSocket.send(data)
      }
      break
    case 'colorScheme':
      if (messaging.peerSocket.readyState === messaging.peerSocket.OPEN) {
        const value = JSON.parse(data.newValue).values[0].name
        messaging.peerSocket.send({
          key: 'colorScheme',
          newValue: value,
        })
      }
      break
    default:
      break
  }
}

let backlog = []
function postData(data, retries = 1) {
  if (retries <= 0) {
    backlog = [...backlog, ...data]
    return
  }

  const body = JSON.stringify([...backlog, ...data])
  fetch(`${API_URL}/counts/${userId}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: body,
  })
    .then((res) => {
      if (res.status === 200) {
        backlog = []
        lastSync = new Date()
        sendVal({
          key: 'lastSync',
          newValue: `${lastSync.toLocaleTimeString().slice(0, 5)}`,
        })
      } else {
        setTimeout(() => {
          postData(data, retries - 1)
        }, 1000)
        sendVal({
          key: 'error',
          newValue: 'error, statusCode: ' + res.status,
        })
      }
    })
    .catch((e) => {
      setTimeout(() => {
        postData(data, retries - 1)
      }, 1000)
      sendVal({
        key: 'error',
        newValue: e.message,
      })
      setSettings('error', e.toString())
    })
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

messaging.peerSocket.addEventListener('message', (evt) => {
  if (!userId) {
    return
  }
  const events = JSON.parse(evt.data)
  postData(events)
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
