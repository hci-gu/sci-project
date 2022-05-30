const { createClient } = require('redis')
const { REDIS_URL } = process.env

const client = createClient({
  url: REDIS_URL ? REDIS_URL : 'redis://localhost:6379',
})

client.on('error', (err) => console.log('Redis Client Error', err))

client.connect()

module.exports = {
  set: (key, value) => client.set(key, JSON.stringify(value), { EX: 60 * 5 }),
  get: (key) =>
    client
      .get(key)
      .then((value) => (value ? JSON.parse(value) : { hr: [], accel: [] })),
}
