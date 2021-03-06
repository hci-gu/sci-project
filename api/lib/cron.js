const { getUsers, activityForPeriod } = require('./routes/users/utils')
const moment = require('moment')
const redis = require('./adapters/redis')
const push = require('./push')
const { AccelCount } = require('./db/models')

const CronJob = require('cron').CronJob

const checkActivityAndSendMessage = async (user) => {
  const activity = await activityForPeriod({
    from: moment().subtract(1, 'hour').toDate(),
    to: new Date(),
    id: user.id,
  })

  const cacheKey = `${user.id}-activity-notification`
  const notification = await redis.get(cacheKey)
  if (activity.minutesInactive > 45 && !notification) {
    const message = {
      title: 'Dags att rulla',
      body: `Du har varit inaktiv i ${activity.minutesInactive} minuter, dags att rulla lite.`,
    }
    await redis.set(cacheKey, message, 60 * 10)
    push.send({
      deviceId: user.deviceId,
      message,
    })
  }
}

const checkForDataAndSendMessage = async (user) => {
  const counts = await AccelCount.find({
    userId: user.id,
    from: moment().subtract(10, 'minutes').toDate(),
    to: new Date(),
  })

  console.log('checkForDataAndSendMessage', counts.length)
  if (counts.length === 0) {
    const cacheKey = `${user.id}-data-notification`
    const notification = await redis.get(cacheKey)
    if (!notification) {
      const message = {
        title: 'Ingen data',
        body: `Din klocka har inte skickat någon data de senaste 10 minuterna, se till att klock appen och Fitbit är igång på din mobil.`,
      }
      await redis.set(cacheKey, message, 60 * 60)
      push.send({
        deviceId: user.deviceId,
        message,
      })
    }
  }
  return counts.length === 0
}

const sendMessages = async (user) => {
  const hasData = await checkForDataAndSendMessage(user)
  if (hasData) {
    checkActivityAndSendMessage(user)
  }
}

// run every other minute
const job = new CronJob('0 */2 * * * *', async () => {
  console.log(new Date())
  const users = await getUsers()

  await Promise.all(users.filter((u) => u.deviceId).map(sendMessages))
})

job.start()
