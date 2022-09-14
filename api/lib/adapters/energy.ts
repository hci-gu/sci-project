import { Condition, Gender } from '../db/models/User'
import { Coeff, getCoeff } from './coeff'

export enum Activity {
  weights = 'weights',
  skiErgo = 'skiErgo',
  armErgo = 'armErgo',
  still = 'still',
  movement = 'movement',
  active = 'active',
}

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

type GetEnergyProps = {
  counts: any[]
  weight: number
  watt: number
  activity: Activity
  gender: Gender
  injuryLevel: number
  condition: Condition
}

export const getEnergy = ({
  counts,
  weight,
  watt,
  activity,
  gender = Gender.female,
  injuryLevel = 5,
  condition = Condition.paraplegic,
}: GetEnergyProps) => {
  return counts.map(({ a, hr, t }) => {
    const values = {
      acc: a,
      hr,
      weight,
      gender: valueForGender(gender),
      watt,
      injuryLevel,
      condition: valueForCondition(condition),
    }
    let still = false
    let activityLevel = 'sedentary'
    let coeff: Coeff
    if (activity && activity != Activity.still) {
      coeff = getCoeff({ condition, activity })
    } else if (
      (condition === Condition.paraplegic && a > 9515) ||
      (condition === Condition.tetraplegic && a > 4887)
    ) {
      coeff = getCoeff({ condition, activity: Activity.active })
      activityLevel = 'high-activity'
    } else if (a > 2700) {
      coeff = getCoeff({ condition, activity: Activity.movement })
      activityLevel = 'movement'
    } else {
      coeff = getCoeff({ condition, activity: Activity.still })
      activityLevel = 'sedentary'
    }

    let energy: number = coeff.constant
    let property: keyof typeof coeff.values
    for (property in coeff.values) {
      energy += coeff.values[property] ?? 0 * values[property]
    }

    return {
      t,
      still,
      energy: Math.max(energy, 0),
      activityLevel,
    }
  })
}
