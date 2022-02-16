const { Sequelize } = require('sequelize')
const models = require('./models')

module.exports = (conf) => {
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

  models.init(sequelize)

  sequelize.sync()
}
