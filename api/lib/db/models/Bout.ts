import moment from 'moment'
import { DataTypes, Op, Sequelize, ModelStatic } from 'sequelize'
import { activityForAccAndCondition } from '../../adapters/energy'
import AccelCountModel from './AccelCount'
import { Activity, MINUTES_FOR_SLEEP } from '../../constants'
import { AccelCount, Bout, User } from '../classes'

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

  const fiveMinAgo = moment().subtract(5, 'minutes')
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
