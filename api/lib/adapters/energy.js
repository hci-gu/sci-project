const { ACTIVITY, getCoeff } = require('./coeff')

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
  return counts.map(({ a, hr, t }) => {
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
    let activityLevel = 'sedentary'
    let coeff
    if (activity && activity != ACTIVITY.still) {
      coeff = getCoeff({ condition, activity })
    } else if (
      (condition === 'paraplegic' && a > 9515) ||
      (condition === 'tetraplegic' && a > 4887)
    ) {
      coeff = getCoeff({ condition, activity: ACTIVITY.HIGH_ACTIVITY })
      activityLevel = 'high-activity'
    } else if (a > 2700) {
      coeff = getCoeff({ condition, activity: ACTIVITY.MOVEMENT })
      activityLevel = 'movement'
    } else {
      coeff = getCoeff({ condition, activity: ACTIVITY.STILL })
      activityLevel = 'sedentary'
    }

    let energy = coeff.constant
    Object.keys(coeff.values).forEach((key) => {
      energy += coeff.values[key] * values[key]
    })

    return {
      t,
      still,
      energy: Math.max(energy, 0),
      activityLevel,
    }
  })
}

module.exports = {
  getEnergy,
}
