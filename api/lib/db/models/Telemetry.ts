import { DataTypes, Op, Sequelize, type ModelStatic } from 'sequelize'
import { Telemetry } from '../classes.js'

let TelemetryModel: ModelStatic<Telemetry>
export default {
  init: (sequelize: Sequelize) => {
    TelemetryModel = sequelize.define<Telemetry>(
      'Telemetry',
      {
        id: {
          type: DataTypes.INTEGER,
          primaryKey: true,
          autoIncrement: true,
        },
        t: DataTypes.DATE,
        batteryPercent: DataTypes.INTEGER,
        batteryMv: DataTypes.INTEGER,
        charging: DataTypes.BOOLEAN,
        powerPresent: DataTypes.BOOLEAN,
        heapFree: DataTypes.INTEGER,
        fsTotal: DataTypes.INTEGER,
        fsFree: DataTypes.INTEGER,
        accelMinutesCount: DataTypes.INTEGER,
        watchId: DataTypes.STRING,
        firmwareVersion: DataTypes.STRING,
        sentToServer: DataTypes.BOOLEAN,
        backgroundSync: DataTypes.BOOLEAN,
      },
      {
        timestamps: false,
        defaultScope: {
          attributes: { exclude: ['id', 'UserId'] },
        },
      }
    )
    return TelemetryModel
  },
  associate: (sequelize: Sequelize) => {
    TelemetryModel.belongsTo(sequelize.models.User, {
      foreignKey: {
        allowNull: false,
      },
      onDelete: 'CASCADE',
    })
  },
  save: (data: any, userId: string) =>
    TelemetryModel.create({
      t: data.timestamp ? new Date(data.timestamp) : data.t ? new Date(data.t) : new Date(),
      batteryPercent: data.batteryPercent,
      batteryMv: data.batteryMv,
      charging: data.charging,
      powerPresent: data.powerPresent,
      heapFree: data.heapFree,
      fsTotal: data.fsTotal,
      fsFree: data.fsFree,
      accelMinutesCount: data.accelMinutesCount,
      watchId: data.watchId,
      firmwareVersion: data.firmwareVersion,
      sentToServer: data.sentToServer,
      backgroundSync: data.backgroundSync,
      UserId: userId,
    }),
  find: ({
    userId,
    from,
    to,
  }: {
    userId: string
    from: Date
    to: Date
  }): Promise<Telemetry[]> =>
    TelemetryModel.findAll({
      attributes: [
        't',
        'accelMinutesCount',
        'sentToServer',
        'backgroundSync',
        'batteryPercent',
      ],
      where: {
        UserId: userId,
        t: {
          [Op.between]: [from, to],
        },
      },
      order: [['t', 'ASC']],
    }),
}
