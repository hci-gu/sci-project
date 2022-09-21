import { Sequelize } from 'sequelize'
import { init } from './models'

type DBProps = {
  database: string
  username: string
  password: string
  host: string
  port: number
}

export default async (conf?: DBProps) => {
  const sequelize = conf
    ? new Sequelize({
        define: {
          defaultScope: {
            attributes: {
              exclude: ['created_at', 'updated_at'],
            },
          },
        },
        dialect: 'postgres',
        logging: false,
        ...conf,
      })
    : new Sequelize('sqlite::memory', { logging: false })

  try {
    if (conf) await sequelize.query(`CREATE DATABASE ${conf.database}`)
  } catch (e) {}

  await init(sequelize)
  await sequelize.sync()

  return sequelize
}
