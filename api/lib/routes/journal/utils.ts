import moment from 'moment'
import { Op } from 'sequelize'
import Journal from '../../db/models/Journal'
import { JournalType } from '../../constants'

export const getCurrentPressureUlcers = async (userId: string, to?: Date) => {
  const entries = await Journal.find(
    {
      userId,
    },
    {
      type: JournalType.pressureUlcer,
      t: {
        [Op.lte]: to || new Date(),
      },
    }
  )

  // info.bodyPart is unique identifier for pressure ulcer, take last entry for each body part
  // if info.pressureUlcerType is "none" as last entry, it means that pressure ulcer is healed
  const lastEntries = entries.reduce((acc: any, entry: any) => {
    if (!acc[entry.info.bodyPart]) {
      acc[entry.info.bodyPart] = entry
    } else if (moment(entry.t).isAfter(acc[entry.info.bodyPart].t)) {
      acc[entry.info.bodyPart] = entry
    }
    if (entry.info.pressureUlcerType === 'none') {
      delete acc[entry.info.bodyPart]
    }
    return acc
  }, {})

  return Object.values(lastEntries)
}
