import PushNotifications from 'node-pushnotifications'
import fs from 'fs'

let CERT_PATH = './dist/push/cert/cert.p8'
if (!fs.existsSync(CERT_PATH)) {
  CERT_PATH = './lib/push/cert/cert.p8'
}

const settings = {
  gcm: {
    id: process.env.GCM_KEY,
  },
  apn: {
    token: {
      key: fs.readFileSync(CERT_PATH),
      keyId: '8DLWUFMYJ3',
      teamId: '5KQ3D3FG5H',
    },
    production: process.env.NODE_ENV === 'production',
  },
}

const push = new PushNotifications(settings)

export type PushMessage = {
  title: string
  body: string
}

export const send = ({
  deviceId,
  message,
  action,
}: {
  deviceId: string
  message: PushMessage
  action?: string
}) => {
  const body: PushNotifications.Data = {
    title: message.title,
    body: message.body,
    topic: process.env.APN_TOPIC,
  }
  if (action) {
    body.action = action
    body.expiry = Math.floor(Date.now() / 1000) + 3600
  }

  return push.send([deviceId], body).catch(console.error)
}
