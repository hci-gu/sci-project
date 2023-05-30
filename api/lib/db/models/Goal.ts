import { DataTypes, Sequelize, ModelStatic } from 'sequelize'
import { Goal } from '../classes'

let GoalModel: ModelStatic<Goal>
export default {
  init: (sequelize: Sequelize) => {
    GoalModel = sequelize.define<Goal>(
      'Goal',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        type: DataTypes.STRING,
        journalType: DataTypes.STRING,
        timeFrame: DataTypes.STRING,
        value: DataTypes.INTEGER,
        start: DataTypes.STRING,
        info: DataTypes.JSONB,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return GoalModel
  },
  associate: (sequelize: Sequelize) => {
    GoalModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data: any, userId: string) =>
    GoalModel.create({
      ...data,
      UserId: userId,
    }),
  find: ({ userId }: { userId: string }) => {
    return GoalModel.findAll({
      attributes: [
        'id',
        'type',
        'journalType',
        'timeFrame',
        'value',
        'start',
        'info',
      ],
      where: {
        UserId: userId,
      },
    })
  },
  delete: (id: string) =>
    GoalModel.destroy({
      where: {
        id,
      },
    }),
  update: (id: string, data: any) =>
    GoalModel.update(
      {
        ...data,
      },
      {
        where: {
          id,
        },
      }
    ),
}
