import db from '../../../lib/db'
import * as utils from '../../../lib/routes/sedentary/utils'
import AccelCountModel, { AccelCount } from '../../../lib/db/models/AccelCount'

jest.mock('../../../lib/db/models/AccelCount')

const AccelCountFindMock = AccelCountModel.find as jest.MockedFunction<
  typeof AccelCountModel.find
>

// jest.mock('../../../lib/db/models/index.js')

beforeEach(async () => {
  await db()
})

describe('activityForPeriod', () => {
  it('works', async () => {
    AccelCountFindMock.mockResolvedValue([
      {
        t: new Date('2022-01-01T00:00:00Z'),
        a: 0,
        hr: 60,
      },
      {
        t: new Date('2022-01-01T00:01:00Z'),
        a: 5000,
        hr: 60,
      },
      {
        t: new Date('2022-01-01T00:02:00Z'),
        a: 0,
        hr: 60,
      },
      {
        t: new Date('2022-01-01T00:03:00Z'),
        a: 0,
        hr: 60,
      },
      {
        t: new Date('2022-01-01T00:04:00Z'),
        a: 0,
        hr: 60,
      },
    ] as AccelCount[])
    const result = await utils.activityForPeriod({
      id: '-1',
      from: new Date('2022-01-01T00:00:00Z'),
      to: new Date('2022-01-01T00:04:00Z'),
    })
    expect(AccelCountFindMock).toHaveBeenCalledTimes(1)
    expect(result.minutesInactive).toBe(3)
    expect(result.averageInactiveDuration).toBe(2)
  })
})
