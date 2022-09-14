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
import { User } from './User'

export class AccelCount extends Model<
  InferAttributes<AccelCount>,
  InferCreationAttributes<AccelCount>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare hr: number
  declare a: number

  declare UserId?: ForeignKey<User['id']>
}

let AccelCountModel: ModelStatic<AccelCount>
export default {
  init: (sequelize: Sequelize) => {
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
  find: ({ userId, from, to }: { userId: string; from: Date; to: Date }) =>
    AccelCountModel.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
}
