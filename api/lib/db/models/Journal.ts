import { DataTypes, Op, Sequelize, ModelStatic } from 'sequelize'
import { Journal } from '../classes'

let sequelizeInstance: Sequelize
let JournalModel: ModelStatic<Journal>
export default {
  init: (sequelize: Sequelize) => {
    sequelizeInstance = sequelize
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
  group: ({ userId }: { userId: string }) => {
    return JournalModel.findAll({
      where: {
        UserId: userId,
      },
      attributes: [
        [
          sequelizeInstance.fn('date_trunc', 'day', sequelizeInstance.col('t')),
          'agg_t',
        ],
        [
          sequelizeInstance.fn('avg', sequelizeInstance.col('painLevel')),
          'painLevel',
        ],
      ],
      group: ['agg_t'],
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map((d) => ({
        // @ts-ignore
        t: d.get({ plain: true }).agg_t,
        painLevel: d.painLevel,
      }))
    )
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
