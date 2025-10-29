import express from 'express'
import { type ValidatedRequest } from 'express-joi-validation'
import Journal from '../../db/models/Journal.js'
import { getQuery, type GetQuerySchema } from '../validation.js'
import { Activity, JournalType } from '../../constants.js'
import {
  fillMockData,
  getCurrentPain,
  getCurrentPressureUlcers,
  getCurrentSpasticity,
  getCurrentUTI,
} from './utils.js'
import { getEnergyForCountAndActivity } from '../../adapters/energy/index.js'
import { AccelCount, Energy } from '../../db/classes.js'
import { removeBout, saveBout, type EnergyGeneratorArgs } from '../bouts/utils.js'

const PHYSICAL_ACTIVITY_DURATION_TO_MINUTES: Record<string, number> = {
  none: 0,
  minutes1To30: 15,
  minutes30To60: 45,
  hours1To3: 120,
  hours3To5: 240,
  hours5To7: 360,
  hours7To10: 510,
  hours10To15: 750,
  hours15To20: 1050,
  moreThan20: 1260,
}

const SEDENTARY_DURATION_TO_MINUTES: Record<string, number> = {
  lessThanOneHour: 30,
  hours1To3: 120,
  hours3To5: 240,
  hours5To7: 360,
  hours7To9: 480,
  hours9To11: 600,
  hours11To13: 720,
  hours13To15: 840,
  hours15To17: 960,
  moreThan17: 1080,
}

const ESTIMATED_ACTIVITY_LEVELS: Partial<
  Record<Activity, { hr: number; a: number }>
> = {
  [Activity.sedentary]: { hr: 60, a: 1000 },
  [Activity.moving]: { hr: 90, a: 6000 },
  [Activity.active]: { hr: 120, a: 11000 },
}

const minutesFromPhysicalDuration = (value?: string) =>
  PHYSICAL_ACTIVITY_DURATION_TO_MINUTES[value ?? 'none'] ?? 0

const minutesFromSedentaryDuration = (value?: string) =>
  SEDENTARY_DURATION_TO_MINUTES[value ?? 'lessThanOneHour'] ?? 0

const createEnergyGenerator = (
  activity: Activity,
  start: Date,
  minutes: number
) => {
  const estimate = ESTIMATED_ACTIVITY_LEVELS[activity]

  if (!estimate || minutes <= 0) {
    return undefined
  }

  return ({ user }: EnergyGeneratorArgs) => {
    const entries: Energy[] = []

    for (let i = 0; i < minutes; i++) {
      const t = new Date(start.getTime() + i * 60 * 1000)
      const count = {
        t,
        hr: estimate.hr,
        a: estimate.a,
      } as AccelCount
      const kcal = getEnergyForCountAndActivity(user, count, activity)
      entries.push({ t, activity, kcal } as Energy)
    }

    return entries
  }
}

const router = express.Router()

router.post('/:userId', async (req, res: any) => {
  const { userId } = req.params
  try {
    const entryTime = req.body.t ? new Date(req.body.t) : new Date()

    if (req.body.type == JournalType.exercise) {
      const bout = await saveBout(userId, {
        ...req.body.info,
        t: entryTime,
      })
      req.body.info.bout = bout.id
    } else if (req.body.type === JournalType.selfAssessedPhysicalActivity) {
      const info = req.body.info ?? {}
      const sedentaryMinutes = minutesFromSedentaryDuration(
        info.sedentaryDuration
      )
      const everydayMinutes = minutesFromPhysicalDuration(
        info.everydayActivityDuration
      )
      const trainingMinutes = minutesFromPhysicalDuration(info.trainingDuration)

      const savedBouts: number[] = []
      const startOfDay = new Date(entryTime)
      startOfDay.setHours(0, 0, 0, 0)
      let currentStart = startOfDay

      const manualActivities: Array<{
        minutes: number
        activity: Activity
      }> = [
        { minutes: sedentaryMinutes, activity: Activity.sedentary },
        { minutes: everydayMinutes, activity: Activity.moving },
        { minutes: trainingMinutes, activity: Activity.active },
      ]

      for (const { minutes, activity } of manualActivities) {
        if (!minutes) {
          continue
        }

        const boutStart = new Date(currentStart)
        const bout = await saveBout(userId, {
          t: boutStart,
          minutes,
          activity,
          data: { manual: true, source: 'selfAssessedPhysicalActivity' },
          energyGenerator: createEnergyGenerator(activity, boutStart, minutes),
        })

        savedBouts.push(bout.id)
        currentStart = new Date(currentStart.getTime() + minutes * 60 * 1000)
      }

      req.body.info = {
        ...info,
        bouts: savedBouts.map((id) => id.toString()),
      }
    }

    const response = await Journal.save(
      {
        ...req.body,
        t: entryTime,
      },
      userId
    )
    res.send(response)
  } catch (e) {
    console.log(e)
    return res.sendStatus(500)
  }
})

router.delete('/:userId/:id', async (req, res) => {
  const { id, userId } = req.params

  try {
    const journalEntry = await Journal.delete(id)
    console.log('deleted.journalEntry', journalEntry)
    if (journalEntry?.type == JournalType.exercise) {
      await removeBout(userId, (journalEntry.info as any).bout.toString())
    } else if (journalEntry?.type === JournalType.selfAssessedPhysicalActivity) {
      const bouts = (journalEntry.info as any)?.bouts as
        | Array<string | number>
        | undefined
      if (Array.isArray(bouts)) {
        for (const boutId of bouts) {
          await removeBout(userId, boutId.toString())
        }
      }
    }
    res.sendStatus(200)
  } catch (e) {
    console.log(e)
    res.sendStatus(500)
  }
})

router.patch('/:userId/:id', async (req, res) => {
  const { id } = req.params

  try {
    const update = req.body
    if (update.t) {
      update.t = new Date(update.t)
    }
    const updated = await Journal.update(id, update)
    res.json(updated)
  } catch (e) {
    res.sendStatus(500)
  }
})

router.get(
  '/:id',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res: any) => {
    const { id } = req.params
    const { from, to, type } = req.query

    try {
      const response = await Journal.find(
        {
          userId: id,
          from,
          to,
        },
        type ? { type } : {}
      )
      res.json(response)
    } catch (e) {
      console.log('GET /journal/:id', e)
      return res.sendStatus(500)
    }
  }
)

router.get('/:id/mock', async (req, res) => {
  await fillMockData(req.params.id)

  res.json({
    message: 'ok',
  })
})

router.get(
  '/:id/:type',
  getQuery,
  async (req: ValidatedRequest<GetQuerySchema>, res: any) => {
    const { id, type } = req.params
    const { to } = req.query

    try {
      switch (type) {
        case JournalType.pressureUlcer:
          res.json(await getCurrentPressureUlcers(id, to))
          break
        case JournalType.urinaryTractInfection:
          res.json(await getCurrentUTI(id, to))
          break
        case JournalType.painLevel:
        case JournalType.neuropathicPain:
          res.json(await getCurrentPain(id, type, to))
          break
        case JournalType.spasticity:
          res.json(await getCurrentSpasticity(id, to))
          break
        default:
          res.sendStatus(404)
          break
      }
    } catch (e) {
      console.log('GET /journal/:id/:type', e)
      return res.sendStatus(500)
    }
  }
)

export default router
