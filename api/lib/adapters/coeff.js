const ACTIVITY = {
  WEIGHTS: 'weights',
  SKI_ERGO: 'ski-ergo',
  ARM_ERGO: 'arm-ergo',
  STILL: 'still',
}

const standardCoeff = {
  constant: -1.235591,
  values: {
    hr: 0.01391,
    weight: 0.007091,
    gender: 0.569553,
    acc: 0.000035,
  },
}
const zeroCoeff = {
  constant: 0,
  values: {},
}
const skiErgo = {
  constant: 0.230183284229348,
  values: {
    weight: 0.0174070397777326,
    watt: 0.076825194274764,
  },
}
const armErgo = {
  constant: -0.603421,
  values: {
    weight: 0.013435,
    hr: 0.012068,
    acc: 0.000091,
    gender: 0.590387,
    condition: -0.493678,
  },
}
const paraWeights = {
  constant: -4.04913828489822,
  values: {
    hr: 0.0143314447204367,
    weight: 0.039208416794491,
    acc: 0.000307940063570141,
    gender: 0.76596174333638,
  },
}
const tetraWeights = {
  constant: -1.38947513504287,
  values: {
    acc: 0.000227067912695819,
    gender: 0.587303205287161,
    injuryLevel: 0.166452279742845,
  },
}

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
