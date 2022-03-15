const { DataTypes, Op } = require('sequelize')

let AccelCount
let sequelize

module.exports = {
  init: (_sequelize) => {
    sequelize = _sequelize
    sequelize.define(
      'AccelCount',
      {
        t: DataTypes.DATE,
        hr: DataTypes.FLOAT,
        a: DataTypes.FLOAT,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    AccelCount = sequelize.models.AccelCount
    return AccelCount
  },
  associate: (models) => {
    AccelCount.belongsTo(models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data, userId) =>
    Promise.all(
      data.map((d) =>
        AccelCount.create({
          t: d.t,
          a: d.a,
          hr: d.hr,
          UserId: userId,
        })
      )
    ),
  find: ({ userId, from, to }) =>
    AccelCount.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
}
