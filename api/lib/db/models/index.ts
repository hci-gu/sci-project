import { Sequelize } from 'sequelize'
import Accel from './Accel.ts'
import AccelCount from './AccelCount.ts'
import Bout from './Bout.ts'
import Energy from './Energy.ts'
import HeartRate from './HeartRate.ts'
import User from './User.ts'
import Position from './Position.ts'
import Journal from './Journal.ts'
import Goal from './Goal.ts'

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
