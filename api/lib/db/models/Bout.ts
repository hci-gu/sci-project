import { DataTypes, Op, Sequelize, ModelStatic } from 'sequelize'
import { Activity } from '../../constants'
import { Bout } from '../classes'

let sequelizeInstance: Sequelize
let BoutModel: ModelStatic<Bout>
export default {
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
    data: { t: Date; minutes: number; activity: Activity }[],
    userId: string
  ) =>
    Promise.all(
      data.map((d) =>
        BoutModel.create({
          t: d.t,
          minutes: d.minutes,
          activity: d.activity,
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
