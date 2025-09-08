import moment from 'moment'
import { DataTypes, Op, Sequelize, type ModelStatic } from 'sequelize'
import { activityForAccAndCondition } from '../../adapters/energy/index.js'
import { Activity, MINUTES_FOR_SLEEP } from '../../constants.js'
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
  const fiveMinAgo = moment(lastCountTime).subtract(5, 'minutes')
  const boutEnd = moment(lastBout.t).add(lastBout.minutes, 'minutes')

  // if activity is different from current bout, create a new bout
  if (boutEnd.isBefore(fiveMinAgo) || lastBout.activity !== activity) {
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

  // if activity is same as current bout, update number of minutes to it
  lastBout.minutes += 1

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

  const fiveMinAgo = moment(minuteT).subtract(5, 'minutes')

  if (
    !lastBout ||
    moment(lastBout.t).add(lastBout.minutes, 'minutes').isBefore(fiveMinAgo) ||
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

  // Same activity & still contiguous → extend
  await BoutModel.update(
    { minutes: lastBout.minutes + 1 },
    { where: { id: lastBout.id }, transaction: options?.transaction }
  )

  // Sleep flip (optional – same logic but relative to minuteT)
  const boutEnd = moment(lastBout.t).add(lastBout.minutes + 1, 'minutes')
  const middleOfTheNight = moment(minuteT)
    .set('hour', 4)
    .set('minute', 0)
    .set('second', 0)
  if (
    lastBout.minutes + 1 > MINUTES_FOR_SLEEP &&
    middleOfTheNight.isBetween(lastBout.t, boutEnd)
  ) {
    await BoutModel.update(
      { isSleeping: true },
      { where: { id: lastBout.id }, transaction: options?.transaction }
    )
  }
}
