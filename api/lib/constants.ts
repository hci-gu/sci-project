export enum Activity {
  sedentary = 'sedentary',
  moving = 'moving',
  active = 'active',
  weights = 'weights',
  skiErgo = 'skiErgo',
  armErgo = 'armErgo',
  rollOutside = 'rollOutside',
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

export enum JournalType {
  painLevel = 'painLevel',
  neuropathicPain = 'neuropathicPain',
  spasticity = 'spasticity',
  pressureRelease = 'pressureRelease',
  pressureUlcer = 'pressureUlcer',
  bodyTemperature = 'bodyTemperature',
  urinaryTractInfection = 'urinaryTractInfection',
  bladderEmptying = 'bladderEmptying',
  bowelEmptying = 'bowelEmptying',
  exercise = 'exercise',
  selfAssessedPhysicalActivity = 'selfAssessedPhysicalActivity',
}

export enum GoalType {
  journal = 'journal',
}

export enum TimeFrame {
  day = 'day',
  week = 'week',
  month = 'month',
  year = 'year',
}

export const SEDENTARY_THRESHOLD = 2700
export const MOVING_THRESHOLD_PARA = 9515
export const MOVING_THRESHOLD_TETRA = 4887
export const MINUTES_FOR_SLEEP = 240

// Bout configuration
export const BOUT_GAP_TOLERANCE_MINUTES = 15 // Max gap before creating new bout (same activity)
export const BOUT_MIN_COUNTS_FOR_PROCESSING = 3 // Minimum counts needed to trigger bout processing
export const BOUT_MERGE_MAX_GAP_MINUTES = 10 // Max gap when merging adjacent bouts
