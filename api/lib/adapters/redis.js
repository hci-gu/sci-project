const { createClient } = require('redis')
const { REDIS_URL } = process.env

const client = createClient({
  url: REDIS_URL ? REDIS_URL : 'redis://localhost:6379',
})

client.on('error', (err) => console.log('Redis Client Error', err))

client.connect()

module.exports = {
  set: (key, value, exp = 60 * 5) =>
    client.set(key, JSON.stringify(value), { EX: exp }),
  get: (key) =>
    client.get(key).then((value) => (value ? JSON.parse(value) : null)),
}
