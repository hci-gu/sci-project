import {
  standardCoeff,
  zeroCoeff,
  skiErgo,
  paraArmErgo,
  tetraArmErgo,
  paraWeights,
  tetraWeights,
  rollOutside,
} from './coeffs.json'
import { Activity, Condition } from '../../constants'

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
      return paraWeights
    case Condition.tetraplegic:
      return tetraWeights
    default:
      return standardCoeff
  }
}

const armErgo = (condition: Condition) => {
  switch (condition) {
    case Condition.paraplegic:
      return paraArmErgo
    case Condition.tetraplegic:
      return tetraArmErgo
    default:
      return standardCoeff
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
      return skiErgo
    case Activity.armErgo:
      return armErgo(condition)
    case Activity.weights:
      return weights(condition)
    case Activity.rollOutside:
      return rollOutside
    // movement
    case Activity.sedentary:
      return zeroCoeff
    case Activity.active:
    case Activity.moving:

    default:
      return standardCoeff
  }
}
