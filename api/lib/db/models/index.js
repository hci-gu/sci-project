const Accel = require('./Accel')
const Energy = require('./Energy')
const HeartRate = require('./HeartRate')
const User = require('./User')

module.exports = {
  init: async (sequelize) => {
    await Promise.all([
      Accel.init(sequelize),
      HeartRate.init(sequelize),
      User.init(sequelize),
      Energy.init(sequelize),
    ])

    User.associate(sequelize.models)
    Accel.associate(sequelize.models)
    HeartRate.associate(sequelize.models)
    Energy.associate(sequelize.models)
  },
  Accel,
  HeartRate,
  User,
  Energy,
}
