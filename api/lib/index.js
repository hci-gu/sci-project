require('dotenv').config()
const db = require('./db')
const createServer = require('./server')

const { DB_HOST, DB_USERNAME, DB_PASSWORD, DB } = process.env

const [host, port] = DB_HOST.split(':')

db({
  database: DB,
  username: DB_USERNAME,
  password: DB_PASSWORD,
  host,
  port,
})

const app = createServer()
app.listen(4000, () => console.log('listening on port 4000'))

// const { Accel, HeartRate } = require('./db/models')
// const { getEnergy } = require('./adapters/energy')

// const wait = () => new Promise((resolve) => setTimeout(resolve, 1000))
// const test = async () => {
//   await wait()
//   const userId = '1d0d4b6d-110d-470a-a376-7bd44f3fe156'
//   const from = '2022-03-10T23:00:00'
//   const to = '2022-03-11T24:00:00'

//   console.log('rows length null try to calc')
//   const [accel, hr] = await Promise.all([
//     await Accel.find({
//       userId,
//       from: new Date(from).toISOString(),
//       to: new Date(to).toISOString(),
//     }),
//     await HeartRate.find({
//       userId,
//       from: new Date(from).toISOString(),
//       to: new Date(to).toISOString(),
//     }),
//   ])
//   console.log('getEnergy with data: ', accel.length, hr.length)
//   const energy = await getEnergy({ accel, hr, weight: 70 })
// }

// test()
