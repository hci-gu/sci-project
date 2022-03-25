const energy = require('../lib/adapters/energy')
const { calculateCounts } = require('../lib/adapters/counts')
const accel = require('./data/accel.json')
const hr = require('./data/hr.json')

beforeAll(() => {
  jest.setTimeout(30000)
})

describe('getEnergy', () => {
  test('runs', async () => {
    const counts = await calculateCounts({ accel, hr })
    const result = await energy.getEnergy({ counts, weight: 80 })

    expect(result).toHaveLength(15)
  })
})
