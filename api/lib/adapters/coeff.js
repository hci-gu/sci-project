const ACTIVITY = {
  WEIGHTS: 'weights',
  SKI_ERGO: 'ski-ergo',
  ARM_ERGO: 'arm-ergo',
  STILL: 'still',
}

const {
  standardCoeff,
  zeroCoeff,
  skiErgo,
  armErgo,
  paraWeights,
  tetraWeights,
} = require('./coeff.json')

const weights = (condition) => {
  if (condition === 'paraplegic') {
    return paraWeights
  }
  if (condition === 'tetraplegic') {
    return tetraWeights
  }
  return standardCoeff
}

const getCoeff = ({ condition, activity }) => {
  switch (activity) {
    case ACTIVITY.WEIGHTS:
      return weights(condition)
    case ACTIVITY.SKI_ERGO:
      return skiErgo
    case ACTIVITY.ARM_ERGO:
      return armErgo
    case ACTIVITY.STILL:
      return zeroCoeff
    default:
      return standardCoeff
  }
}

module.exports = getCoeff
