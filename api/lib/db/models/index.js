const Accel = require('./Accel')
const HeartRate = require('./HeartRate')
const User = require('./User')

module.exports = {
  init: (sequelize) => {
    Accel.init(sequelize)
    HeartRate.init(sequelize)
    User.init(sequelize)

    User.associate(sequelize.models)
    Accel.associate(sequelize.models)
    HeartRate.associate(sequelize.models)
  },
  Accel,
  HeartRate,
  User,
}
