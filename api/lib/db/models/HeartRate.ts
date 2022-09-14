import {
  Model,
  DataTypes,
  Op,
  InferAttributes,
  InferCreationAttributes,
  Sequelize,
  CreationOptional,
  NonAttribute,
  ForeignKey,
  ModelStatic,
} from 'sequelize'
import { User } from './User'

export class HeartRate extends Model<
  InferAttributes<HeartRate>,
  InferCreationAttributes<HeartRate>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare hr: number

  declare UserId?: ForeignKey<User['id']>
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
  save: (data: any[], userId: string) =>
    Promise.all(
      data.map((d) =>
        HeartRateModel.create({
          ...d,
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
