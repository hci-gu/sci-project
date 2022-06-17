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
        gender: DataTypes.ENUM('male', 'female', 'other'),
        condition: DataTypes.ENUM('paraplegic', 'tetraplegic', 'none'),
        injuryLevel: DataTypes.INTEGER,
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
  getAll: () => User.findAll(),
}
