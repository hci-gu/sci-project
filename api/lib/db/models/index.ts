import { Sequelize } from 'sequelize'
import Accel from './Accel.js'
import AccelCount from './AccelCount.js'
import Bout from './Bout.js'
import Energy from './Energy.js'
import HeartRate from './HeartRate.js'
import User from './User.js'
import Position from './Position.js'
import Journal from './Journal.js'
import Goal from './Goal.js'

export async function init(sequelize: Sequelize) {
  await Promise.all([
    Accel.init(sequelize),
    AccelCount.init(sequelize),
    Bout.init(sequelize),
    HeartRate.init(sequelize),
    Energy.init(sequelize),
    User.init(sequelize),
    Position.init(sequelize),
    Journal.init(sequelize),
    Goal.init(sequelize),
  ])

  User.associate(sequelize)
  Accel.associate(sequelize)
  AccelCount.associate(sequelize)
  Bout.associate(sequelize)
  Energy.associate(sequelize)
  HeartRate.associate(sequelize)
  Position.associate(sequelize)
  Journal.associate(sequelize)
  Goal.associate(sequelize)
}
