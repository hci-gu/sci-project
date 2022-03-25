const Joi = require('joi')
const validator = require('express-joi-validation').createValidator({})

const user = Joi.object({
  weight: Joi.number().integer().min(1).max(1000).optional(),
  gender: Joi.string().valid('female', 'male', 'other').optional(),
  condition: Joi.string().valid('paraplegic', 'tetraplegic', 'none').optional(),
  injuryLevel: Joi.number().integer().min(1).max(10).optional(),
  deviceId: Joi.string().optional(),
})

module.exports = {
  userBody: validator.body(user),
}
