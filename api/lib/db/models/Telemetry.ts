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
        syncAttempted: DataTypes.BOOLEAN,
        syncSucceeded: DataTypes.BOOLEAN,
        syncError: DataTypes.STRING,
        bluetoothFailed: DataTypes.BOOLEAN,
        bluetoothFailureReason: DataTypes.STRING,
        uploadDeferredReason: DataTypes.STRING,
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
  save: async (data: any, userId: string) => {
    const payload = {
      t:
        data.timestamp
          ? new Date(data.timestamp)
          : data.t
            ? new Date(data.t)
            : new Date(),
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
      syncAttempted: data.syncAttempted,
      syncSucceeded: data.syncSucceeded,
      syncError: data.syncError,
      bluetoothFailed: data.bluetoothFailed,
      bluetoothFailureReason: data.bluetoothFailureReason,
      uploadDeferredReason: data.uploadDeferredReason,
      UserId: userId,
    }

    try {
      return await TelemetryModel.create(payload)
    } catch (e) {
      const message = e instanceof Error ? e.message.toLowerCase() : ''
      const columnMissing =
        message.includes('column') && message.includes('does not exist')
      if (!columnMissing) {
        throw e
      }

      // Backward-compatible fallback for environments where schema updates
      // have not yet been applied.
      return TelemetryModel.create({
        t: payload.t,
        batteryPercent: payload.batteryPercent,
        batteryMv: payload.batteryMv,
        charging: payload.charging,
        powerPresent: payload.powerPresent,
        heapFree: payload.heapFree,
        fsTotal: payload.fsTotal,
        fsFree: payload.fsFree,
        accelMinutesCount: payload.accelMinutesCount,
        watchId: payload.watchId,
        firmwareVersion: payload.firmwareVersion,
        sentToServer: payload.sentToServer,
        backgroundSync: payload.backgroundSync,
        UserId: payload.UserId,
      })
    }
  },
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
