import { activityForPeriod } from './routes/sedentary/utils.js'
import moment from 'moment-timezone'
import * as redis from './adapters/redis.js'
import UserModel from './db/models/User.js'
import * as push from './push/index.js'
import AccelCount from './db/models/AccelCount.js'
import { Goal, User } from './db/classes.js'
import JournalModel from './db/models/Journal.js'
import GoalModel from './db/models/Goal.js'
import NotificationEventModel from './db/models/NotificationEvent.js'
import { getGoalInfo } from './routes/goals/utils.js'
import { getCurrentPressureUlcers } from './routes/journal/utils.js'
import { JournalType } from './constants.js'
import { CronJob } from 'cron'

enum MessageType {
  Activity = 'activity',
  Data = 'data',
  Journal = 'journal',
  Goal = 'goal',
  PainSmell = 'pain-smell',
  UtiStatus = 'uti-status',
  AbPressureRelease = 'ab-pressure-release',
  AbPainLevel = 'ab-pain-level',
}
const cacheKeyForType = (type: MessageType, user: User) =>
  `${user.id}-${type}-notification`

const sendNotificationAndLog = async ({
  user,
  message,
  reason,
  action,
}: {
  user: User
  message: push.PushMessage
  reason: string
  action?: string
}) => {
  await push.send({
    deviceId: user.deviceId,
    message,
    action,
  })

  try {
    await NotificationEventModel.save({
      title: message.title,
      body: message.body,
      timestamp: new Date(),
      userId: user.id,
      reason,
    })
  } catch (error) {
    console.error('Failed to store notification event', error)
  }
}

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
    await sendNotificationAndLog({
      user,
      message,
      reason: MessageType.Activity,
    })
  }
}

const checkForDataAndSendMessage = async (user: User) => {
  // if the user has never sent data, don't send a message they may not have a watch.
  const hasEverSentData = await AccelCount.hasData(user.id)
  if (!hasEverSentData) {
    return false
  }

  const counts = await AccelCount.find({
    userId: user.id,
    from: moment().subtract(6, 'hour').toDate(),
    to: new Date(),
  })

  if (counts.length === 0 && user.notificationSettings.data) {
    const cacheKey = cacheKeyForType(MessageType.Data, user)
    const notification = await redis.get(cacheKey)
    if (!notification) {
      const message: push.PushMessage = {
        title: 'Ingen data',
        body: `Du har inte synkat data den senaste tiden, kom ihåg att öppna appen och synka så att du får påminnelser och kan följa din aktivitet!`,
      }
      await redis.set(cacheKey, message, 60 * 60 * 5)
      await sendNotificationAndLog({
        user,
        message,
        reason: MessageType.Data,
      })
    }
  }
  return counts.length > 0
}

const sendPressureReleaseReminder = async (user: User, goal: Goal) => {
  const userHasData = await AccelCount.hasData(user.id)

  if (userHasData) {
    const activity = await activityForPeriod({
      from: moment().subtract(10, 'minutes').toDate(),
      to: new Date(),
      id: user.id,
    })
    if (activity.minutesInactive <= 5) {
      // user has been active in the last 5 minutes, no need to send a reminder
      return
    }
  }

  const cacheKey =
    cacheKeyForType(MessageType.Goal, user) + '-' + goal.journalType
  const notification = await redis.get(cacheKey)
  if (!notification) {
    const message = {
      title: 'Påminnelse att tryckavlasta',
      body: `Nu är det dags att tryckavlasta!`,
    }
    await redis.set(cacheKey, message, 60 * 45)
    await sendNotificationAndLog({
      user,
      message,
      reason: `${MessageType.Goal}:${goal.journalType}`,
      action: 'create-journal?type=' + goal.journalType,
    })
  }
}

const sendBladderEmptyingReminder = async (user: User, goal: Goal) => {
  const cacheKey =
    cacheKeyForType(MessageType.Goal, user) + '-' + goal.journalType
  const notification = await redis.get(cacheKey)
  if (!notification) {
    const message = {
      title: 'Påminnelse för blåstömning',
      body: `Nu är det dags för blåstömning`,
    }
    await redis.set(cacheKey, message, 60 * 45)
    await sendNotificationAndLog({
      user,
      message,
      reason: `${MessageType.Goal}:${goal.journalType}`,
      action: 'create-journal?type=' + goal.journalType,
    })
  }
}

const fetchGoalsAndCheckReminders = async (user: User) => {
  const goals = await GoalModel.find({ userId: user.id })

  for (const goal of goals) {
    const goalInfo = await getGoalInfo(user.id, goal)

    if (goalInfo.reminder && moment(goalInfo.reminder).isBefore(moment())) {
      switch (goal.journalType) {
        case JournalType.pressureRelease:
          await sendPressureReleaseReminder(user, goal)
          break
        case JournalType.bladderEmptying:
          await sendBladderEmptyingReminder(user, goal)
          break
        default:
          break
      }
    }
  }
}

const sendMessages = async (user: User) => {
  const hasData = await checkForDataAndSendMessage(user)
  if (hasData && user.notificationSettings.activity) {
    await checkActivityAndSendMessage(user)
  }

  await fetchGoalsAndCheckReminders(user)
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
    const message: push.PushMessage = {
      title: 'Hur känner du dig idag?',
      body: `Här kommer en påminnelse att uppdatera din loggbok.`,
    }
    await redis.set(cacheKey, message, 60 * 60 * 12)
    await sendNotificationAndLog({
      user,
      message,
      reason: MessageType.Journal,
    })
  }
}

