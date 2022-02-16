const { DataTypes } = require('sequelize')

let User

module.exports = {
  init: (sequelize) => {
    sequelize.define(
      'User',
      {
        id: {
          type: DataTypes.UUID,
          defaultValue: DataTypes.UUIDV4,
          unique: true,
          primaryKey: true,
        },
        weight: DataTypes.FLOAT,
        deviceId: DataTypes.STRING,
        createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
      },
      {
        timestamps: false,
      }
    )
    User = sequelize.models.User

    return User
  },
  associate: (models) => {
    User.hasMany(models.HeartRate, {
      onDelete: 'cascade',
    })
    User.hasMany(models.Accel, {
      onDelete: 'cascade',
    })
  },
  save: (data) =>
    User.create({
      weight: data.weight,
    }),
  get: (id) => User.findOne({ where: { id } }),
}
