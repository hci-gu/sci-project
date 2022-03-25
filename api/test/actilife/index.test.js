const { getCounts } = require('../../lib/adapters/counts')
const accel = require('../data/accel.json')

beforeAll(() => {
  jest.setTimeout(30000)
})

describe.only('actilife', () => {
  test('correct count', async () => {
    const accelx = accel.map((d) => d.x / 9.82)

    const x = await getCounts(accelx)
    expect(x).toHaveLength(991)
  })
})
