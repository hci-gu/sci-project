import moment from 'moment'
import { DataTypes, Op, Sequelize, type ModelStatic } from 'sequelize'
import { activityForAccAndCondition } from '../../adapters/energy/index.js'
import {
  Activity,
  MINUTES_FOR_SLEEP,
  BOUT_GAP_TOLERANCE_MINUTES,
  BOUT_MERGE_MAX_GAP_MINUTES,
} from '../../constants.js'
import { AccelCount, Bout, User } from '../classes.js'

let sequelizeInstance: Sequelize
let BoutModel: ModelStatic<Bout>
const Model = {
  init: (sequelize: Sequelize) => {
    sequelizeInstance = sequelize
    BoutModel = sequelize.define<Bout>(
      'Bout',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        t: DataTypes.DATE,
        minutes: DataTypes.INTEGER,
        activity: DataTypes.ENUM(...Object.values(Activity)),
        isSleeping: {
          type: DataTypes.BOOLEAN,
          defaultValue: false,
        },
        data: DataTypes.JSONB,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return BoutModel
  },
  associate: (sequelize: Sequelize) => {
    BoutModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (
    bout: { t: Date; minutes: number; activity: Activity; data: any },
    userId: string
  ) =>
    BoutModel.create({
      t: bout.t,
      minutes: bout.minutes,
      activity: bout.activity,
      UserId: userId,
      isSleeping: false,
      data: bout.data,
    }),
  get: (id: string) => BoutModel.findOne({ where: { id } }),
  remove: (id: string) => BoutModel.destroy({ where: { id } }),
  find: ({
    userId,
    from,
    to,
  }: {
    userId: string
    from: Date
    to: Date
  }): Promise<Bout[]> =>
    BoutModel.findAll({
      attributes: ['id', 't', 'activity', 'minutes'],
      where: {
        UserId: userId,
        isSleeping: false,
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
  }): Promise<Bout[]> =>
    BoutModel.findAll({
      where: {
        UserId: userId,
        isSleeping: false,
        t: {
          [Op.between]: [from, to],
        },
      },
      attributes: [
        [
          sequelizeInstance.fn('date_trunc', unit, sequelizeInstance.col('t')),
          'agg_t',
        ],
        [
          sequelizeInstance.fn('avg', sequelizeInstance.col('minutes')),
          'minutes',
        ],
        'activity',
      ],
      group: ['agg_t', 'activity'],
      order: [[sequelizeInstance.col('agg_t'), 'ASC']],
    }).then((docs) =>
      docs.map(
        (d) =>
          ({
            // @ts-ignore
            t: d.get({ plain: true }).agg_t,
            minutes: d.get({ plain: true }).minutes,
            activity: d.activity,
          } as Bout)
      )
    ),
}

export default Model

export const createBoutFromCounts = async (
  user: User,
  counts: AccelCount[]
) => {
  const activities = counts.map((count) =>
    activityForAccAndCondition(count.a, user.condition)
  )

  // get majority activity from activities
  const activity = activities
    .sort(
      (a, b) =>
        activities.filter((v) => v === a).length -
        activities.filter((v) => v === b).length
    )
    .pop()

  // get average acc for counts
  //const avgAcc = counts.reduce((acc, c) => acc + c.a, 0) / counts.length

  // get the activity level from average acc
  // const activity = activityForAccAndCondition(avgAcc, user.condition)

  // lookup last bout up to the last count time (backfill-safe)
  const lastBout = await BoutModel.findOne({
    attributes: ['id', 't', 'activity', 'minutes'],
    where: {
      UserId: user.id,
      activity: {
        [Op.in]: [Activity.sedentary, Activity.moving, Activity.active],
      },
      t: {
        [Op.lte]: counts[counts.length - 1].t,
      },
    },
    order: [['t', 'DESC']],
  })

  // if it doesn't exist
  if (!lastBout) {
    const bout = await Model.save(
      {
        t: counts[counts.length - 1].t,
        minutes: 1,
        activity: activity ?? Activity.sedentary,
        data: {},
      },
      user.id
    )
    return bout
  }

  const lastCountTime = counts[counts.length - 1].t
  const gapToleranceAgo = moment(lastCountTime).subtract(
    BOUT_GAP_TOLERANCE_MINUTES,
    'minutes'
  )
  const boutEnd = moment(lastBout.t).add(lastBout.minutes, 'minutes')

  // if activity is different from current bout, or gap exceeds tolerance, create a new bout
  if (boutEnd.isBefore(gapToleranceAgo) || lastBout.activity !== activity) {
    const bout = await Model.save(
      {
        t: counts[counts.length - 1].t,
        minutes: 1,
        activity: activity ?? Activity.sedentary,
        data: {},
      },
      user.id
    )
    return bout
  }

  // if activity is same as current bout, extend by the gap duration (fill the gap)
  // If the current minute is already within the existing bout, no change is needed.
  if (moment(lastCountTime).isBefore(boutEnd)) {
    return lastBout
  }

  const gapMinutes = moment(lastCountTime).diff(boutEnd, 'minutes')
  lastBout.minutes += Math.max(1, gapMinutes + 1)

  const middleOfTheNight = moment().set('hour', 4)
  if (
    lastBout.minutes > MINUTES_FOR_SLEEP &&
    middleOfTheNight.isBetween(lastBout.t, boutEnd)
  ) {
    lastBout.isSleeping = true
  }

  await lastBout.save()
  return lastBout
}

export const createBoutsFromBatch = async (
  user: User,
  rows: { t: Date; a: number; hr: number }[]
) => {
  if (!rows?.length) return

  // sort, in case caller forgot
  rows.sort((x, y) => new Date(x.t).getTime() - new Date(y.t).getTime())

  // use a single transaction to avoid races
  await sequelizeInstance.transaction(async (t) => {
    // walk a 5-minute sliding window over the rows
    for (let i = 4; i < rows.length; i++) {
      const window = rows.slice(i - 4, i + 1) // 5 items
      // guard: ensure they are consecutive minutes — optional depending on your data
      // if (!areConsecutiveMinutes(window)) continue;

      const activities = window.map((c) =>
        activityForAccAndCondition(c.a, user.condition)
      )

      // majority vote
      const activity = activities
        .sort(
          (a, b) =>
            activities.filter((v) => v === a).length -
            activities.filter((v) => v === b).length
        )
        .pop()

      // the "current minute" time is the last element in the window
      const currentT = window[window.length - 1].t

      // Extend or create bout based on *currentT*
      await upsertBoutAtMinute(user, activity ?? Activity.sedentary, currentT, {
        transaction: t,
      })
    }
  })
}

// Helper: extend or create a bout at the given minute
const upsertBoutAtMinute = async (
  user: User,
  activity: Activity,
  minuteT: Date,
  options?: { transaction?: any }
) => {
  // fetch latest bout at or before the minute (backfill-safe)
  const lastBout = await BoutModel.findOne({
    attributes: ['id', 't', 'activity', 'minutes', 'isSleeping'],
    where: {
      UserId: user.id,
      isSleeping: false,
      activity: {
        [Op.in]: [Activity.sedentary, Activity.moving, Activity.active],
      },
      t: {
        [Op.lte]: minuteT,
      },
    },
    order: [['t', 'DESC']],
    transaction: options?.transaction,
    lock: options?.transaction ? options.transaction.LOCK.UPDATE : undefined, // pessimistic if supported
  })

  const gapToleranceAgo = moment(minuteT).subtract(
    BOUT_GAP_TOLERANCE_MINUTES,
    'minutes'
  )
  const boutEnd = moment(lastBout?.t).add(lastBout?.minutes ?? 0, 'minutes')

  if (
    !lastBout ||
    boutEnd.isBefore(gapToleranceAgo) ||
    lastBout.activity !== activity
  ) {
    // start a new 1-minute bout at minuteT
    await BoutModel.create(
      {
        t: minuteT,
        minutes: 1,
        activity,
        UserId: user.id,
        isSleeping: false,
        data: {},
      },
      { transaction: options?.transaction }
    )
    return
  }

  // Same activity & within gap tolerance → extend by filling the gap
  // If minuteT already sits inside the existing bout, do nothing.
  if (moment(minuteT).isBefore(boutEnd)) {
    return
  }

  const gapMinutes = moment(minuteT).diff(boutEnd, 'minutes')
  const newMinutes = lastBout.minutes + Math.max(1, gapMinutes + 1)

  await BoutModel.update(
    { minutes: newMinutes },
    { where: { id: lastBout.id }, transaction: options?.transaction }
  )

  // Sleep flip (optional – same logic but relative to minuteT)
  const updatedBoutEnd = moment(lastBout.t).add(newMinutes, 'minutes')
  const middleOfTheNight = moment(minuteT)
    .set('hour', 4)
    .set('minute', 0)
    .set('second', 0)
  if (
    newMinutes > MINUTES_FOR_SLEEP &&
    middleOfTheNight.isBetween(lastBout.t, updatedBoutEnd)
  ) {
    await BoutModel.update(
      { isSleeping: true },
      { where: { id: lastBout.id }, transaction: options?.transaction }
    )
  }
}

type NormalizedBout = {
  id: number
  t: Date
  minutes: number
  activity: Activity
  data: any
  isManual: boolean
  startMs: number
  endMs: number
  dataSignature: string
}

type TimelineSegment = {
  startMs: number
  endMs: number
  activity: Activity
  isManual: boolean
  data: any
  dataSignature: string
}

const ACTIVITY_PRIORITY: Record<Activity, number> = {
  [Activity.sedentary]: 1,
  [Activity.moving]: 2,
  [Activity.active]: 3,
  [Activity.weights]: 0,
  [Activity.skiErgo]: 0,
  [Activity.armErgo]: 0,
  [Activity.rollOutside]: 0,
}

const dataSignature = (data: any) => {
  try {
    return JSON.stringify(data ?? {})
  } catch {
    return '{}'
  }
}

const toNormalizedBout = (bout: Bout): NormalizedBout | null => {
  const startMs = new Date(bout.t).getTime()
  const minutes = Number(bout.minutes)
  if (!Number.isFinite(startMs) || !Number.isFinite(minutes) || minutes <= 0) {
    return null
  }

  const endMs = startMs + minutes * 60 * 1000
  if (endMs <= startMs) {
    return null
  }

  const data = bout.data ?? {}
  const manual = !!(data && typeof data === 'object' && (data as any).manual)

  return {
    id: Number(bout.id),
    t: new Date(bout.t),
    minutes,
    activity: bout.activity,
    data,
    isManual: manual,
    startMs,
    endMs,
    dataSignature: dataSignature(data),
  }
}

const chooseWinningBout = (activeBouts: NormalizedBout[]) => {
  if (!activeBouts.length) return null

  let winner = activeBouts[0]
  for (let i = 1; i < activeBouts.length; i++) {
    const candidate = activeBouts[i]

    if (candidate.isManual !== winner.isManual) {
      if (candidate.isManual) winner = candidate
      continue
    }

    if (candidate.startMs !== winner.startMs) {
      if (candidate.startMs > winner.startMs) winner = candidate
      continue
    }

    const candidatePriority = ACTIVITY_PRIORITY[candidate.activity] ?? 0
    const winnerPriority = ACTIVITY_PRIORITY[winner.activity] ?? 0
    if (candidatePriority !== winnerPriority) {
      if (candidatePriority > winnerPriority) winner = candidate
      continue
    }

    if (candidate.id > winner.id) winner = candidate
  }

  return winner
}

const normalizeTimeline = (bouts: NormalizedBout[]): TimelineSegment[] => {
  if (!bouts.length) return []

  const starts = new Map<number, NormalizedBout[]>()
  const ends = new Map<number, number[]>()
  const boundaries = new Set<number>()

  for (const bout of bouts) {
    if (!starts.has(bout.startMs)) starts.set(bout.startMs, [])
    starts.get(bout.startMs)!.push(bout)

    if (!ends.has(bout.endMs)) ends.set(bout.endMs, [])
    ends.get(bout.endMs)!.push(bout.id)

    boundaries.add(bout.startMs)
    boundaries.add(bout.endMs)
  }

  const points = Array.from(boundaries.values()).sort((a, b) => a - b)
  if (points.length < 2) return []

  const active = new Map<number, NormalizedBout>()
  const timeline: TimelineSegment[] = []

  for (let i = 0; i < points.length - 1; i++) {
    const point = points[i]
    const nextPoint = points[i + 1]
    if (nextPoint <= point) continue

    const ending = ends.get(point) ?? []
    for (const id of ending) active.delete(id)

    const starting = starts.get(point) ?? []
    for (const bout of starting) active.set(bout.id, bout)

    if (active.size === 0) continue

    const winner = chooseWinningBout(Array.from(active.values()))
    if (!winner) continue

    const previous = timeline[timeline.length - 1]
    if (
      previous &&
      previous.endMs === point &&
      previous.activity === winner.activity &&
      previous.isManual === winner.isManual &&
      previous.dataSignature === winner.dataSignature
    ) {
      previous.endMs = nextPoint
      continue
    }

    timeline.push({
      startMs: point,
      endMs: nextPoint,
      activity: winner.activity,
      isManual: winner.isManual,
      data: winner.data,
      dataSignature: winner.dataSignature,
    })
  }

  return timeline
}

const mergeCompatibleSegments = (
  segments: TimelineSegment[],
  maxGapMinutes: number
) => {
  if (segments.length < 2) return segments

  const merged: TimelineSegment[] = [
    {
      ...segments[0],
    },
  ]

  for (let i = 1; i < segments.length; i++) {
    const segment = segments[i]
    const current = merged[merged.length - 1]
    const gapMinutes = (segment.startMs - current.endMs) / (60 * 1000)

    if (
      current.activity === segment.activity &&
      current.isManual === segment.isManual &&
      current.dataSignature === segment.dataSignature &&
      gapMinutes >= 0 &&
      gapMinutes <= maxGapMinutes
    ) {
      current.endMs = segment.endMs
      continue
    }

    merged.push({ ...segment })
  }

  return merged
}

const intervalSignature = (segments: TimelineSegment[]) =>
  segments
    .map((segment) => ({
      startMs: segment.startMs,
      endMs: segment.endMs,
      activity: segment.activity,
      dataSignature: segment.dataSignature,
    }))
    .sort((a, b) => {
      if (a.startMs !== b.startMs) return a.startMs - b.startMs
      if (a.endMs !== b.endMs) return a.endMs - b.endMs
      if (a.activity !== b.activity) return a.activity.localeCompare(b.activity)
      return a.dataSignature.localeCompare(b.dataSignature)
    })

/**
 * Normalize bouts into a non-overlapping timeline and merge adjacent compatible
 * segments. Manual bouts are preserved and take precedence when overlap exists.
 */
export const mergeBouts = async (
  userId: string,
  options?: { maxGapMinutes?: number; from?: Date; to?: Date }
) => {
  const maxGap = options?.maxGapMinutes ?? BOUT_MERGE_MAX_GAP_MINUTES

  const whereClause: any = {
    UserId: userId,
    isSleeping: false,
    activity: {
      [Op.in]: [Activity.sedentary, Activity.moving, Activity.active],
    },
  }

  if (options?.from && options?.to) {
    // Include earlier starts that can still overlap the target window.
    whereClause.t = { [Op.lte]: options.to }
  } else if (options?.to) {
    whereClause.t = { [Op.lte]: options.to }
  } else if (options?.from) {
    whereClause.t = { [Op.gte]: options.from }
  }

  const rawBouts = await BoutModel.findAll({
    attributes: ['id', 't', 'activity', 'minutes', 'data'],
    where: whereClause,
    order: [['t', 'ASC']],
  })

  const normalizedBouts = rawBouts
    .map((bout) => toNormalizedBout(bout as Bout))
    .filter((bout): bout is NormalizedBout => !!bout)

  if (normalizedBouts.length < 2) return { merged: 0, deleted: 0 }

  const fromMs = options?.from ? options.from.getTime() : null
  const toMs = options?.to ? options.to.getTime() : null

  const scopedBouts = normalizedBouts.filter((bout) => {
    if (fromMs != null && bout.endMs <= fromMs) return false
    if (toMs != null && bout.startMs >= toMs) return false
    return true
  })

  if (scopedBouts.length < 2) return { merged: 0, deleted: 0 }

  const mutableBouts = scopedBouts.filter((bout) => !bout.isManual)
  if (mutableBouts.length === 0) return { merged: 0, deleted: 0 }

  const timeline = mergeCompatibleSegments(normalizeTimeline(scopedBouts), maxGap)
  const nextMutableTimeline = timeline.filter((segment) => !segment.isManual)

  const currentMutableTimeline: TimelineSegment[] = mutableBouts.map((bout) => ({
    startMs: bout.startMs,
    endMs: bout.endMs,
    activity: bout.activity,
    isManual: false,
    data: bout.data,
    dataSignature: bout.dataSignature,
  }))

  const currentSignature = intervalSignature(currentMutableTimeline)
  const nextSignature = intervalSignature(nextMutableTimeline)

  const changed =
    currentSignature.length !== nextSignature.length ||
    currentSignature.some((segment, index) => {
      const next = nextSignature[index]
      return (
        segment.startMs !== next.startMs ||
        segment.endMs !== next.endMs ||
        segment.activity !== next.activity ||
        segment.dataSignature !== next.dataSignature
      )
    })

  if (!changed) {
    return { merged: 0, deleted: 0 }
  }

  const replaceableIds = mutableBouts.map((bout) => bout.id)
  await sequelizeInstance.transaction(async (transaction) => {
    await BoutModel.destroy({
      where: { id: { [Op.in]: replaceableIds } },
      transaction,
    })

    if (nextMutableTimeline.length > 0) {
      await BoutModel.bulkCreate(
        nextMutableTimeline.map((segment) => ({
          t: new Date(segment.startMs),
          minutes: Math.round((segment.endMs - segment.startMs) / (60 * 1000)),
          activity: segment.activity,
          UserId: userId,
          isSleeping: false,
          data: segment.data ?? {},
        })),
        { transaction }
      )
    }
  })

  return {
    merged: Math.max(0, replaceableIds.length - nextMutableTimeline.length),
    deleted: replaceableIds.length,
    inserted: nextMutableTimeline.length,
    maxGapMinutes: maxGap,
  }
}
