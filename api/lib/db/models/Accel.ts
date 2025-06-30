import { DataTypes, Op, Sequelize, type ModelStatic } from 'sequelize'
import { Accel } from '../classes.ts'

export type AccelData = {
  t: Date
  x: number
  y: number
  z: number
}

let AccelModel: ModelStatic<Accel>
let sequelizeInstance: Sequelize

export default {
  init: (sequelize: Sequelize) => {
    sequelizeInstance = sequelizeInstance
    AccelModel = sequelize.define<Accel>(
      'Accel',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
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
    return Accel
  },
  associate: (sequelize: Sequelize) => {
    AccelModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data: AccelData[], userId: string) =>
    Promise.all(
      data.map((d) =>
        AccelModel.create({
          ...d,
          t: new Date(d.t),
          UserId: userId,
        })
      )
    ),
  find: ({ userId, from, to }: { userId: string; from: Date; to: Date }) =>
    AccelModel.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
  group: ({
    userId,
    from,
    to,
    unit = 'minute',
  }: {
    userId: string
    from: Date
    to: Date
    unit: string
  }): Promise<Accel[]> =>
    AccelModel.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      attributes: [
        [
          sequelizeInstance.fn('date_trunc', unit, sequelizeInstance.col('t')),
          'agg_t',
        ],
        [sequelizeInstance.fn('avg', sequelizeInstance.col('x')), 'x'],
        [sequelizeInstance.fn('avg', sequelizeInstance.col('y')), 'y'],
        [sequelizeInstance.fn('avg', sequelizeInstance.col('z')), 'z'],
      ],
      group: 'agg_t',
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then(
      (docs) =>
        docs.map((d) => ({
          // @ts-ignore
          t: d.get({ plain: true }).agg_t,
          x: d.x,
          y: d.y,
          z: d.z,
        })) as Accel[]
    ),
}
