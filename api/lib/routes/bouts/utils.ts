import UserModel from '../../db/models/User.js'
import { overwriteEnergy, removeEnergyForPeriod } from '../../db/models/Energy.js'
import AccelCountModel from '../../db/models/AccelCount.js'
import BoutModel, { mergeBouts } from '../../db/models/Bout.js'
import { Activity } from '../../constants.js'
import {
  activityForAccAndCondition,
  getEnergyForCountAndActivity,
} from '../../adapters/energy/index.js'
import { Bout, Energy, User } from '../../db/classes.js'
import moment from 'moment'

export const boutsForPeriod = async ({
  from,
  to,
  id,
  group,
}: {
  from: Date
  to: Date
  id: string
  group?: string
}) => {
  const user = await UserModel.get(id)

  if (!user) {
    throw new Error('User not found')
  }

  if (group) {
    const bouts = await BoutModel.group({
      userId: id,
      from,
      to,
      unit: group,
    })

    return bouts
  }

  const bouts = await BoutModel.find({
    userId: id,
    from,
    to,
  })
  return bouts
}

export type EnergyGeneratorArgs = {
  user: User
  bout: Bout
}

export const saveBout = async (
  userId: string,
  {
    t,
    minutes,
    activity,
    data = {},
    energyGenerator,
  }: {
    t: Date
    minutes: number
    activity: Activity
    data?: any
    energyGenerator?: (args: EnergyGeneratorArgs) => Promise<Energy[]> | Energy[]
  }
) => {
  const user = await UserModel.get(userId)

  if (!user) {
    throw new Error('User not found')
  }
  const bout = await BoutModel.save(
    {
      t,
      minutes,
      activity,
      data,
    },
    userId
  )

  let energy: Energy[] = []

  if (energyGenerator) {
    const generated = await energyGenerator({ user, bout })
    if (generated?.length) {
      energy = generated
    }
  } else {
    const counts = await AccelCountModel.find({
      userId,
      from: bout.t,
      to: new Date(bout.t.getTime() + bout.minutes * 60 * 1000),
    })

    // get energy for each count
    energy = counts.map((count) => {
      // TODO: for activity that required watt, store that in "data" field for bout
      const kcal = getEnergyForCountAndActivity(user, count, activity)

      return {
        t: count.t,
        activity,
        kcal,
      } as Energy
    })
  }

  if (energy.length) {
    await overwriteEnergy(userId, energy)
  }

  return bout
}

export const removeBout = async (userId: string, id: string) => {
  console.log('removeBout', userId, id)
  const user = await UserModel.get(userId)
  if (!user) {
    throw new Error('User not found')
  }

  const bout = await BoutModel.get(id)
  if (!bout) {
    throw new Error('Bout not found')
  }

  const boutEnd = new Date(bout.t.getTime() + bout.minutes * 60 * 1000)

  if ((bout.data as any)?.manual) {
    await removeEnergyForPeriod(userId, bout.t, boutEnd)
    await BoutModel.remove(id)
    return
  }

  // get all counts for this bout
  const counts = await AccelCountModel.find({
    userId,
    from: bout.t,
    to: boutEnd,
  })

  const energy = counts.map((count) => {
    const activity = activityForAccAndCondition(count.a, user.condition)
    const kcal = getEnergyForCountAndActivity(user, count)

    return {
      t: count.t,
      activity,
      kcal,
    } as Energy
  })

  if (energy.length) {
    await overwriteEnergy(userId, energy)
  }

  await BoutModel.remove(id)
}

const randMin = (value: number) => Math.floor((Math.random() * 2 - 1) * value)

export const fillMockData = async (userId: string, days = 365) => {
  let bouts = []

  for (let i = 0; i < days; i++) {
    const wakeUpHour = Math.floor(Math.random() * 2) + 6
    const exercised = Math.random() < 0.15
    const date = moment()
      .subtract(i, 'days')
      .startOf('day')
      .add(wakeUpHour, 'hours')
      .toDate()

    let morningMinutes = 60 + randMin(30)
    let commuteToWorkMinutes = 30 + randMin(5)
    let commuteHomeMinutes = 30 + randMin(5)
    let eveningMinutes = 4 * 60 + randMin(60)

    let timestamp = date
    bouts.push({
      minutes: morningMinutes,
      timestamp: date,
      activity: Activity.moving,
    })
    timestamp = moment(timestamp).add(morningMinutes, 'minutes').toDate()

    bouts.push({
      minutes: commuteToWorkMinutes,
      timestamp,
      activity: Activity.moving,
    })

    timestamp = moment(timestamp).add(commuteToWorkMinutes, 'minutes').toDate()

    for (let j = 0; j < 8; j++) {
      let stillMinutes = 50 + randMin(10)
      let movementMinutes = 10 + randMin(5)

      bouts.push({
        minutes: stillMinutes,
        timestamp,
        activity: Activity.sedentary,
      })
      timestamp = moment(timestamp).add(stillMinutes, 'minutes').toDate()
      bouts.push({
        minutes: movementMinutes,
        timestamp,
        activity: Activity.sedentary,
      })
      timestamp = moment(timestamp).add(movementMinutes, 'minutes').toDate()
    }

    bouts.push({
      minutes: commuteHomeMinutes,
      timestamp,
      activity: Activity.moving,
    })
    timestamp = moment(timestamp).add(commuteHomeMinutes, 'minutes').toDate()

    if (exercised) {
      const exerciseMinutes = 30 + randMin(15)
      bouts.push({
        minutes: exerciseMinutes,
        timestamp,
        activity: Activity.active,
      })
      timestamp = moment(timestamp).add(exerciseMinutes, 'minutes').toDate()
    }

    bouts.push({
      minutes: eveningMinutes,
      timestamp,
      activity: Activity.sedentary,
    })
  }

  for (let bout of bouts) {
    await BoutModel.save(
      {
        t: bout.timestamp,
        minutes: bout.minutes,
        activity: bout.activity,
        data: {},
      },
      userId
    )
  }
}

export const mergeBoutsForUser = async (
  userId: string,
  options?: { maxGapMinutes?: number; from?: Date; to?: Date }
) => {
  const user = await UserModel.get(userId)

  if (!user) {
    throw new Error('User not found')
  }

  return mergeBouts(userId, options)
}
