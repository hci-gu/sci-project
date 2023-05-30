import moment from 'moment'
import { Op } from 'sequelize'
import { GoalType } from '../../constants'
import { Goal } from '../../db/classes'
import Journal from '../../db/models/Journal'

export const getGoalProgress = async (
  userId: string,
  goal: Goal,
  date = new Date()
) => {
  if (goal.type === GoalType.journal) {
    const journals = await Journal.find(
      {
        userId,
        from: moment(date).startOf('day').toDate(),
        to: moment(date).endOf('day').toDate(),
      },
      {
        type: goal.journalType,
      }
    )
    return journals.length
  }
  return 0
}