const sendPainAndSmellReminder = async (user: User) => {
  const cacheKey = cacheKeyForType(MessageType.PainSmell, user)
  const notification = await redis.get(cacheKey)
  if (notification) {
    return
  }

  const message: push.PushMessage = {
    title: 'Påminnelse om loggboken',
    body: 'Kom ihåg att rapportera smärta och/eller lukt.',
  }

  await redis.set(cacheKey, message, 60 * 60)
  await sendNotificationAndLog({
    user,
    message,
    reason: MessageType.PainSmell,
  })
}

const sendUtiStatusReminder = async (user: User) => {
  const cacheKey = cacheKeyForType(MessageType.UtiStatus, user)
  const notification = await redis.get(cacheKey)
  if (notification) {
    return
  }

  const message: push.PushMessage = {
    title: 'Påminnelse om UVI-status',
    body: 'Kom ihåg att uppdatera status för UVI.',
  }

  await redis.set(cacheKey, message, 60 * 60)
  await sendNotificationAndLog({
    user,
    message,
    reason: MessageType.UtiStatus,
    action: 'create-journal?type=' + JournalType.urinaryTractInfection,
  })
}

const hasJournalEntryInLastHour = async (userId: string, type: JournalType) => {
  const entries = await JournalModel.find(
    {
      userId,
      from: moment().subtract(1, 'hour').toDate(),
      to: new Date(),
    },
    {
      type,
    }
  )
  return entries.length > 0
}

const sendAbPressureReleaseReminder = async (
  user: User,
  hasCurrentPressureUlcer: boolean
) => {
  const cacheKey = cacheKeyForType(MessageType.AbPressureRelease, user)
  const notification = await redis.get(cacheKey)
  if (notification) {
    return
  }

  const message: push.PushMessage = hasCurrentPressureUlcer
    ? {
        title: 'Längre tryckavlastning rekommenderas',
        body: 'Du har ett aktivt trycksår. Gör en längre tryckavlastning nu.',
      }
    : {
        title: 'Påminnelse att tryckavlasta',
        body: 'Det är dags att tryckavlasta.',
      }

  await redis.set(cacheKey, message, 60 * 55)
  await sendNotificationAndLog({
    user,
    message,
    reason: hasCurrentPressureUlcer
      ? `${MessageType.AbPressureRelease}:pressure-ulcer`
      : MessageType.AbPressureRelease,
    action: 'create-journal?type=' + JournalType.pressureRelease,
  })
}

const sendAbPainLevelReminder = async (user: User) => {
  const cacheKey = cacheKeyForType(MessageType.AbPainLevel, user)
  const notification = await redis.get(cacheKey)
  if (notification) {
    return
  }

  const message: push.PushMessage = {
    title: 'Påminnelse om smärtnivå',
    body: 'Kom ihåg att rapportera din smärtnivå.',
  }

  await redis.set(cacheKey, message, 60 * 55)
  await sendNotificationAndLog({
    user,
    message,
    reason: MessageType.AbPainLevel,
    action: 'create-journal?type=' + JournalType.painLevel,
  })
}

const sendAbTestRemindersForUser = async (user: User) => {
  if (user.testType !== 'B') {
    return
  }

  const currentHour = moment().hour()

  const shouldSendPainReminder = [9, 14, 19].includes(currentHour)
  if (shouldSendPainReminder) {
    const hasRecentPainLevel = await hasJournalEntryInLastHour(
      user.id,
      JournalType.painLevel
    )
    if (!hasRecentPainLevel) {
      await sendAbPainLevelReminder(user)
    }
  }

  const goals = await GoalModel.find({ userId: user.id })
  const hasPressureReleaseGoal = goals.some(
    (goal) => goal.journalType === JournalType.pressureRelease
  )
  if (hasPressureReleaseGoal) {
    return
  }

  const currentPressureUlcers = await getCurrentPressureUlcers(
    user.id,
    new Date()
  )
  const hasCurrentPressureUlcer = currentPressureUlcers.length > 0

  const shouldSendPressureReleaseReminder = hasCurrentPressureUlcer
    ? currentHour >= 10 && currentHour <= 20
    : [10, 14, 19].includes(currentHour)

  if (shouldSendPressureReleaseReminder) {
    const hasRecentPressureRelease = await hasJournalEntryInLastHour(
      user.id,
      JournalType.pressureRelease
    )
    if (!hasRecentPressureRelease) {
      await sendAbPressureReleaseReminder(user, hasCurrentPressureUlcer)
    }
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

const painAndSmellReminderJob = new CronJob('0 0 8,20 * * *', async () => {
  if (!UserModel) return
  const users = await UserModel.getAll()

  await Promise.all(
    users
      .filter((u) => u.deviceId && u.notificationSettings.journal)
      .map(sendPainAndSmellReminder)
  )
})

const utiStatusReminderJob = new CronJob('0 0 10 * * 2,5', async () => {
  if (!UserModel) return
  const users = await UserModel.getAll()

  await Promise.all(
    users
      .filter((u) => u.deviceId && u.notificationSettings.journal)
      .map(sendUtiStatusReminder)
  )
})

const abTestingReminderJob = new CronJob('0 0 9-20 * * *', async () => {
  if (!UserModel) return
  const users = await UserModel.getAll()

  await Promise.all(
    users
      .filter((u) => u.deviceId && u.notificationSettings.journal)
      .map(sendAbTestRemindersForUser)
  )
})

job.start()
journalJob.start()
painAndSmellReminderJob.start()
utiStatusReminderJob.start()
abTestingReminderJob.start()
