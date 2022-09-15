import { Condition, Gender, User } from '../../db/models/User'
import { Movement } from '../movement'
import { Activity } from '../../constants'
import getCoeff from './coeff'

const valueForGender = (gender: Gender) => {
  switch (gender) {
    case Gender.female:
      return 1
    case Gender.male:
      return 2
    default:
      return 0
  }
}

const valueForCondition = (condition: Condition) => {
  switch (condition) {
    case Condition.paraplegic:
      return 3
    case Condition.tetraplegic:
      return 4
    default:
      return 0
  }
}

export const getEnergyForMovementAndActivity = (
  user: User,
  movement: Movement,
  activity: Activity
) => {
  const values = {
    acc: movement.a,
    hr: movement.hr,
    weight: user.weight,
    injuryLevel: user.injuryLevel,
    gender: valueForGender(user.gender),
    condition: valueForCondition(user.condition),
  }

  const coeff = getCoeff({
    condition: user.condition,
    movementLevel: movement.level,
    activity,
  })

  let energy: number = coeff.constant
  let property: keyof typeof coeff.values
  for (property in coeff.values) {
    energy += (coeff.values[property] ?? 0) * values[property]
  }

  return Math.max(energy, 0)
}
