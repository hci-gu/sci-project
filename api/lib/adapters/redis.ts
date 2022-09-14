import { createClient } from 'redis'
const { REDIS_URL } = process.env

const client = createClient({
  url: REDIS_URL ?? 'redis://localhost:6379',
})

client.on('error', (err) => console.log('Redis Client Error', err))

client.connect()

export const set = (key: string, value: any, exp = 60 * 5) =>
  client.set(key, JSON.stringify(value), { EX: exp })
export const get = (key: string) =>
  client.get(key).then((value) => (value ? JSON.parse(value) : null))
