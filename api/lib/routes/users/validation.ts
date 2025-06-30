import Joi from 'joi'
import moment from 'moment'
import {
  createValidator,
  type ValidatedRequestSchema,
} from 'express-joi-validation'
import ejv from 'express-joi-validation'
const { ContainerTypes } = ejv
import { Condition, Gender } from '../../constants.ts'

const validator = createValidator({})

const user = Joi.object({
  weight: Joi.number().integer().min(1).max(1000).optional().allow(null),
  gender: Joi.string()
    .valid(...Object.values(Gender))
    .optional()
    .allow(null),
  condition: Joi.string()
    .valid(...Object.values(Condition))
    .optional()
    .allow(null),
  injuryLevel: Joi.number().integer().optional().allow(null),
  deviceId: Joi.string().allow(null, '').optional().allow(null),
  email: Joi.string().email().optional().allow(null),
  password: Joi.string().optional().allow(null),
  timezone: Joi.string().optional().allow(null),
  notificationSettings: Joi.object({
    activity: Joi.boolean().optional().allow(null),
    data: Joi.boolean().optional().allow(null),
    journal: Joi.boolean().optional().allow(null),
  })
    .optional()
    .allow(null),
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
    email: string
    password: string
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
  }
}

export const getQuery = validator.query(
  Joi.object({
    from: Joi.date()
      .optional()
      .default(moment().subtract(1, 'day').endOf('day').toDate()),
    to: Joi.date().optional().default(new Date()),
    group: Joi.string()
      .valid('hour', 'day', 'week', 'month', 'year')
      .optional(),
  })
)
