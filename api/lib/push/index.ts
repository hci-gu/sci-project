import PushNotifications from 'node-pushnotifications'
import fs from 'fs'

const settings = {
  gcm: {
    id: process.env.GCM_KEY,
  },
  apn: {
    token: {
      key: fs.readFileSync('./lib/push/cert/cert.p8'),
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
}: {
  deviceId: string
  message: PushMessage
}) => {
  return push
    .send([deviceId], {
      title: message.title,
      body: message.body,
      topic: process.env.APN_TOPIC,
    })
    .then((res) => console.info(JSON.stringify(res, null, 2)))
    .catch(console.error)
}
