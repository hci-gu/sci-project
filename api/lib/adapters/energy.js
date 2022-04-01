const getCoeff = require('./coeff')

const valueForGender = (gender) => {
  if (gender === 'male') return 2
  if (gender === 'female') return 1
  return 0
}

const getEnergy = ({
  counts,
  weight,
  watt,
  activity,
  gender = 'female',
  injuryLevel = 5,
  condition = 'paraplegic',
}) => {
  const coeff = getCoeff({ condition, activity })

  return counts.map(({ a, hr, t }) => {
    const values = {
      acc: a,
      hr,
      weight,
      gender: valueForGender(gender),
      watt,
      injuryLevel,
    }
    let energyPerKg = coeff.constant
    Object.keys(coeff.values).forEach((key) => {
      energyPerKg += coeff.values[key] * values[key]
    })
    const energy = weight * energyPerKg

    return {
      t,
      energy,
    }
  })
}

module.exports = {
  getEnergy,
}
