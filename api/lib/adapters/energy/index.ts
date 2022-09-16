import { Condition, Gender, User } from '../../db/models/User'
import {
  Activity,
  MOVING_THRESHOLD_PARA,
  MOVING_THRESHOLD_TETRA,
  SEDENTARY_THRESHOLD,
} from '../../constants'
import getCoeff from './coeff'
import { AccelCount } from '../../db/models/AccelCount'

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

export const movementLevelForAccAndCondition = (
  a: number,
  condition: Condition
) => {
  if (
    (condition === Condition.paraplegic && a > MOVING_THRESHOLD_PARA) ||
    (condition === Condition.tetraplegic && a > MOVING_THRESHOLD_TETRA)
  ) {
    return Activity.active
  } else if (a > SEDENTARY_THRESHOLD) {
    return Activity.moving
  }

  return Activity.sedentary
}

export const getEnergyForCountAndActivity = (
  user: User,
  count: AccelCount,
  activity?: Activity
) => {
  const values = {
    acc: count.a,
    hr: count.hr,
    weight: user.weight,
    injuryLevel: user.injuryLevel,
    gender: valueForGender(user.gender),
    condition: valueForCondition(user.condition),
  }

  const coeff = getCoeff({
    condition: user.condition,
    activity:
      activity ?? movementLevelForAccAndCondition(count.a, user.condition),
  })

  let energy: number = coeff.constant
  let property: keyof typeof coeff.values
  for (property in coeff.values) {
    energy += (coeff.values[property] ?? 0) * values[property]
  }

  return Math.max(energy, 0)
}
