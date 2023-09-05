import Joi from 'joi'
import moment from 'moment'
import {
  ContainerTypes,
  createValidator,
  ValidatedRequestSchema,
} from 'express-joi-validation'
import { Activity, JournalType } from '../constants'

const validator = createValidator({})

export interface GetQuerySchema extends ValidatedRequestSchema {
  [ContainerTypes.Params]: {
    id: string
    type: string
  }
  [ContainerTypes.Query]: {
    from: Date
    to: Date
    date: Date
    group: string
    activity: Activity
    watt: number
    type: string
  }
}

export const getQuery = validator.query(
  Joi.object({
    from: Joi.date().optional().default(moment().startOf('day').toDate()),
    to: Joi.date().optional().default(moment().endOf('day').toDate()),
    date: Joi.date().optional().default(moment().endOf('day').toDate()),
    group: Joi.string()
      .valid('hour', 'day', 'week', 'month', 'year')
      .optional(),
    activity: Joi.string()
      .valid(...Object.values(Activity))
      .optional(),
    watt: Joi.number().optional(),
    type: Joi.string().optional(),
  })
)
