const { DataTypes, Op } = require('sequelize')

let Accel
let sequelize

module.exports = {
  init: (_sequelize) => {
    sequelize = _sequelize
    sequelize.define(
      'Accel',
      {
        t: DataTypes.DATE,
        x: DataTypes.FLOAT,
        y: DataTypes.FLOAT,
        z: DataTypes.FLOAT,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    Accel = sequelize.models.Accel
    return Accel
  },
  associate: (models) => {
    Accel.belongsTo(models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data, userId) =>
    Promise.all(
      data.map((d) =>
        Accel.create({
          ...d,
          UserId: userId,
        })
      )
    ),
  find: ({ userId, from, to }) =>
    Accel.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
  group: ({ userId, from, to, unit = 'minute' }) =>
    Accel.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      attributes: [
        [sequelize.fn('date_trunc', unit, sequelize.col('t')), 'agg_t'],
        [sequelize.fn('avg', sequelize.col('x')), 'x'],
        [sequelize.fn('avg', sequelize.col('y')), 'y'],
        [sequelize.fn('avg', sequelize.col('z')), 'z'],
      ],
      group: 'agg_t',
      order: [[sequelize.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map((d) => ({
        t: d.get({ plain: true }).agg_t,
        x: d.x,
        y: d.y,
        z: d.z,
      }))
    ),
}
