import UserModel from '../../db/models/User'
import { getEnergyForMovementAndActivity } from '../../adapters/energy'
import { getMovementForPeriod } from '../../adapters/movement'
import { Activity } from '../../constants'

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
  group: string
}) => {
  const user = await UserModel.get(id)

  if (!user) {
    throw new Error('User not found')
  }

  const movement = await getMovementForPeriod({
    id,
    from,
    to,
    group,
    condition: user.condition,
  })

  return movement.map((m) => ({
    ...m,
    energy: getEnergyForMovementAndActivity(user, m, activity),
  }))
}
