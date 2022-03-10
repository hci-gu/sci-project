const actilife = require('../actilife')

const standardCoeff = {
  constant: -0.022223,
  hr: 0.000281,
  weight: 0.000081,
  acc: 0.000002,
}

const getEnergy = ({ accel, hr, weight, coeff = standardCoeff }) => {
  const x = actilife.counts({ acc: accel.map(d => d.x / 9.82), f: 30 })
  const y = actilife.counts({ acc: accel.map(d => d.y / 9.82), f: 30 })
  const z = actilife.counts({ acc: accel.map(d => d.z / 9.82), f: 30 })
  const a = x.map((d, i) => d + y[i] + z[i])
  
}

module.exports = {

}