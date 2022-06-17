const PushNotifications = require('node-pushnotifications')
const fs = require('fs')

const settings = {
  gcm: {
    // id: process.env.GCM_KEY,
  },
  apn: {
    token: {
      key: fs.readFileSync('./lib/push/cert/cert.p8'),
      keyId: '8DLWUFMYJ3',
      teamId: '5KQ3D3FG5H',
    },
    production: false,
  },
}

const push = new PushNotifications(settings)

module.exports = {
  send: ({ deviceId, message }) => {
    console.log({
      title: message.title,
      body: message.body,
      topic: process.env.APN_TOPIC,
    })
    return push
      .send([deviceId], {
        title: message.title,
        body: message.body,
        topic: process.env.APN_TOPIC,
      })
      .then((res) => console.info(JSON.stringify(res, null, 2)))
      .catch(console.error)
  },
}
