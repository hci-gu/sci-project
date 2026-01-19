import moment from 'moment'
import { DataTypes, Op, Sequelize, type ModelStatic } from 'sequelize'
import { activityForAccAndCondition } from '../../adapters/energy/index.js'
import {
  Activity,
  MINUTES_FOR_SLEEP,
  BOUT_GAP_TOLERANCE_MINUTES,
  BOUT_MERGE_MAX_GAP_MINUTES,
} from '../../constants.js'
import { AccelCount, Bout, User } from '../classes.js'

let sequelizeInstance: Sequelize
let BoutModel: ModelStatic<Bout>
const Model = {
  init: (sequelize: Sequelize) => {
    sequelizeInstance = sequelize
    BoutModel = sequelize.define<Bout>(
      'Bout',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        t: DataTypes.DATE,
        minutes: DataTypes.INTEGER,
        activity: DataTypes.ENUM(...Object.values(Activity)),
        isSleeping: {
          type: DataTypes.BOOLEAN,
          defaultValue: false,
        },
        data: DataTypes.JSONB,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return BoutModel
  },
  associate: (sequelize: Sequelize) => {
    BoutModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (
    bout: { t: Date; minutes: number; activity: Activity; data: any },
    userId: string
  ) =>
    BoutModel.create({
      t: bout.t,
      minutes: bout.minutes,
      activity: bout.activity,
      UserId: userId,
      isSleeping: false,
      data: bout.data,
    }),
  get: (id: string) => BoutModel.findOne({ where: { id } }),
  remove: (id: string) => BoutModel.destroy({ where: { id } }),
  find: ({
    userId,
    from,
    to,
  }: {
    userId: string
    from: Date
    to: Date
  }): Promise<Bout[]> =>
    BoutModel.findAll({
      attributes: ['id', 't', 'activity', 'minutes'],
      where: {
        UserId: userId,
        isSleeping: false,
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
  group: ({
    userId,
    from,
    to,
    unit = 'minute',
  }: {
    userId: string
    from: Date
    to: Date
    unit: string
  }): Promise<Bout[]> =>
    BoutModel.findAll({
      where: {
        UserId: userId,
        isSleeping: false,
        t: {
          [Op.between]: [from, to],
        },
      },
      attributes: [
        [
          sequelizeInstance.fn('date_trunc', unit, sequelizeInstance.col('t')),
          'agg_t',
        ],
        [
          sequelizeInstance.fn('avg', sequelizeInstance.col('minutes')),
          'minutes',
        ],
        'activity',
      ],
      group: ['agg_t', 'activity'],
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map(
        (d) =>
          ({
            // @ts-ignore
            t: d.get({ plain: true }).agg_t,
            minutes: d.get({ plain: true }).minutes,
            activity: d.activity,
          } as Bout)
      )
    ),
}

export default Model

export const createBoutFromCounts = async (
  user: User,
  counts: AccelCount[]
) => {
  const activities = counts.map((count) =>
    activityForAccAndCondition(count.a, user.condition)
  )

  // get majority activity from activities
  const activity = activities
    .sort(
      (a, b) =>
        activities.filter((v) => v === a).length -
        activities.filter((v) => v === b).length
    )
    .pop()

  // get average acc for counts
  //const avgAcc = counts.reduce((acc, c) => acc + c.a, 0) / counts.length

  // get the activity level from average acc
  // const activity = activityForAccAndCondition(avgAcc, user.condition)

  // lookup last bout
  const lastBout = await BoutModel.findOne({
    attributes: ['id', 't', 'activity', 'minutes'],
    where: {
      UserId: user.id,
      activity: {
        [Op.in]: [Activity.sedentary, Activity.moving, Activity.active],
      },
    },
    order: [['t', 'DESC']],
  })

  // if it doesn't exist
  if (!lastBout) {
    const bout = await Model.save(
      {
        t: counts[counts.length - 1].t,
        minutes: 1,
        activity: activity ?? Activity.sedentary,
        data: {},
      },
      user.id
    )
    return bout
  }

  const lastCountTime = counts[counts.length - 1].t
  const gapToleranceAgo = moment(lastCountTime).subtract(
    BOUT_GAP_TOLERANCE_MINUTES,
    'minutes'
  )
  const boutEnd = moment(lastBout.t).add(lastBout.minutes, 'minutes')

  // if activity is different from current bout, or gap exceeds tolerance, create a new bout
  if (boutEnd.isBefore(gapToleranceAgo) || lastBout.activity !== activity) {
    const bout = await Model.save(
      {
        t: counts[counts.length - 1].t,
        minutes: 1,
        activity: activity ?? Activity.sedentary,
        data: {},
      },
      user.id
    )
    return bout
  }

  // if activity is same as current bout, extend by the gap duration (fill the gap)
  const gapMinutes = moment(lastCountTime).diff(boutEnd, 'minutes')
  lastBout.minutes += Math.max(1, gapMinutes + 1)

  const middleOfTheNight = moment().set('hour', 4)
  if (
    lastBout.minutes > MINUTES_FOR_SLEEP &&
    middleOfTheNight.isBetween(lastBout.t, boutEnd)
  ) {
    lastBout.isSleeping = true
  }

  await lastBout.save()
  return lastBout
}

export const createBoutsFromBatch = async (
  user: User,
  rows: { t: Date; a: number; hr: number }[]
) => {
  if (!rows?.length) return

  // sort, in case caller forgot
  rows.sort((x, y) => new Date(x.t).getTime() - new Date(y.t).getTime())

  // use a single transaction to avoid races
  await sequelizeInstance.transaction(async (t) => {
    // walk a 5-minute sliding window over the rows
    for (let i = 4; i < rows.length; i++) {
      const window = rows.slice(i - 4, i + 1) // 5 items
      // guard: ensure they are consecutive minutes — optional depending on your data
      // if (!areConsecutiveMinutes(window)) continue;

      const activities = window.map((c) =>
        activityForAccAndCondition(c.a, user.condition)
      )

      // majority vote
      const activity = activities
        .sort(
          (a, b) =>
            activities.filter((v) => v === a).length -
            activities.filter((v) => v === b).length
        )
        .pop()

      // the "current minute" time is the last element in the window
      const currentT = window[window.length - 1].t

      // Extend or create bout based on *currentT*
      await upsertBoutAtMinute(user, activity ?? Activity.sedentary, currentT, {
        transaction: t,
      })
    }
  })
}

// Helper: extend or create a bout at the given minute
const upsertBoutAtMinute = async (
  user: User,
  activity: Activity,
  minuteT: Date,
  options?: { transaction?: any }
) => {
  // fetch latest bout in the activity set (non-sleeping)
  const lastBout = await BoutModel.findOne({
    attributes: ['id', 't', 'activity', 'minutes', 'isSleeping'],
    where: {
      UserId: user.id,
      isSleeping: false,
      activity: {
        [Op.in]: [Activity.sedentary, Activity.moving, Activity.active],
      },
    },
    order: [['t', 'DESC']],
    transaction: options?.transaction,
    lock: options?.transaction ? options.transaction.LOCK.UPDATE : undefined, // pessimistic if supported
  })

  const gapToleranceAgo = moment(minuteT).subtract(
    BOUT_GAP_TOLERANCE_MINUTES,
    'minutes'
  )
  const boutEnd = moment(lastBout?.t).add(lastBout?.minutes ?? 0, 'minutes')

  if (
    !lastBout ||
    boutEnd.isBefore(gapToleranceAgo) ||
    lastBout.activity !== activity
  ) {
    // start a new 1-minute bout at minuteT
    await BoutModel.create(
      {
        t: minuteT,
        minutes: 1,
        activity,
        UserId: user.id,
        isSleeping: false,
        data: {},
      },
      { transaction: options?.transaction }
    )
    return
  }

  // Same activity & within gap tolerance → extend by filling the gap
  const gapMinutes = moment(minuteT).diff(boutEnd, 'minutes')
  const newMinutes = lastBout.minutes + Math.max(1, gapMinutes + 1)

  await BoutModel.update(
    { minutes: newMinutes },
    { where: { id: lastBout.id }, transaction: options?.transaction }
  )

  // Sleep flip (optional – same logic but relative to minuteT)
  const updatedBoutEnd = moment(lastBout.t).add(newMinutes, 'minutes')
  const middleOfTheNight = moment(minuteT)
    .set('hour', 4)
    .set('minute', 0)
    .set('second', 0)
  if (
    newMinutes > MINUTES_FOR_SLEEP &&
    middleOfTheNight.isBetween(lastBout.t, updatedBoutEnd)
  ) {
    await BoutModel.update(
      { isSleeping: true },
      { where: { id: lastBout.id }, transaction: options?.transaction }
    )
  }
}

/**
 * Merge adjacent bouts of the same activity type that have small gaps between them.
 * This repairs fragmented bout data caused by data gaps or timing issues.
 */
export const mergeBouts = async (
  userId: string,
  options?: { maxGapMinutes?: number; from?: Date; to?: Date }
) => {
  const maxGap = options?.maxGapMinutes ?? BOUT_MERGE_MAX_GAP_MINUTES

  const whereClause: any = {
    UserId: userId,
    isSleeping: false,
    activity: {
      [Op.in]: [Activity.sedentary, Activity.moving, Activity.active],
    },
  }

  if (options?.from && options?.to) {
    whereClause.t = { [Op.between]: [options.from, options.to] }
  }

  const bouts = await BoutModel.findAll({
    attributes: ['id', 't', 'activity', 'minutes'],
    where: whereClause,
    order: [['t', 'ASC']],
  })

  if (bouts.length < 2) return { merged: 0, deleted: 0 }

  const toDelete: number[] = []
  let current = bouts[0]
  let mergeCount = 0

  for (let i = 1; i < bouts.length; i++) {
    const bout = bouts[i]
    const currentEnd = moment(current.t).add(current.minutes, 'minutes')
    const gap = moment(bout.t).diff(currentEnd, 'minutes')

    // Merge if same activity and gap is within tolerance
    if (current.activity === bout.activity && gap <= maxGap && gap >= 0) {
      // Extend current bout to include the gap and the next bout
      current.minutes += gap + bout.minutes
      toDelete.push(bout.id)
      mergeCount++
    } else {
      // Save the current bout and move to next
      if (current.changed()) {
        await current.save()
      }
      current = bout
    }
  }

  // Save the last bout if modified
  if (current.changed()) {
    await current.save()
  }

  // Delete merged bouts
  if (toDelete.length > 0) {
    await BoutModel.destroy({ where: { id: { [Op.in]: toDelete } } })
  }

  return { merged: mergeCount, deleted: toDelete.length }
}
