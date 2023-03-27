import Joi from 'joi'
import moment from 'moment'
import {
  ContainerTypes,
  createValidator,
  ValidatedRequestSchema,
} from 'express-joi-validation'
import { Activity } from '../../constants'
const validator = createValidator({})

const bout = Joi.object({
  t: Joi.date().required(),
  minutes: Joi.number().integer().min(1).required(),
  activity: Joi.string()
    .valid(...Object.values(Activity))
    .required(),
})

export interface BoutBodySchema extends ValidatedRequestSchema {
  [ContainerTypes.Params]: {
    id: string
  }
  [ContainerTypes.Body]: {
    t: Date
    minutes: number
    activity: Activity
  }
}
export const boutBody = validator.body(bout)
