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
        imageUrl: DataTypes.STRING,
        info: DataTypes.JSONB,
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
  find: (
    {
      userId,
      from,
      to,
    }: {
      userId: string
      from?: Date
      to?: Date
    },
    filter = {}
  ) => {
    const where: any = {
      UserId: userId,
    }
    if (from && to) {
      where.t = {
        [Op.between]: [from, to],
      }
    }
    return JournalModel.findAll({
      attributes: ['id', 't', 'type', 'comment', 'info'],
      where: {
        ...where,
        ...filter,
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
          sequelizeInstance.fn(
            'avg',
            sequelizeInstance.literal("info->>'painLevel'")
          ),
          'agg_painLevel',
        ],
      ],
      group: ['agg_t'],
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map((d) => ({
        // @ts-ignore
        t: d.get({ plain: true }).agg_t,
        info: {
          // @ts-ignore
          painLevel: d.agg_painLevel,
        },
      }))
    )
  },
  getLastEntry: (userId: string) => {
    return JournalModel.findOne({
      attributes: ['id', 't', 'type', 'comment', 'info'],
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
