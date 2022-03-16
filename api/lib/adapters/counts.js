const axios = require('axios')
const { PYTHON_API = 'http://localhost:5555' } = process.env

const getCounts = async (acc) => {
  const counts = await axios.post(`${PYTHON_API}/counts`, acc)
  return counts.data
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

const calculateCounts = ({ accel, hr }) => {
  const minutes = group(accel, (d) => getMinute(d.t))

  return Promise.all(
    Object.keys(minutes).map(async (minute) => {
      const accel = minutes[minute]
      if (accel.length < 1600) {
        return {
          minute: new Date(minute).toISOString(),
          energy: null,
        }
      }
      const [xs, ys, zs] = await Promise.all([
        getCounts(accel.map((d) => d.x / 9.82)),
        getCounts(accel.map((d) => d.y / 9.82)),
        getCounts(accel.map((d) => d.z / 9.82)),
      ])
      const x = xs.reduce((a, b) => a + b)
      const y = ys.reduce((a, b) => a + b)
      const z = zs.reduce((a, b) => a + b)
      const accVM = Math.sqrt(x * x + y * y + z * z)

      const hrs = hr.filter((d) => getMinute(d.t) === minute)
      const heartrate = hrs.reduce((acc, d) => acc + d.hr, 0) / hrs.length

      return {
        t: new Date(minute).toISOString(),
        a: accVM,
        hr: heartrate,
      }
    })
  )
}

module.exports = {
  calculateCounts,
}
