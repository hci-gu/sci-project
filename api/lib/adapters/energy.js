const getCoeff = require('./coeff')

const valueForGender = (gender) => {
  if (gender === 'male') return 2
  if (gender === 'female') return 1
  return 0
}

const valueForCondition = (condition) => {
  if (condition === 'paraplegic') return 3
  if (condition === 'tetraplegic') return 4
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
  const returnVal = counts.map(({ a, hr, t }) => {
    const values = {
      acc: a,
      hr,
      weight,
      gender: valueForGender(gender),
      watt,
      injuryLevel,
      condition: valueForCondition(condition),
    }
    let still = false
    let coeff
    if ((!activity || activity === 'none') && a < 2000) {
      still = true
      coeff = getCoeff({ activity: 'still' })
    } else {
      coeff = getCoeff({ condition, activity })
    }
    totalCount++

    let energy = coeff.constant
    Object.keys(coeff.values).forEach((key) => {
      formulaStr += ` + (${coeff.values[key]} * ${values[key]})`
      energy += coeff.values[key] * values[key]
    })

    return {
      t,
      still,
      energy: Math.max(energy, 0),
    }
  })

  return returnVal.reduce((acc, curr) => acc + curr.energy, 0)
}

module.exports = {
  getEnergy,
}
