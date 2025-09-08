import { DataTypes, Op, Sequelize, type ModelStatic } from 'sequelize'
import { Position } from '../classes.js'

let PositionModel: ModelStatic<Position>
export default {
  init: (sequelize: Sequelize) => {
    PositionModel = sequelize.define<Position>(
      'Position',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        t: DataTypes.DATE,
        longitude: DataTypes.FLOAT,
        latitude: DataTypes.FLOAT,
        accuracy: DataTypes.FLOAT,
        altitude: DataTypes.FLOAT,
        floor: DataTypes.FLOAT,
        speed: DataTypes.FLOAT,
        heading: DataTypes.FLOAT,
        speed_accuracy: DataTypes.FLOAT,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return PositionModel
  },
  associate: (sequelize: Sequelize) => {
    PositionModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data: any, userId: string) =>
    PositionModel.create({
      t: new Date(data.timestamp),
      ...data,
      UserId: userId,
    }),
}
