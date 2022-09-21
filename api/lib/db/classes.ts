import {
  Model,
  InferAttributes,
  InferCreationAttributes,
  CreationOptional,
  ForeignKey,
} from 'sequelize'
import { Activity, Condition, Gender } from '../constants'

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
  declare createdAt: CreationOptional<Date>
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
