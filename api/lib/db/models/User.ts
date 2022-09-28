import { DataTypes, Sequelize, ModelStatic } from 'sequelize'
import bcrypt from 'bcrypt'
import { Condition, Gender } from '../../constants'
import { User } from '../classes'

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
        createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
        email: DataTypes.STRING,
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
  associate: (sequelize: Sequelize) => {
    UserModel.hasMany(sequelize.models.HeartRate, {
      onDelete: 'cascade',
    })
    UserModel.hasMany(sequelize.models.Accel, {
      onDelete: 'cascade',
    })
  },
  save: ({
    weight,
    condition,
    gender,
    injuryLevel,
  }: {
    weight: number
    condition?: Condition
    gender?: Gender
    injuryLevel?: number
  }) =>
    UserModel.create({
      weight,
      condition,
      gender,
      injuryLevel,
    }),
  get: (id: string) => UserModel.findOne({ where: { id } }),
  getAll: () => UserModel.findAll(),
  login: async (email: string, password: string) => {
    const user = await UserModel.findOne({ where: { email } })
    if (!user) {
      throw new NotFoundError('User not found')
    }

    const success = await bcrypt.compare(password, user.password)
    if (!success) {
      throw new ForbiddenError('Invalid password')
    }
    return user
  },
}
