const { Sequelize } = require('sequelize')
const models = require('./models')

module.exports = async (conf) => {
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
    await sequelize.query(`CREATE DATABASE ${conf.DB}`)
  } catch (e) {}

  await models.init(sequelize)
  await sequelize.sync()

  return sequelize
}
