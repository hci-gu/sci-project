import Joi from 'joi'
import {
  createValidator,
  type ValidatedRequestSchema,
} from 'express-joi-validation'
import ejv from 'express-joi-validation'
const { ContainerTypes } = ejv
import { Activity } from '../../constants.ts'
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
