import {
  Model,
  InferAttributes,
  InferCreationAttributes,
  CreationOptional,
  ForeignKey,
} from 'sequelize'
import { Activity, Condition, Gender, JournalType } from '../constants'

export type NotificationSettings = {
  activity: boolean
  data: boolean
  journal: boolean
}

export class User extends Model<
  InferAttributes<User>,
  InferCreationAttributes<User>
> {
  declare id: CreationOptional<string>
  declare weight: CreationOptional<number>
  declare gender: CreationOptional<Gender>
  declare condition: CreationOptional<Condition>
  declare injuryLevel: CreationOptional<number>
  declare deviceId: CreationOptional<string>
  declare timezone: CreationOptional<string>
  declare notificationSettings: CreationOptional<NotificationSettings>
  declare createdAt: CreationOptional<Date>
  declare email: CreationOptional<string>
  declare password: CreationOptional<string>
}

export class AccelCount extends Model<
  InferAttributes<AccelCount>,
  InferCreationAttributes<AccelCount>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare hr: number
  declare a: number

  declare UserId?: ForeignKey<User['id']>
}

export class Accel extends Model<
  InferAttributes<Accel>,
  InferCreationAttributes<Accel>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare x: number
  declare y: number
  declare z: number

  declare UserId?: ForeignKey<User['id']>
}

export class Bout extends Model<
  InferAttributes<Bout>,
  InferCreationAttributes<Bout>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare minutes: number
  declare activity: Activity
  declare isSleeping: boolean

  declare UserId?: ForeignKey<User['id']>
}

export class Energy extends Model<
  InferAttributes<Energy>,
  InferCreationAttributes<Energy>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare kcal: number
  declare activity: Activity

  declare UserId?: ForeignKey<User['id']>
}

export class HeartRate extends Model<
  InferAttributes<HeartRate>,
  InferCreationAttributes<HeartRate>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare hr: number

  declare UserId?: ForeignKey<User['id']>
}

export class Journal extends Model<
  InferAttributes<Journal>,
  InferCreationAttributes<Journal>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare type: JournalType
  declare comment: string

  declare UserId?: ForeignKey<User['id']>
  declare painLevel: CreationOptional<number>
  declare bodyPart: CreationOptional<string>
}

export class Position extends Model<
  InferAttributes<Position>,
  InferCreationAttributes<Position>
> {
  declare id: CreationOptional<number>
  declare t: Date
  declare longitude: number
  declare latitude: number
  declare accuracy: number
  declare altitude: number
  declare floor: number
  declare speed: number
  declare heading: number
  declare speed_accuracy: number

  declare UserId?: ForeignKey<User['id']>
}
