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

export class Energy extends Model<
  InferAttributes<Energy>,
  InferCreationAttributes<Energy>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare value: number

  declare UserId?: ForeignKey<User['id']>
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
        value: DataTypes.FLOAT,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return Energy
  },
  associate: (sequelize: Sequelize) => {
    EnergyModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data: any[], userId: string) =>
    Promise.all(
      data
        .filter((d) => d.energy)
        .map((d) =>
          EnergyModel.create({
            t: d.minute,
            value: d.energy,
            UserId: userId,
          })
        )
    ),
  find: ({ userId, from, to }: { userId: string; from: string; to: string }) =>
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
    from: string
    to: string
    unit: string
  }) =>
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
        [sequelizeInstance.fn('sum', sequelizeInstance.col('value')), 'value'],
      ],
      group: 'agg_t',
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map((d) => ({
        //@ts-ignore
        t: d.get({ plain: true }).agg_t,
        value: d.value,
      }))
    ),
}
