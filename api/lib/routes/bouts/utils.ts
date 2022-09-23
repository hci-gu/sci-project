import UserModel from '../../db/models/User'
import BoutModel from '../../db/models/Bout'

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
  console.log('bouts', bouts)
  return bouts
}
