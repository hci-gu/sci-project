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
  sciErgoCoeff: {
    constant: 0.053278,
    // constant value used for training session
    watt: 0.000885,
    hr: 0,
    weight: -0.000365,
    acc: 0,
  },
}

const getEnergy = ({ counts, weight, coeff = standardCoeff }) => {
  return counts.map(({ a, hr, t }) => {
    const energy =
      weight *
      (coeff.constant + coeff.hr * hr + coeff.weight * weight + coeff.acc * a)

    return {
      t,
      energy,
    }
  })
}

module.exports = {
  getEnergy,
}
