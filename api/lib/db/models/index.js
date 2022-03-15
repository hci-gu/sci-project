const Accel = require('./Accel')
const AccelCount = require('./AccelCount')
const Energy = require('./Energy')
const HeartRate = require('./HeartRate')
const User = require('./User')

module.exports = {
  init: async (sequelize) => {
    await Promise.all([
      Accel.init(sequelize),
      AccelCount.init(sequelize),
      HeartRate.init(sequelize),
      User.init(sequelize),
      Energy.init(sequelize),
    ])

    User.associate(sequelize.models)
    Accel.associate(sequelize.models)
    AccelCount.associate(sequelize.models)
    HeartRate.associate(sequelize.models)
    Energy.associate(sequelize.models)
  },
  Accel,
  AccelCount,
  HeartRate,
  User,
  Energy,
}
