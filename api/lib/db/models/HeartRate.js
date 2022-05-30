const { DataTypes, Op } = require('sequelize')

let HeartRate
let sequelize

module.exports = {
  init: (_sequelize) => {
    sequelize = _sequelize
    sequelize.define(
      'HeartRate',
      {
        t: DataTypes.DATE,
        hr: DataTypes.FLOAT,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    HeartRate = sequelize.models.HeartRate
    return HeartRate
  },
  associate: (models) => {
    HeartRate.belongsTo(models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data, userId) =>
    Promise.all(
      data.map((d) =>
        HeartRate.create({
          ...d,
          UserId: userId,
        })
      )
    ),
  find: ({ userId, from, to }) =>
    HeartRate.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
  group: ({ userId, from, to, unit = 'minute' }) =>
    HeartRate.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      attributes: [
        [sequelize.fn('date_trunc', unit, sequelize.col('t')), 'agg_t'],
        [sequelize.fn('avg', sequelize.col('hr')), 'hr'],
      ],
      group: 'agg_t',
      order: [[sequelize.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map((d) => ({
        t: d.get({ plain: true }).agg_t,
        hr: d.hr,
      }))
    ),
}
