import moment from 'moment'
import { Op } from 'sequelize'
import Journal from '../../db/models/Journal.ts'
import { JournalType } from '../../constants.ts'
import { createNoise2D } from 'simplex-noise'

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

export const getCurrentUTI = async (userId: string, to?: Date) => {
  const dateTo = moment(to).endOf('day').toDate()
  const entries = await Journal.find(
    {
      userId,
    },
    {
      type: JournalType.urinaryTractInfection,
      t: {
        [Op.lte]: dateTo,
      },
    }
  )

  // sort by timestamp and return latest entry
  const sortedEntries = entries.sort((a: any, b: any) =>
    moment(a.t).isAfter(b.t) ? -1 : 1
  )
  return [sortedEntries[0]]
}

export const getCurrentPain = async (
  userId: string,
  type: JournalType,
  to?: Date
) => {
  const dateTo = moment(to).endOf('day').toDate()
  const entries = await Journal.find(
    {
      userId,
    },
    {
      type: type,
      t: {
        [Op.lte]: dateTo,
      },
    }
  )

  // sort by timestamp and return latest entry
  entries.sort((a: any, b: any) => (moment(a.t).isAfter(b.t) ? -1 : 1))

  const lastEntries = entries.reduce((acc: any, entry: any) => {
    if (!acc[entry.info.bodyPart]) {
      acc[entry.info.bodyPart] = entry
    } else if (moment(entry.t).isAfter(acc[entry.info.bodyPart].t)) {
      acc[entry.info.bodyPart] = entry
    }
    return acc
  }, {})

  return Object.values(lastEntries)
}

export const getCurrentSpasticity = async (userId: string, to?: Date) => {
  const dateTo = moment(to).endOf('day').toDate()
  const entries = await Journal.find(
    {
      userId,
    },
    {
      type: JournalType.spasticity,
      t: {
        [Op.lte]: dateTo,
      },
    }
  )

  // sort by timestamp and return latest entry
  const sortedEntries = entries.sort((a: any, b: any) =>
    moment(a.t).isAfter(b.t) ? -1 : 1
  )

  return [sortedEntries[0]]
}

const bodyParts: any = [
  { name: 'elbow-right', noise: createNoise2D(Math.random) },
  { name: 'scapula-left', noise: createNoise2D(Math.random) },
]

export const fillMockData = async (userId: string, days = 600) => {
  let pressureReleases = []
  let painEntries = []
  let pressureUlcers = []

  for (let i = 0; i < days; i++) {
    // random wake up time between 6 and 8
    const wakeUpHour = Math.floor(Math.random() * 2) + 6
    const date = moment()
      .subtract(i, 'days')
      .startOf('day')
      .add(wakeUpHour, 'hours')
      .toDate()

    // for each bodyPart
    for (let bodyPart of bodyParts) {
      const timestamp = moment(date).toDate()
      // pain value between 0 to 10 with noise based on day as x
      const painValue = (bodyPart.noise(i, 0) + 1) * 0.5
      const painEntry = {
        timestamp,
        type: JournalType.painLevel,
        comment: Math.random() < 0.05 ? 'This is a comment' : '',
        info: {
          bodyPart: bodyPart.name,
          painLevel: Math.floor(painValue * 10),
        },
      }
      if (Math.random() < 0.1) {
        painEntries.push(painEntry)
      }
    }

    let numberOfPressureReleases = Math.floor(Math.pow(Math.random(), 0.5) * 10)
    if (Math.random() < 0.05) {
      numberOfPressureReleases = 0
    }

    for (let j = 0; j < numberOfPressureReleases; j++) {
      const timestamp = moment(date).add(j, 'hours').toDate()
      const pressureRelease = {
        timestamp,
        type: JournalType.pressureRelease,
        comment: '',
        info: { exercises: ['rightSide', 'leftSide', 'forwards'] },
      }
      pressureReleases.push(pressureRelease)
    }
  }

  let initialPressureUlcerDate = moment().subtract(days, 'days').add().toDate()
  pressureUlcers.push({
    timestamp: initialPressureUlcerDate,
    type: JournalType.pressureUlcer,
    comment: '',
    info: {
      location: 'elbow-right',
      pressureUlcerType: 'stage1',
    },
  })
  let timestamp = initialPressureUlcerDate
  const stages = ['stage2', 'stage3', 'stage4', 'stage2', 'stage1', 'none']
  for (let i = 0; i < stages.length; i++) {
    const stage = stages[i]
    const durationOfStage = 20 + Math.floor(Math.random() * 40)
    timestamp = moment(timestamp).add(durationOfStage, 'days').toDate()

    const pressureUlcer = {
      timestamp,
      type: JournalType.pressureUlcer,
      comment: '',
      info: {
        location: 'elbow-right',
        pressureUlcerType: stage,
      },
    }
    pressureUlcers.push(pressureUlcer)
  }

  for (let e of pressureReleases) {
    await Journal.save(e, userId)
  }
  for (let e of painEntries) {
    await Journal.save(e, userId)
  }
  for (let e of pressureUlcers) {
    await Journal.save(e, userId)
  }
}
