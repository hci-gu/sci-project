import { DataTypes, Op, Sequelize, type ModelStatic } from 'sequelize'
import UserModel from './User.js'
import { saveEnergyFromCount } from './Energy.js'
import { AccelCount } from '../classes.js'
import moment from 'moment'
import { createBoutFromCounts, createBoutsFromBatch } from './Bout.js'

const afterCreate = async (count: AccelCount, options?: any) => {
  // Allow callers to bypass the hook (for bulk/batch flows)
  if (options?.context?.skipBoutProcessing) return

  if (!count.UserId || !(count.hr > 0)) return
  const user = await UserModel.get(count.UserId)

  if (!user) return

  saveEnergyFromCount(user, count)

  const countsFromLastFiveMinutes = await Model.find({
    userId: user.id,
    from: moment(count.t).subtract(4, 'minutes').toDate(),
    to: count.t,
  })
  if (countsFromLastFiveMinutes.length === 5) {
    createBoutFromCounts(user, countsFromLastFiveMinutes)
  }
}

let sequelizeInstance: Sequelize
let AccelCountModel: ModelStatic<AccelCount>
const Model = {
  init: (sequelize: Sequelize) => {
    sequelizeInstance = sequelize
    AccelCountModel = sequelize.define<AccelCount>(
      'AccelCount',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        t: DataTypes.DATE,
        hr: DataTypes.FLOAT,
        a: DataTypes.FLOAT,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
        hooks: {
          afterCreate,
        },
      }
    )
    return AccelCount
  },
  associate: (sequelize: Sequelize) => {
    AccelCountModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data: any[], userId: string) =>
    Promise.all(
      data.map((d) =>
        AccelCountModel.create({
          t: d.t,
          a: d.a,
          hr: d.hr,
          UserId: userId,
        })
      )
    ),
  bulkSave: async (data: any[], userId: string) => {
    const rows = data
      .map((d) => ({ t: d.t, a: d.a, hr: d.hr, UserId: userId }))
      .sort((x, y) => new Date(x.t).getTime() - new Date(y.t).getTime())

    await AccelCountModel.bulkCreate(rows, {
      validate: true,
      individualHooks: true,
      hooks: false,
      logging: false,
    })

    const user = await UserModel.get(userId)
    if (user) {
      const countsForEnergy = rows.filter((row) => row.hr > 0)

      await Promise.all(
        countsForEnergy.map((row) =>
          saveEnergyFromCount(user, row as unknown as AccelCount)
        )
      )

      await createBoutsFromBatch(user, rows)
    }

    return rows
  },
  find: ({
    userId,
    from,
    to,
  }: {
    userId: string
    from: Date
    to: Date
  }): Promise<AccelCount[]> =>
    AccelCountModel.findAll({
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
  }): Promise<AccelCount[]> =>
    AccelCountModel.findAll({
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
        [sequelizeInstance.fn('avg', sequelizeInstance.col('hr')), 'hr'],
        [sequelizeInstance.fn('avg', sequelizeInstance.col('a')), 'a'],
      ],
      group: 'agg_t',
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map(
        (d) =>
          ({
            // @ts-ignore
            t: d.get({ plain: true }).agg_t,
            hr: d.hr,
            a: d.a,
          } as AccelCount)
      )
    ),
  hasData: (userId: string) =>
    AccelCountModel.findOne({
      where: {
        UserId: userId,
      },
    }).then((doc) => !!doc),
}

export default Model
