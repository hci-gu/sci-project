const actilife = require('../actilife')
const moment = require('moment')

const standardCoeff = {
  constant: -0.022223,
  hr: 0.000281,
  weight: 0.000081,
  acc: 0.000002,
}

const group = (data, f) => {
  const groups = {}
  data.forEach(d => {
    const key = f(d)
    if (!groups[key]) groups[key] = []
    groups[key].push(d)
  })
  return groups
}

const getEnergy = ({ accel, hr, weight, coeff = standardCoeff }) => {
  const minutes = group(accel, d => moment(d.t).format("YYYY-MM-DD HH:mm"))

  return Promise.all(Object.keys(minutes).map(async minute => {
    const accel = minutes[minute]
    const x = await actilife.counts({ acc: accel.map(d => d.x / 9.82), f: 30 })
    const y = await actilife.counts({ acc: accel.map(d => d.y / 9.82), f: 30 })
    const z = await actilife.counts({ acc: accel.map(d => d.z / 9.82), f: 30 })
    const a = x.map((d, i) => d + y[i] + z[i])

    const hrs = hr.filter(d => moment(d.t).format("YYYY-MM-DD HH:mm") === minute)
    const heartrate = hrs.reduce((acc, d) => acc + d.hr, 0) / hrs.length

    const energy = coeff.constant + coeff.hr * heartrate + coeff.weight * weight + coeff.acc * a.reduce((a, b) => a + b)

    return {
      minute: moment(minute).toISOString(),
      energy,
      accel,
    }
  }))
}

module.exports = {
  getEnergy,
}
