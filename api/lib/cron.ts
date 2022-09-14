import { activityForPeriod } from './routes/users/utils'
import moment from 'moment'
import * as redis from './adapters/redis'
import UserModel, { User } from './db/models/User'
import * as push from './push'
import AccelCount from './db/models/AccelCount'

const CronJob = require('cron').CronJob

const checkActivityAndSendMessage = async (user: User) => {
  const activity = await activityForPeriod({
    from: moment().subtract(1, 'hour').toDate(),
    to: new Date(),
    id: user.id,
  })

  const cacheKey = `${user.id}-activity-notification`
  const notification = await redis.get(cacheKey)
  if (activity.minutesInactive >= 60 && !notification) {
    const message: push.PushMessage = {
      title: 'Dags att rulla',
      body: `Du har varit inaktiv i ${activity.minutesInactive} minuter, dags att rulla lite.`,
    }
    await redis.set(cacheKey, message, 60 * 90)
    push.send({
      deviceId: user.deviceId,
      message,
    })
  }
}

const checkForDataAndSendMessage = async (user: User) => {
  const counts = await AccelCount.find({
    userId: user.id,
    from: moment().subtract(1, 'hour').toDate(),
    to: new Date(),
  })

  if (counts.length === 0) {
    const cacheKey = `${user.id}-data-notification`
    const notification = await redis.get(cacheKey)
    if (!notification) {
      const message = {
        title: 'Ingen data',
        body: `Din klocka har inte skickat någon data den senaste timmen, se till att klock appen och Fitbit är igång på din mobil.`,
      }
      await redis.set(cacheKey, message, 60 * 60 * 5)
      push.send({
        deviceId: user.deviceId,
        message,
      })
    }
  }
  return counts.length > 0
}

const sendMessages = async (user: User) => {
  const hasData = await checkForDataAndSendMessage(user)
  if (hasData) {
    checkActivityAndSendMessage(user)
  }
}

// run every other minute during the day
const job = new CronJob('0 */2 8-19 * * *', async () => {
  const users = await UserModel.getAll()

  await Promise.all(users.filter((u) => u.deviceId).map(sendMessages))
})

job.start()
