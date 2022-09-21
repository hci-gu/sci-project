import {
  DataTypes,
  Model,
  InferAttributes,
  Sequelize,
  InferCreationAttributes,
  CreationOptional,
  ModelStatic,
} from 'sequelize'

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
      },
      {
        timestamps: false,
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
  save: ({ weight }: { weight: number }) =>
    UserModel.create({
      weight,
    }),
  get: (id: string) => UserModel.findOne({ where: { id } }),
  getAll: () => UserModel.findAll(),
}
