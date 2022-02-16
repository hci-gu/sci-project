const { Sequelize, Model, DataTypes, Op } = require('sequelize')
const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB } = process.env

const Accel = require('./Accel')
const HeartRate = require('./HeartRate')
const User = require('./User')

const sequelize = DB
  ? new Sequelize({
      define: {
        defaultScope: {
          attributes: {
            exclude: ['created_at', 'updated_at'],
          },
        },
      },
      database: DB,
      username: DB_USERNAME,
      password: DB_PASSWORD,
      host: DB_HOST,
      port: DB_PORT,
      dialect: 'postgres',
      logging: false,
    })
  : new Sequelize('sqlite::memory', { logging: false })

Accel.init(sequelize)
HeartRate.init(sequelize)
User.init(sequelize)

User.associate(sequelize.models)
Accel.associate(sequelize.models)
HeartRate.associate(sequelize.models)

sequelize.sync()

module.exports = {
  HeartRate,
  Accel,
  User,
}
