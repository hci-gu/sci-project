import { Condition } from '../../db/models/User'
import {
  standardCoeff,
  zeroCoeff,
  skiErgo,
  armErgo,
  paraWeights,
  tetraWeights,
} from './coeffs.json'
import { Activity } from '../../constants'

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
      return armErgo
    case Activity.weights:
      return weights(condition)
    // movement
    case Activity.sedentary:
      return zeroCoeff
    case Activity.active:
    case Activity.moving:
    default:
      return standardCoeff
  }
}
