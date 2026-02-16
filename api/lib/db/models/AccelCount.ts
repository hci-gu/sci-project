import { DataTypes, Op, Sequelize, type ModelStatic } from 'sequelize'
import UserModel from './User.js'
import { saveEnergyFromCount } from './Energy.js'
import { AccelCount } from '../classes.js'
import moment from 'moment'
import {
  createBoutFromCounts,
  createBoutsFromBatch,
  mergeBouts,
} from './Bout.js'
import {
  BOUT_MIN_COUNTS_FOR_PROCESSING,
  BOUT_MERGE_MAX_GAP_MINUTES,
} from '../../constants.js'

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
  if (countsFromLastFiveMinutes.length >= BOUT_MIN_COUNTS_FOR_PROCESSING) {
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

    // Deduplicate within the same batch by exact timestamp.
    const uniqueRowsByTimestamp = new Map<number, (typeof rows)[number]>()
    rows.forEach((row) => {
      uniqueRowsByTimestamp.set(new Date(row.t).getTime(), row)
    })
    const dedupedRows = Array.from(uniqueRowsByTimestamp.values()).sort(
      (x, y) => new Date(x.t).getTime() - new Date(y.t).getTime()
    )

    if (dedupedRows.length === 0) {
      return []
    }

    // Make saves idempotent across repeated uploads by skipping timestamps
    // that are already persisted for this user.
    const firstTs = new Date(dedupedRows[0].t)
    const lastTs = new Date(dedupedRows[dedupedRows.length - 1].t)
    const existingRows = await AccelCountModel.findAll({
      where: {
        UserId: userId,
        t: {
          [Op.between]: [firstTs, lastTs],
        },
      },
      attributes: ['t'],
    })
    const existingTs = new Set<number>(
      existingRows.map((row) => new Date(row.t).getTime())
    )
    const rowsToInsert = dedupedRows.filter(
      (row) => !existingTs.has(new Date(row.t).getTime())
    )

    if (rowsToInsert.length === 0) {
      return []
    }

    await AccelCountModel.bulkCreate(rowsToInsert, {
      validate: true,
      individualHooks: true,
      hooks: false,
      logging: false,
    })

    const user = await UserModel.get(userId)
    if (user) {
      const countsForEnergy = rowsToInsert.filter((row) => row.hr > 0)

      await Promise.all(
        countsForEnergy.map((row) =>
          saveEnergyFromCount(user, row as unknown as AccelCount)
        )
      )

      await createBoutsFromBatch(user, rowsToInsert)

      // Merge within the batch window (plus a small buffer) to heal fragmentation.
      if (rowsToInsert.length > 0) {
        const from = moment(rowsToInsert[0].t)
          .subtract(BOUT_MERGE_MAX_GAP_MINUTES, 'minutes')
          .toDate()
        const to = moment(rowsToInsert[rowsToInsert.length - 1].t)
          .add(BOUT_MERGE_MAX_GAP_MINUTES, 'minutes')
          .toDate()

        await mergeBouts(user.id, { from, to })
      }
    }

    return rowsToInsert
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
