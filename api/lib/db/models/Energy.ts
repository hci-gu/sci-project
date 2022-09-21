import {
  Model,
  DataTypes,
  Op,
  InferAttributes,
  InferCreationAttributes,
  Sequelize,
  CreationOptional,
  ForeignKey,
  ModelStatic,
} from 'sequelize'
import { Activity } from '../../constants'
import { User } from './User'

export class Energy extends Model<
  InferAttributes<Energy>,
  InferCreationAttributes<Energy>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare kcal: number
  declare activity: Activity

  declare UserId?: ForeignKey<User['id']>
}

interface AggregatedEnergy extends Energy {
  minutes: number
}

let sequelizeInstance: Sequelize
let EnergyModel: ModelStatic<Energy>
export default {
  init: (sequelize: Sequelize) => {
    sequelizeInstance = sequelize
    EnergyModel = sequelize.define<Energy>(
      'Energy',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        t: DataTypes.DATE,
        kcal: DataTypes.FLOAT,
        activity: DataTypes.ENUM(...Object.values(Activity)),
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return EnergyModel
  },
  associate: (sequelize: Sequelize) => {
    EnergyModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (
    data: { t: Date; kcal: number; activity: Activity }[],
    userId: string
  ) =>
    Promise.all(
      data.map((d) =>
        EnergyModel.create({
          t: d.t,
          kcal: d.kcal,
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
  }): Promise<Energy[]> =>
    EnergyModel.findAll({
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
  }): Promise<AggregatedEnergy[]> =>
    EnergyModel.findAll({
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
        [sequelizeInstance.fn('sum', sequelizeInstance.col('kcal')), 'kcal'],
        'activity',
        [
          sequelizeInstance.fn('count', sequelizeInstance.col('activity')),
          'minutes',
        ],
      ],
      group: ['agg_t', 'activity'],
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map(
        (d) =>
          ({
            // @ts-ignore
            t: d.get({ plain: true }).agg_t,
            // @ts-ignore
            minutes: parseInt(d.get({ plain: true }).minutes),
            activity: d.activity,
            kcal: d.kcal,
          } as AggregatedEnergy)
      )
    ),
}
