const standardCoeff = {
  constant: -0.019288,
  hr: 0.000281,
  weight: 0.000044,
  acc: 0.000002,
}
const oldStandardCoeff = {
  constant: -0.022223,
  hr: 0.000281,
  weight: 0.000081,
  acc: 0.000002,
}
const gymCoeff = {
  constant: 0,
  hr: 0,
  weight: 0,
  acc: 0,
}
const paraCoeffs = {
  skiErgoCoeff: {
    constant: 0.035032,
    // constant value used for training session
    watt: 0.000829,
    hr: 0.000129,
    weight: -0.000315,
    acc: 0,
  },
}
const tetraCoeffs = {
  skiErgoCoeff: {
    constant: -0.174673,
    // constant value used for training session
    watt: 0.000744,
    hr: 0.001398,
    weight: 0.001318,
    acc: 0,
  },
}

const getCoeff = async (condition, type, watt) => {
  switch (type) {
    case 'value':
      break

    default:
      break
  }
  return standardCoeff
}

module.exports = getCoeff
