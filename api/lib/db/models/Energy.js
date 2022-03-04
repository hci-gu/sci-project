const { DataTypes, Op } = require('sequelize')

let Energy
let sequelize

module.exports = {
  init: (_sequelize) => {
    sequelize = _sequelize
    sequelize.define(
      'Energy',
      {
        t: DataTypes.DATE,
        value: DataTypes.FLOAT,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    Energy = sequelize.models.Energy
    return Energy
  },
  associate: (models) => {
    Energy.belongsTo(models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data, userId) =>
    Promise.all(
      data.map((d) =>
        Energy.create({
          t: d.t,
          value: d.v,
          UserId: userId,
        })
      )
    ),
  find: ({ userId, from, to }) =>
    Energy.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
  group: ({ userId, from, to, unit = 'minute' }) =>
    Energy.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      attributes: [
        [sequelize.fn('date_trunc', unit, sequelize.col('t')), 'agg_t'],
        [sequelize.fn('sum', sequelize.col('value')), 'value'],
      ],
      group: 'agg_t',
      order: [[sequelize.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map((d) => ({
        t: d.get({ plain: true }).agg_t,
        value: d.value,
      }))
    ),
}
