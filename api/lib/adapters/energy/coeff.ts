import coeffs from './coeffs.json' assert { type: 'json' }
import { Activity, Condition } from '../../constants.ts'

type Coeff = {
  constant: number
  values: {
    hr?: number
    weight?: number
    gender?: number
    acc?: number
    condition?: number
    injuryLevel?: number
  }
}

const weights = (condition: Condition) => {
  switch (condition) {
    case Condition.paraplegic:
      return coeffs.paraWeights
    case Condition.tetraplegic:
      return coeffs.tetraWeights
    default:
      return coeffs.standardCoeff
  }
}

const armErgo = (condition: Condition) => {
  switch (condition) {
    case Condition.paraplegic:
      return coeffs.paraArmErgo
    case Condition.tetraplegic:
      return coeffs.tetraArmErgo
    default:
      return coeffs.standardCoeff
  }
}

export default function getCoeff({
  condition,
  activity,
}: {
  condition: Condition
  activity: Activity
}): Coeff {
  switch (activity) {
    // training
    case Activity.skiErgo:
      return coeffs.skiErgo
    case Activity.armErgo:
      return armErgo(condition)
    case Activity.weights:
      return weights(condition)
    case Activity.rollOutside:
      return coeffs.rollOutside
    // movement
    case Activity.sedentary:
      return coeffs.zeroCoeff
    case Activity.active:
    case Activity.moving:

    default:
      return coeffs.standardCoeff
  }
}
