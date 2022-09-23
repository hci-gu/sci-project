import db from '../../lib/db'
import moment from 'moment'
import { AccelCount, User } from '../../lib/db/classes'
import UserModel from '../../lib/db/models/User'
import AccelCountModel from '../../lib/db/models/AccelCount'
import { createBoutFromCounts } from '../../lib/db/models/Bout'
import { Activity, Condition, SEDENTARY_THRESHOLD } from '../../lib/constants'

beforeEach(async () => {
  await db()
})

const createAccelCounts = (length: number, a: number, start = new Date()) => {
  return Array.from({ length }).map((_, i) => {
    const t = moment(start)
      .subtract(i + 1, 'minutes')
      .toDate()
    return {
      t,
      a,
      hr: 60,
    }
  })
}

describe('Bout', () => {
  let user: User
  beforeEach(async () => {
    user = await UserModel.save({
      weight: 60,
      condition: Condition.paraplegic,
    })
  })

  test('creates correct bout from count', async () => {
    // sedentary for last 5 minutes
    const counts = await AccelCountModel.save(
      createAccelCounts(5, SEDENTARY_THRESHOLD - 1000),
      user.id
    )

    const bout = await createBoutFromCounts(user, counts)

    expect(bout.minutes).toBe(1)
    expect(bout.activity).toBe(Activity.sedentary)
  })

  test('Adds minute to bout if there is one ongoing', async () => {
    // sedentary for last 5 minutes
    const counts = await AccelCountModel.save(
      createAccelCounts(
        5,
        SEDENTARY_THRESHOLD - 1000,
        moment().subtract(1, 'minutes').toDate()
      ),
      user.id
    )

    const bout = await createBoutFromCounts(user, counts)
    expect(bout.minutes).toBe(1)
    expect(bout.activity).toBe(Activity.sedentary)

    // still sedentary
    const count = {
      t: new Date(),
      a: 0,
      hr: 60,
    } as AccelCount

    const bout2 = await createBoutFromCounts(user, [...counts.slice(1), count])

    expect(bout2.minutes).toBe(2)
    expect(bout2.activity).toBe(Activity.sedentary)
  })
})
