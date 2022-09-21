import { DataTypes, Op, Sequelize, ModelStatic } from 'sequelize'
import {
  getEnergyForCountAndActivity,
  activityForAccAndCondition,
} from '../../adapters/energy'
import UserModel from './User'
import EnergyModel from './Energy'
import { AccelCount } from '../classes'

const afterCreate = async (count: AccelCount) => {
  if (!count.UserId) return
  const user = await UserModel.get(count.UserId)

  if (!user) return

  const activity = activityForAccAndCondition(count.a, user.condition)
  const kcal = getEnergyForCountAndActivity(user, count)

  await EnergyModel.save(
    [
      {
        t: count.t,
        activity,
        kcal,
      },
    ],
    count.UserId
  )
}

let sequelizeInstance: Sequelize
let AccelCountModel: ModelStatic<AccelCount>
export default {
  init: (sequelize: Sequelize) => {
    sequelizeInstance = sequelize
    AccelCountModel = sequelize.define<AccelCount>(
      'AccelCount',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        t: DataTypes.DATE,
        hr: DataTypes.FLOAT,
        a: DataTypes.FLOAT,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
        hooks: {
          afterCreate,
        },
      }
    )
    return AccelCount
  },
  associate: (sequelize: Sequelize) => {
    AccelCountModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data: any[], userId: string) =>
    Promise.all(
      data.map((d) =>
        AccelCountModel.create({
          t: d.t,
          a: d.a,
          hr: d.hr,
          UserId: userId,
        })
      )
    ),
  find: ({
    userId,
    from,
    to,
  }: {
    userId: string
    from: Date
    to: Date
  }): Promise<AccelCount[]> =>
    AccelCountModel.findAll({
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
  }): Promise<AccelCount[]> =>
    AccelCountModel.findAll({
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
        [sequelizeInstance.fn('avg', sequelizeInstance.col('hr')), 'hr'],
        [sequelizeInstance.fn('avg', sequelizeInstance.col('a')), 'a'],
      ],
      group: 'agg_t',
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map(
        (d) =>
          ({
            // @ts-ignore
            t: d.get({ plain: true }).agg_t,
            hr: d.hr,
            a: d.a,
          } as AccelCount)
      )
    ),
}
