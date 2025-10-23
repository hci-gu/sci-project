import { DataTypes, Op, Sequelize, type ModelStatic } from 'sequelize'
import { Image } from '../classes.js'

let ImageModel: ModelStatic<Image>
export default {
  init: (sequelize: Sequelize) => {
    ImageModel = sequelize.define<Image>(
      'Image',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        data: DataTypes.BLOB('long'),
        prompt: DataTypes.TEXT,
        createdAt: DataTypes.DATE,
        updatedAt: DataTypes.DATE,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return ImageModel
  },
  associate: (sequelize: Sequelize) => {
    ImageModel.belongsTo(sequelize.models.User, {
      foreignKey: 'UserId',
      as: 'user',
    })
  },
  save: (data: any, userId: string) => {
    return ImageModel.create({
      ...data,
      UserId: userId,
    })
  },
  findOne: ({ userId }: { userId: string }) => {
    return ImageModel.findOne({
      where: { UserId: userId },
    })
  },
}
