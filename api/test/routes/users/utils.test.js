const db = require('../../../lib/db')
const utils = require('../../../lib/routes/users/utils')

const models = require('../../../lib/db/models')

// jest.mock('../../../lib/db/models/index.js')

beforeEach(async () => {
  await db()
})

describe('activityForPeriod', () => {
  it('works', async () => {
    models.User = jest.fn()
    models.User.mockResolvedValue({})
    models.AccelCount.find = jest.fn()
    models.AccelCount.find.mockResolvedValue([
      {
        t: '2022-01-01T00:00:00Z',
        a: 0,
        hr: 60,
      },
      {
        t: '2022-01-01T00:01:00Z',
        a: 5000,
        hr: 60,
      },
      {
        t: '2022-01-01T00:02:00Z',
        a: 0,
        hr: 60,
      },
      {
        t: '2022-01-01T00:03:00Z',
        a: 0,
        hr: 60,
      },
      {
        t: '2022-01-01T00:04:00Z',
        a: 0,
        hr: 60,
      },
    ])

    const result = await utils.activityForPeriod({
      id: -1,
      from: '2022-01-01T00:00:00Z',
      to: '2022-01-01T00:04:00Z',
    })
    expect(result.minutesInactive).toBe(3)
    expect(result.averageInactiveDuration).toBe(2)
  })
})
