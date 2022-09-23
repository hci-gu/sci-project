import { Sequelize } from 'sequelize'
import Accel from './Accel'
import AccelCount from './AccelCount'
import Bout from './Bout'
import Energy from './Energy'
import HeartRate from './HeartRate'
import User from './User'

export async function init(sequelize: Sequelize) {
  await Promise.all([
    Accel.init(sequelize),
    AccelCount.init(sequelize),
    Bout.init(sequelize),
    HeartRate.init(sequelize),
    Energy.init(sequelize),
    User.init(sequelize),
  ])

  User.associate(sequelize)
  Accel.associate(sequelize)
  AccelCount.associate(sequelize)
  Bout.associate(sequelize)
  Energy.associate(sequelize)
  HeartRate.associate(sequelize)
}
