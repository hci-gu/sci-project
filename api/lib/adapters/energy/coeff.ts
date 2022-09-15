import { Condition } from '../../db/models/User'
import { MovementLevel } from '../movement'
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
  movementLevel,
}: {
  condition: Condition
  activity?: Activity
  movementLevel: MovementLevel
}): Coeff {
  if (activity) {
    switch (activity) {
      case Activity.skiErgo:
        return skiErgo
      case Activity.armErgo:
        return armErgo
      case Activity.weights:
        return weights(condition)
    }
  }

  switch (movementLevel) {
    case MovementLevel.sedentary:
      return zeroCoeff
    case MovementLevel.active:
    case MovementLevel.moving:
    default:
      return standardCoeff
  }
}
