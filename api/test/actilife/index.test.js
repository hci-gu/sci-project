const actilife = require('../../lib/actilife')
const accel = require('../data/accel.json')

beforeAll(() => {
  jest.setTimeout(30000)
})

describe('actilife', () => {
  test('correct count', async () => {
    const accelx = accel.map(d => d.x / 9.82)
    const x = await actilife.counts({ acc: accelx, f: 30 })
    expect(x).toHaveLength(991)
  })
})
