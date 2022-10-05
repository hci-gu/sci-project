export enum Activity {
  sedentary = 'sedentary',
  moving = 'moving',
  active = 'active',
  weights = 'weights',
  skiErgo = 'skiErgo',
  armErgo = 'armErgo',
}

export enum Gender {
  male = 'male',
  female = 'female',
  other = 'other',
}

export enum Condition {
  paraplegic = 'paraplegic',
  tetraplegic = 'tetraplegic',
  none = 'none',
}

export const SEDENTARY_THRESHOLD = 2700
export const MOVING_THRESHOLD_PARA = 9515
export const MOVING_THRESHOLD_TETRA = 4887
export const MINUTES_FOR_SLEEP = 240
