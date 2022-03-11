const actilife = require('../actilife')

const standardCoeff = {
  constant: -0.022223,
  hr: 0.000281,
  weight: 0.000081,
  acc: 0.000002,
}

const group = (data, f) => {
  const groups = {}
  data.forEach((d) => {
    const key = f(d)
    if (!groups[key]) groups[key] = []
    groups[key].push(d)
  })
  return groups
}

const getMinute = (ts) => {
  const d = new Date(ts)
  return `${d.getFullYear()}-${
    d.getMonth() + 1
  }-${d.getDate()} ${d.getHours()}:${d.getMinutes()}`
}

const getEnergy = ({ accel, hr, weight, coeff = standardCoeff }) => {
  const minutes = group(accel, (d) => getMinute(d.t))

  return Promise.all(
    Object.keys(minutes).map(async (minute) => {
      const accel = minutes[minute]
      if (accel.length < 30) {
        return {
          minute: new Date(minute).toISOString(),
          energy: null,
        }
      }
      const [x, y, z] = await Promise.all([
        actilife.counts({
          type: 'x',
          minute,
          acc: accel.map((d) => d.x / 9.82),
          f: 30,
        }),
        actilife.counts({
          type: 'y',
          minute,
          acc: accel.map((d) => d.y / 9.82),
          f: 30,
        }),
        actilife.counts({
          type: 'z',
          minute,
          acc: accel.map((d) => d.z / 9.82),
          f: 30,
        }),
      ])
      const a = x.map((d, i) => d + y[i] + z[i])

      const hrs = hr.filter((d) => getMinute(d.t) === minute)
      const heartrate = hrs.reduce((acc, d) => acc + d.hr, 0) / hrs.length
      const accTotal = a.reduce((a, b) => a + b)

      const energy =
        weight *
        (coeff.constant +
          coeff.hr * heartrate +
          coeff.weight * weight +
          coeff.acc * accTotal)

      return {
        minute: new Date(minute).toISOString(),
        energy,
      }
    })
  )
}

module.exports = {
  getEnergy,
}
