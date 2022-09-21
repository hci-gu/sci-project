import { DataTypes, Op, Sequelize, ModelStatic } from 'sequelize'
import { HeartRate } from '../classes'

export type HeartRateData = {
  t: Date
  hr: number
}

let HeartRateModel: ModelStatic<HeartRate>
let sequelizeInstance: Sequelize
export default {
  init: (sequelize: Sequelize) => {
    sequelizeInstance = sequelize
    HeartRateModel = sequelize.define<HeartRate>(
      'HeartRate',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        t: DataTypes.DATE,
        hr: DataTypes.FLOAT,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return HeartRate
  },
  associate: (sequelize: Sequelize) => {
    HeartRateModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data: HeartRateData[], userId: string) =>
    Promise.all(
      data.map((d) =>
        HeartRateModel.create({
          t: new Date(d.t),
          hr: d.hr,
          UserId: userId,
        })
      )
    ),
  find: ({ userId, from, to }: { userId: string; from: Date; to: Date }) =>
    HeartRate.findAll({
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
  }) =>
    HeartRate.findAll({
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
      ],
      group: 'agg_t',
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map((d) => ({
        // @ts-ignore
        t: d.get({ plain: true }).agg_t,
        hr: d.hr,
      }))
    ),
}
