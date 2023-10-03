import UserModel from '../../db/models/User'
import { overwriteEnergy } from '../../db/models/Energy'
import AccelCountModel from '../../db/models/AccelCount'
import BoutModel from '../../db/models/Bout'
import { Activity } from '../../constants'
import {
  activityForAccAndCondition,
  getEnergyForCountAndActivity,
} from '../../adapters/energy'
import { Energy } from '../../db/classes'

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

export const saveBout = async (
  userId: string,
  {
    t,
    minutes,
    activity,
  }: {
    t: Date
    minutes: number
    activity: Activity
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
      data: {},
    },
    userId
  )

  const counts = await AccelCountModel.find({
    userId,
    from: bout.t,
    to: new Date(bout.t.getTime() + bout.minutes * 60 * 1000),
  })

  // get energy for each count
  const energy = counts.map((count) => {
    // TODO: for activity that required watt, store that in "data" field for bout
    const kcal = getEnergyForCountAndActivity(user, count, activity)

    return {
      t: count.t,
      activity,
      kcal,
    } as Energy
  })

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

  // get all counts for this bout
  const counts = await AccelCountModel.find({
    userId,
    from: bout.t,
    to: new Date(bout.t.getTime() + bout.minutes * 60 * 1000),
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
