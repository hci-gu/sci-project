const { DataTypes, Op } = require('sequelize')

let Accel

module.exports = {
  init: (sequelize) => {
    sequelize.define(
      'Accel',
      {
        t: DataTypes.DATE,
        x: DataTypes.FLOAT,
        y: DataTypes.FLOAT,
        z: DataTypes.FLOAT,
      },
      { timestamps: false }
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
          t: d.t,
          x: d.v[0],
          y: d.v[1],
          z: d.v[2],
          userId,
        })
      )
    ),
  find: ({ userId, from, to }) =>
    Accel.findAll({
      where: {
        userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
  group: ({ userId, from, to, unit = 'minute' }) =>
    Accel.findAll({
      where: {
        userId,
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
