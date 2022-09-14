import axios from 'axios'
import { Accel } from '../db/models/Accel'
import { HeartRate } from '../db/models/HeartRate'
import * as utils from '../utils'
const { PYTHON_API = 'http://localhost:5555' } = process.env

export const getCounts = async (acc: number[]): Promise<number[]> => {
  const counts = await axios.post(`${PYTHON_API}/counts`, acc)
  return counts.data
}

export const calculateCounts = ({
  accel,
  hr,
}: {
  accel: Accel[]
  hr: HeartRate[]
}) => {
  const minutes = utils.group(accel, (d) => utils.getMinute(d.t))

  return Promise.all(
    Object.keys(minutes).map(async (minute) => {
      const accel = minutes[minute] as Accel[]
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

      const hrs = hr.filter((d) => utils.getMinute(d.t) === minute)
      const heartrate = hrs.reduce((acc, d) => acc + d.hr, 0) / hrs.length

      return {
        t: new Date(minute).toISOString(),
        a: accVM,
        hr: heartrate,
      }
    })
  )
}
