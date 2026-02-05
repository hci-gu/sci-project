import db from '../../lib/db'
import moment from 'moment'
import { AccelCount, User } from '../../lib/db/classes'
import UserModel from '../../lib/db/models/User'
import AccelCountModel from '../../lib/db/models/AccelCount'
import BoutModel, { createBoutFromCounts } from '../../lib/db/models/Bout'
import {
  Activity,
  Condition,
  SEDENTARY_THRESHOLD,
} from '../../lib/constants'

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

const createCountsAtTimes = (times: Date[], a: number) =>
  times.map(
    (t) =>
      ({
        t,
        a,
        hr: 60,
      }) as AccelCount
  )

const createAccelRows = (
  start: moment.Moment,
  length: number,
  a: number
) => {
  return Array.from({ length }).map((_, i) => ({
    t: start.clone().add(i, 'minutes').toDate(),
    a,
    hr: 60,
  }))
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
    const base = moment().startOf('minute')
    const counts = createCountsAtTimes(
      [
        base.clone().subtract(4, 'minutes').toDate(),
        base.clone().subtract(3, 'minutes').toDate(),
        base.clone().subtract(2, 'minutes').toDate(),
        base.clone().subtract(1, 'minutes').toDate(),
        base.toDate(),
      ],
      SEDENTARY_THRESHOLD - 1000
    )

    const bout = await createBoutFromCounts(user, counts)
    expect(bout.minutes).toBe(1)
    expect(bout.activity).toBe(Activity.sedentary)

    const nextCounts = createCountsAtTimes(
      [
        base.clone().subtract(3, 'minutes').toDate(),
        base.clone().subtract(2, 'minutes').toDate(),
        base.clone().subtract(1, 'minutes').toDate(),
        base.toDate(),
        base.clone().add(1, 'minute').toDate(),
      ],
      SEDENTARY_THRESHOLD - 1000
    )
    const bout2 = await createBoutFromCounts(user, nextCounts)

    expect(bout2.minutes).toBe(2)
    expect(bout2.activity).toBe(Activity.sedentary)
  })

  test('bulk backfill does not extend a future bout', async () => {
    const later = moment().startOf('day').add(12, 'hours')
    await BoutModel.save(
      {
        t: later.toDate(),
        minutes: 5,
        activity: Activity.sedentary,
        data: {},
      },
      user.id
    )

    const earlier = later.clone().subtract(3, 'hours')
    const rows = createAccelRows(
      earlier,
      5,
      SEDENTARY_THRESHOLD - 1000
    )

    await AccelCountModel.bulkSave(rows, user.id)

    const bouts = await BoutModel.find({
      userId: user.id,
      from: earlier.clone().subtract(30, 'minutes').toDate(),
      to: later.clone().add(30, 'minutes').toDate(),
    })

    const latest = bouts[bouts.length - 1]
    expect(latest.activity).toBe(Activity.sedentary)
    expect(latest.minutes).toBe(5)
  })

  test('bulk save merges adjacent same-activity bouts within batch window', async () => {
    const base = moment().startOf('day').add(10, 'hours')
    await BoutModel.save(
      {
        t: base.toDate(),
        minutes: 10,
        activity: Activity.sedentary,
        data: {},
      },
      user.id
    )
    await BoutModel.save(
      {
        t: base.clone().add(15, 'minutes').toDate(),
        minutes: 5,
        activity: Activity.sedentary,
        data: {},
      },
      user.id
    )

    const rows = createAccelRows(
      base.clone().add(6, 'minutes'),
      5,
      SEDENTARY_THRESHOLD - 1000
    )

    await AccelCountModel.bulkSave(rows, user.id)

    const bouts = await BoutModel.find({
      userId: user.id,
      from: base.clone().subtract(30, 'minutes').toDate(),
      to: base.clone().add(30, 'minutes').toDate(),
    })

    const sedentary = bouts.filter(
      (bout) => bout.activity === Activity.sedentary
    )
    expect(sedentary).toHaveLength(1)
    expect(sedentary[0].minutes).toBe(20)
  })
})
