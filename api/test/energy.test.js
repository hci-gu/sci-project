const energy = require('../lib/adapters/energy')
const accel = require('./data/accel.json')
const hr = require('./data/hr.json')

describe('getEnergy', () => {
  test('runs', async () => {
    const result = await energy.getEnergy({ accel, hr, weight: 80 })
    expect(result).toHaveLength(991)
  })
})
