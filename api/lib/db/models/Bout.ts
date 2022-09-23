import moment from 'moment'
import { DataTypes, Op, Sequelize, ModelStatic } from 'sequelize'
import { activityForAccAndCondition } from '../../adapters/energy'
import { Activity } from '../../constants'
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
    data: { t: Date; minutes: number; activity: Activity },
    userId: string
  ) =>
    BoutModel.create({
      t: data.t,
      minutes: data.minutes,
      activity: data.activity,
      UserId: userId,
    }),
  find: ({
    userId,
    from,
    to,
  }: {
    userId: string
    from: Date
    to: Date
  }): Promise<Bout[]> =>
    Bout.findAll({
      where: {
        UserId: userId,
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
  // get average acc for counts
  const avgAcc = counts.reduce((acc, c) => acc + c.a, 0) / counts.length

  // get the activity level from average acc
  const activity = activityForAccAndCondition(avgAcc, user.condition)

  // lookup last bout
  const lastBout = await BoutModel.findOne({
    attributes: ['id', 't', 'activity', 'minutes'],
    where: {
      UserId: user.id,
    },
    order: [['t', 'DESC']],
  })

  // if it doesn't exist or is more than 5 minutes ago, create a new one
  const fiveMinAgo = moment().subtract(5, 'minutes')
  const doesntExistOrIsOld =
    !lastBout ||
    moment(lastBout.t).add(lastBout.minutes, 'minutes').isBefore(fiveMinAgo)

  // if activity is different from current bout or there is no bout, create a new bout
  if (doesntExistOrIsOld || lastBout.activity !== activity) {
    const bout = await Model.save(
      {
        t: counts[counts.length - 1].t,
        minutes: 1,
        activity,
      },
      user.id
    )
    return bout
  }

  // if activity is same as current bout, update number of minutes to it
  lastBout.minutes += 1
  await lastBout.save()
  return lastBout
}
