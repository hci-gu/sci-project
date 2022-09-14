const {
  standardCoeff,
  zeroCoeff,
  skiErgo,
  armErgo,
  paraWeights,
  tetraWeights,
} = require('./coeff.json')

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

export type Coeff = {
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

export const getCoeff = ({
  condition,
  activity,
}: {
  condition: Condition
  activity: Activity
}): Coeff => {
  switch (activity) {
    case Activity.weights:
      return weights(condition)
    case Activity.skiErgo:
      return skiErgo
    case Activity.armErgo:
      return armErgo
    case Activity.still:
      return zeroCoeff
    default:
      return standardCoeff
  }
}
