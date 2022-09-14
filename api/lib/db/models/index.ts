import { Sequelize } from 'sequelize'
import Accel from './Accel'
import AccelCount from './AccelCount'
import Energy from './Energy'
import HeartRate from './HeartRate'
import User from './User'

export async function init(sequelize: Sequelize) {
  await Promise.all([
    Accel.init(sequelize),
    AccelCount.init(sequelize),
    HeartRate.init(sequelize),
    User.init(sequelize),
    Energy.init(sequelize),
  ])

  User.associate(sequelize)
  Accel.associate(sequelize)
  AccelCount.associate(sequelize)
  HeartRate.associate(sequelize)
  Energy.associate(sequelize)
}

export default {
  Accel,
  AccelCount,
  HeartRate,
  User,
  Energy,
}
