import { DataTypes, Sequelize, type ModelStatic } from 'sequelize'
import bcrypt from 'bcrypt'
import { Condition, Gender } from '../../constants.ts'
import { User } from '../classes.ts'

export class NotFoundError extends Error {}
export class ForbiddenError extends Error {}

export const hashPassword = async (password: string) => {
  const salt = await bcrypt.genSalt(10)
  return bcrypt.hash(password, salt)
}

let UserModel: ModelStatic<User>
export default {
  init: (sequelize: Sequelize) => {
    UserModel = sequelize.define<User>(
      'User',
      {
        id: {
          type: DataTypes.UUID,
          defaultValue: DataTypes.UUIDV4,
          unique: true,
          primaryKey: true,
        },
        weight: DataTypes.FLOAT,
        gender: DataTypes.ENUM('male', 'female', 'other'),
        condition: DataTypes.ENUM('paraplegic', 'tetraplegic', 'none'),
        injuryLevel: DataTypes.INTEGER,
        deviceId: DataTypes.STRING,
        timezone: DataTypes.STRING,
        notificationSettings: DataTypes.JSONB,
        createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
        email: {
          type: DataTypes.STRING,
          unique: true,
        },
        password: DataTypes.STRING,
      },
      {
        timestamps: false,
        hooks: {
          beforeCreate: async (user: User) => {
            if (user.password) {
              user.password = await hashPassword(user.password)
            }
          },
        },
      }
    )
    return User
  },
  associate: (sequelize: Sequelize) => {},
  save: ({
    email,
    password,
    weight,
    condition,
    gender,
    injuryLevel,
  }: {
    email: string
    password: string
    weight: number
    condition?: Condition
    gender?: Gender
    injuryLevel?: number
  }) => {
    return UserModel.create({
      email: email?.toLowerCase(),
      password,
      weight,
      condition,
      gender,
      injuryLevel,
      notificationSettings: {
        activity: true,
        data: true,
        journal: false,
      },
    }).catch((e) => {
      if (e.name === 'SequelizeUniqueConstraintError') {
        throw new ForbiddenError('Email already exists')
      }
      throw e
    })
  },
  get: (id: string) => UserModel.findOne({ where: { id } }),
  getAll: () => UserModel.findAll(),
  login: async (email: string, password: string) => {
    const user = await UserModel.findOne({
      where: { email: email.toLowerCase() },
    })
    if (!user) {
      throw new NotFoundError('User not found')
    }

    const success = await bcrypt.compare(password, user.password)
    if (!success) {
      throw new ForbiddenError('Invalid password')
    }
    return user
  },
  delete: (id: string) => UserModel.destroy({ where: { id } }),
}
