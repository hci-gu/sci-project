import { DataTypes, Op, Sequelize, ModelStatic } from 'sequelize'
import { Journal } from '../classes'

let JournalModel: ModelStatic<Journal>
export default {
  init: (sequelize: Sequelize) => {
    JournalModel = sequelize.define<Journal>(
      'Journal',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        t: DataTypes.DATE,
        type: DataTypes.STRING,
        comment: DataTypes.STRING,
        painLevel: DataTypes.INTEGER,
        bodyPart: DataTypes.STRING,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return JournalModel
  },
  associate: (sequelize: Sequelize) => {
    JournalModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data: any, userId: string) =>
    JournalModel.create({
      t: new Date(data.timestamp),
      ...data,
      UserId: userId,
    }),
  find: ({ userId }: { userId: string }) => {
    return JournalModel.findAll({
      attributes: ['id', 't', 'type', 'comment', 'painLevel', 'bodyPart'],
      where: {
        UserId: userId,
      },
      order: [['t', 'ASC']],
    })
  },
  getLastEntry: (userId: string) => {
    return JournalModel.findOne({
      attributes: ['id', 't', 'type', 'comment', 'painLevel', 'bodyPart'],
      where: {
        UserId: userId,
      },
      order: [['t', 'DESC']],
    })
  },
  delete: (id: string) => JournalModel.destroy({ where: { id } }),
  update: (id: string, data: any) =>
    JournalModel.update(data, { where: { id } }),
}
