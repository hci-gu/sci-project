import { activityForPeriod } from './routes/sedentary/utils'
import moment from 'moment-timezone'
import * as redis from './adapters/redis'
import UserModel from './db/models/User'
import * as push from './push'
import AccelCount from './db/models/AccelCount'
import { NotificationSettings, User } from './db/classes'
import JournalModel from './db/models/Journal'

const CronJob = require('cron').CronJob

enum MessageType {
  Activity = 'activity',
  Data = 'data',
  Journal = 'journal',
}
const cacheKeyForType = (type: MessageType, user: User) =>
  `${user.id}-${type}-notification`

const checkActivityAndSendMessage = async (user: User) => {
  const activity = await activityForPeriod({
    from: moment().subtract(1, 'hour').toDate(),
    to: new Date(),
    id: user.id,
  })

  const cacheKey = cacheKeyForType(MessageType.Activity, user)

  const notification = await redis.get(cacheKey)
  if (activity.minutesInactive >= 55 && !notification) {
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

  if (counts.length === 0 && user.notificationSettings.data) {
    const cacheKey = cacheKeyForType(MessageType.Data, user)
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
  if (hasData && user.notificationSettings.activity) {
    checkActivityAndSendMessage(user)
  }
}

// run every other minute during the day
const job = new CronJob('0 */2 8-19 * * *', async () => {
  if (!UserModel) return
  const users = await UserModel.getAll()

  await Promise.all(users.filter((u) => u.deviceId).map(sendMessages))
})

const sendJournalMessages = async (user: User) => {
  const cacheKey = cacheKeyForType(MessageType.Journal, user)

  const notification = await redis.get(cacheKey)
  if (notification) {
    // dont send one again
    return
  }

  const lastEntry = await JournalModel.getLastEntry(user.id)
  const tz: string = 'Europe/Stockholm'

  if (lastEntry && moment.tz(lastEntry.t, tz).isSame(moment(), 'day')) {
    // no need to send a message
    return
  }

  let sendPush = false
  if (lastEntry) {
    const timeWhenLastAnswered = moment.tz(lastEntry.t, tz)

    // if current hour is same ast last answered hour
    if (timeWhenLastAnswered.hour() === moment().hour()) {
      sendPush = true
    }
  } else if (moment().hour() === 12) {
    // if it's 12:00 and user never answered before, send the notification.
    sendPush = true
  }

  if (sendPush) {
    const message = {
      title: 'Hur känner du dig idag?',
      body: `Här kommer en påminnelse att uppdatera din journal.`,
    }
    await redis.set(cacheKey, message, 60 * 60 * 12)
    push.send({
      deviceId: user.deviceId,
      message,
    })
  }
}

const journalJob = new CronJob('0 0 * * * *', async () => {
  if (!UserModel) return
  const users = await UserModel.getAll()

  await Promise.all(
    users
      .filter((u) => u.deviceId && u.notificationSettings.journal)
      .map(sendJournalMessages)
  )
})

job.start()
journalJob.start()
