import { getEnergyForCountAndActivity } from '../lib/adapters/energy'
import { calculateCounts } from '../lib/adapters/counts'
const accel = require('./data/accel.json')
const hr = require('./data/hr.json')
const user = require('./data/user.json')

beforeAll(() => {
  jest.setTimeout(30000)
})

describe('getEnergy', () => {
  test('runs', async () => {
    const counts = await calculateCounts({ accel, hr })

    const result = counts.map((c) => {
      return {
        t: c.t,
        kcal: getEnergyForCountAndActivity(user, c),
      }
    })

    expect(result).toHaveLength(15)
  })
})
