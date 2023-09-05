import moment from 'moment-timezone'
import { Op } from 'sequelize'
import { GoalType } from '../../constants'
import { Goal, Journal } from '../../db/classes'
import JournalModel from '../../db/models/Journal'

const getGoalReccurence = (goal: Goal) => {
  const goalMinuteOfDay =
    moment(goal.start, 'HH:mm').hour() * 60 +
    moment(goal.start, 'HH:mm').minute()
  return Math.floor((22 * 60 - goalMinuteOfDay) / goal.value)
}

export const getNextReminder = (goal: Goal, journal: Journal[]) => {
  const tz: string = 'Europe/Stockholm'

  if (journal.length === 0) {
    return moment
      .tz(goal.start, 'HH:mm', tz)
      .add(getGoalReccurence(goal), 'minutes')
      .toDate()
  }

  const lastEntry = moment.tz(journal[journal.length - 1].t, tz)

  const nextEntry = lastEntry.add(getGoalReccurence(goal), 'minutes')
  // round to nearest 15 minutes
  const remainder = nextEntry.minute() % 15
  if (remainder > 7) {
    nextEntry.add(15 - remainder, 'minutes')
  } else {
    nextEntry.subtract(remainder, 'minutes')
  }
  nextEntry.second(0).millisecond(0)

  return nextEntry.toDate()
}

export const getGoalInfo = async (
  userId: string,
  goal: Goal,
  date = new Date()
) => {
  if (goal.type === GoalType.journal) {
    const journal = await JournalModel.find(
      {
        userId,
        from: moment(date).startOf('day').toDate(),
        to: moment(date).endOf('day').toDate(),
      },
      {
        type: goal.journalType,
      }
    )

    return {
      progress: journal.length,
      recurrence: getGoalReccurence(goal),
      reminder: getNextReminder(goal, journal),
    }
  }
  return {
    progress: 0,
  }
}
