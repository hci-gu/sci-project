import { DataTypes, Sequelize, type ModelStatic } from 'sequelize'
import { NotificationEvent } from '../classes.js'

let NotificationEventModel: ModelStatic<NotificationEvent>
export default {
  init: (sequelize: Sequelize) => {
    NotificationEventModel = sequelize.define<NotificationEvent>(
      'NotificationEvent',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        title: {
          type: DataTypes.STRING,
          allowNull: false,
        },
        body: {
          type: DataTypes.TEXT,
          allowNull: false,
        },
        timestamp: {
          type: DataTypes.DATE,
          allowNull: false,
          defaultValue: DataTypes.NOW,
        },
        reason: {
          type: DataTypes.STRING,
          allowNull: false,
        },
        userId: {
          type: DataTypes.UUID,
          allowNull: false,
        },
      },
      {
        timestamps: false,
      }
    )

    return NotificationEventModel
  },
  associate: (sequelize: Sequelize) => {
    NotificationEventModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        name: 'userId',
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: ({
    title,
    body,
    timestamp,
    reason,
    userId,
  }: {
    title: string
    body: string
    timestamp?: Date
    reason: string
    userId: string
  }) =>
    NotificationEventModel.create({
      title,
      body,
      timestamp: timestamp ?? new Date(),
      reason,
      userId,
    }),
}
