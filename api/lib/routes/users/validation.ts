import Joi from 'joi'
import {
  ContainerTypes,
  createValidator,
  ValidatedRequestSchema,
} from 'express-joi-validation'
import { Activity } from '../../adapters/energy'
import { Condition, Gender } from '../../db/models/User'
const validator = createValidator({})

const user = Joi.object({
  weight: Joi.number().integer().min(1).max(1000).optional(),
  gender: Joi.string()
    .valid(...Object.values(Gender))
    .optional(),
  condition: Joi.string()
    .valid(...Object.values(Condition))
    .optional(),
  injuryLevel: Joi.number().integer().min(1).max(10).optional(),
  deviceId: Joi.string().optional(),
})

export interface UserBodySchema extends ValidatedRequestSchema {
  [ContainerTypes.Params]: {
    id: string
  }
  [ContainerTypes.Body]: {
    weight: number
    gender: Gender
    condition: Condition
    injuryLevel: number
    deviceId: string
  }
}
export const userBody = validator.body(user)

export interface GetQuerySchema extends ValidatedRequestSchema {
  [ContainerTypes.Params]: {
    id: string
    type: 'accel' | 'hr'
  }
  [ContainerTypes.Query]: {
    from: Date
    to: Date
    group: string
    activity: Activity
    gender: Gender
    condition: Condition
    watt: number
    injuryLevel: number
    weight: number
  }
}

export const getQuery = validator.query(
  Joi.object({
    from: Joi.date()
      .optional()
      .default(new Date().setDate(new Date().getDate() - 1)),
    to: Joi.date().optional().default(new Date()),
    group: Joi.string()
      .valid('hour', 'day', 'week', 'month', 'year')
      .optional(),
    activity: Joi.string()
      .valid(...Object.values(Activity))
      .optional(),
    gender: Joi.string()
      .valid(...Object.values(Gender))
      .optional(),
    condition: Joi.string()
      .valid(...Object.values(Condition))
      .optional(),
    watt: Joi.number().optional(),
    injuryLevel: Joi.number().optional(),
    weight: Joi.number().optional(),
  })
)
