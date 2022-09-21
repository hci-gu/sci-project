import UserModel from '../../db/models/User'
import { Activity } from '../../constants'
import EnergyModel from '../../db/models/Energy'
import AccelCountModel from '../../db/models/AccelCount'
import {
  getEnergyForCountAndActivity,
  movementLevelForAccAndCondition,
} from '../../adapters/energy'

export const energyForPeriod = async ({
  from,
  to,
  id,
  activity,
  watt,
  group,
}: {
  from: Date
  to: Date
  id: string
  activity: Activity
  watt?: number
  group?: string
}) => {
  const user = await UserModel.get(id)

  if (!user) {
    throw new Error('User not found')
  }

  if (group) {
    const energy = await EnergyModel.group({
      userId: id,
      from,
      to,
      unit: group,
    })

    return energy
  }

  const energy = await EnergyModel.find({
    userId: id,
    from,
    to,
  })

  return energy
}

export const fillEnergyFromCounts = async ({
  from,
  to,
  id,
}: {
  from: Date
  to: Date
  id: string
}) => {
  const user = await UserModel.get(id)

  if (!user) {
    throw new Error('User not found')
  }

  const counts = await AccelCountModel.find({
    userId: id,
    from,
    to,
  })

  const energies = counts.map((count) => {
    const activity = movementLevelForAccAndCondition(count.a, user.condition)
    const kcal = getEnergyForCountAndActivity(user, count)

    return {
      t: count.t,
      activity,
      kcal,
    }
  })

  await EnergyModel.save(energies, id)
}
