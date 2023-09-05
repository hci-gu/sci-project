import moment from 'moment'
import { Op } from 'sequelize'
import Journal from '../../db/models/Journal'
import { JournalType } from '../../constants'

export const getCurrentPressureUlcers = async (userId: string, to?: Date) => {
  const dateTo = moment(to).endOf('day').toDate()
  const entries = await Journal.find(
    {
      userId,
    },
    {
      type: JournalType.pressureUlcer,
      t: {
        [Op.lte]: dateTo,
      },
    }
  )

  // info.bodyPart is unique identifier for pressure ulcer, take last entry for each body part
  // if info.pressureUlcerType is "none" as last entry, it means that pressure ulcer is healed
  const lastEntries = entries.reduce((acc: any, entry: any) => {
    if (!acc[entry.info.location]) {
      acc[entry.info.location] = entry
    } else if (moment(entry.t).isAfter(acc[entry.info.location].t)) {
      acc[entry.info.location] = entry
    }
    if (entry.info.pressureUlcerType === 'none') {
      delete acc[entry.info.location]
    }
    return acc
  }, {})

  return Object.values(lastEntries)
}

export const fillMockData = async (userId: string, days = 90) => {
  let pressureReleases = []

  for (let i = 0; i < days; i++) {
    // random wake up time between 6 and 8
    const wakeUpHour = Math.floor(Math.random() * 2) + 6
    const date = moment()
      .subtract(i, 'days')
      .startOf('day')
      .add(wakeUpHour, 'hours')
      .toDate()

    const numberOfPressureReleases = Math.floor(
      Math.pow(Math.random(), 0.5) * 10
    )

    for (let j = 0; j < numberOfPressureReleases; j++) {
      const timestamp = moment(date).add(j, 'hours').toDate()
      const pressureRelease = {
        timestamp,
        type: JournalType.pressureRelease,
        info: { exercises: ['rightSide', 'leftSide', 'forwards'] },
      }
      pressureReleases.push(pressureRelease)
    }
  }

  for (let e of pressureReleases) {
    await Journal.save(e, userId)
  }
}
