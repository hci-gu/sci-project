const { Sequelize, Model, DataTypes, Op } = require('sequelize')
const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB } = process.env

const sequelize = DB
  ? new Sequelize({
      define: {
        defaultScope: {
          attributes: {
            exclude: ['created_at', 'updated_at'],
          },
        },
      },
      database: DB,
      username: DB_USERNAME,
      password: DB_PASSWORD,
      host: DB_HOST,
      port: DB_PORT,
      dialect: 'postgres',
      logging: false,
    })
  : new Sequelize('sqlite::memory', { logging: false })

class Accel extends Model {}
Accel.init(
  {
    t: DataTypes.DATE,
    x: DataTypes.FLOAT,
    y: DataTypes.FLOAT,
    z: DataTypes.FLOAT,
  },
  { sequelize, modelName: 'accel', timestamps: false }
)

class HeartRate extends Model {}
HeartRate.init(
  {
    t: DataTypes.DATE,
    hr: DataTypes.FLOAT,
  },
  { sequelize, modelName: 'heartRate', timestamps: false }
)

sequelize.sync()

const types = {
  accel: Accel,
  hr: HeartRate,
}
const fieldsForType = (type) => {
  switch (type) {
    case 'accel':
      return [
        [sequelize.fn('avg', sequelize.col('x')), 'x'],
        [sequelize.fn('avg', sequelize.col('y')), 'y'],
        [sequelize.fn('avg', sequelize.col('z')), 'z'],
      ]
    case 'hr':
      return [[sequelize.fn('avg', sequelize.col('hr')), 'hr']]
    default:
      return []
      break
  }
}

module.exports = {
  saveAccel: (data) =>
    Promise.all(
      data.map((d) =>
        Accel.create({
          t: d.t,
          x: d.v[0],
          y: d.v[1],
          z: d.v[2],
        })
      )
    ),
  saveHr: (data) =>
    Promise.all(
      data.map((d) =>
        HeartRate.create({
          t: d.t,
          hr: d.v,
        })
      )
    ),
  get: ({ type, from, to }) =>
    types[type].findAll({
      where: {
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
  aggregate: async ({ type, from, to, unit = 'minute' }) => {
    const docs = await types[type].findAll({
      where: {
        t: {
          [Op.between]: [from, to],
        },
      },
      attributes: [
        [sequelize.fn('date_trunc', unit, sequelize.col('t')), 'agg_t'],
        ...fieldsForType(type),
      ],
      group: 'agg_t',
      order: [[sequelize.col('agg_t'), 'ASC']],
    })

    if (type === 'accel') {
      return docs.map((d) => ({
        t: d.get({ plain: true }).agg_t,
        x: d.x,
        y: d.y,
        z: d.z,
      }))
    } else {
      return docs.map((d) => ({
        t: d.get({ plain: true }).agg_t,
        hr: d.hr,
      }))
    }
  },
}
