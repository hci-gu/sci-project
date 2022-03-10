const energy = require('../lib/adapters/energy')
const accel = require('./data/accel.json')
const hr = require('./data/hr.json')

beforeAll(() => {
  jest.setTimeout(30000)
})

describe('getEnergy', () => {
  test('runs', async () => {
    const result = await energy.getEnergy({ accel, hr, weight: 80 })
    // console.log({ result })
    expect(result).toHaveLength(15)
  })
})
