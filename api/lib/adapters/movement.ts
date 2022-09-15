import {
  MOVING_THRESHOLD_PARA,
  MOVING_THRESHOLD_TETRA,
  SEDENTARY_THRESHOLD,
} from '../constants'
import AccelCountModel, { AccelCount } from '../db/models/AccelCount'
import { Condition } from '../db/models/User'

export enum MovementLevel {
  sedentary = 'sedentary',
  moving = 'moving',
  active = 'active',
}

export type Movement = {
  t: Date
  a: number
  hr: number
  level: MovementLevel
}

const movementLevelForAccAndCondition = (a: number, condition: Condition) => {
  if (
    (condition === Condition.paraplegic && a > MOVING_THRESHOLD_PARA) ||
    (condition === Condition.tetraplegic && a > MOVING_THRESHOLD_TETRA)
  ) {
    return MovementLevel.active
  } else if (a > SEDENTARY_THRESHOLD) {
    return MovementLevel.moving
  }

  return MovementLevel.sedentary
}

export const countAndConditionToActivity = (
  count: AccelCount,
  condition: Condition
): Movement => {
  return {
    t: count.t,
    a: count.a,
    hr: count.hr,
    level: movementLevelForAccAndCondition(count.a, condition),
  }
}

export const getMovementForPeriod = ({
  id,
  from,
  to,
  condition = Condition.paraplegic,
  group,
}: {
  id: string
  from: Date
  to: Date
  condition: Condition
  group?: string
}) =>
  group
    ? AccelCountModel.group({ userId: id, from, to, unit: group }).then(
        (counts) =>
          counts.map((count) => countAndConditionToActivity(count, condition))
      )
    : AccelCountModel.find({ userId: id, from, to }).then((counts) =>
        counts.map((count) => countAndConditionToActivity(count, condition))
      )
