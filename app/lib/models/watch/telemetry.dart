import 'dart:typed_data';

class WatchTelemetry {
  final int batteryPercent;
  final int batteryMv;
  final bool charging;
  final bool powerPresent;
  final int heapFree;
  final int fsTotal;
  final int fsFree;
  final int accelMinutesCount;
  final String? watchId;
  final String? firmwareVersion;
  final DateTime? timestamp;
  final bool? sentToServer;
  final bool? backgroundSync;
  final bool? syncAttempted;
  final bool? syncSucceeded;
  final String? syncError;
  final bool? bluetoothFailed;
  final String? bluetoothFailureReason;
  final String? uploadDeferredReason;

  WatchTelemetry({
    required this.batteryPercent,
    required this.batteryMv,
    required this.charging,
    required this.powerPresent,
    required this.heapFree,
    required this.fsTotal,
    required this.fsFree,
    required this.accelMinutesCount,
    this.watchId,
    this.firmwareVersion,
    this.timestamp,
    this.sentToServer,
    this.backgroundSync,
    this.syncAttempted,
    this.syncSucceeded,
    this.syncError,
    this.bluetoothFailed,
    this.bluetoothFailureReason,
    this.uploadDeferredReason,
  });

  static WatchTelemetry fromBytes(List<int> data) {
    if (data.length < 22) {
      throw StateError('telemetry_payload_too_short');
    }

    final b = ByteData.sublistView(Uint8List.fromList(data));
    final command = b.getUint8(0);
    final status = b.getUint8(1);
    if (command != 0x02 || status != 0x01) {
      throw StateError('telemetry_response_error');
    }

    final batteryPercent = b.getUint8(2);
    final batteryMv = b.getUint16(3, Endian.little);
    final powerFlags = b.getUint8(5);
    final heapFree = b.getUint32(6, Endian.little);
    final fsTotal = b.getUint32(10, Endian.little);
    final fsFree = b.getUint32(14, Endian.little);
    final accelMinutesCount = b.getUint32(18, Endian.little);

    return WatchTelemetry(
      batteryPercent: batteryPercent,
      batteryMv: batteryMv,
      charging: (powerFlags & 0x01) != 0,
      powerPresent: (powerFlags & 0x02) != 0,
      heapFree: heapFree,
      fsTotal: fsTotal,
      fsFree: fsFree,
      accelMinutesCount: accelMinutesCount,
    );
  }

  WatchTelemetry withContext({
    String? watchId,
    String? firmwareVersion,
    DateTime? timestamp,
    bool? sentToServer,
    bool? backgroundSync,
    bool? syncAttempted,
    bool? syncSucceeded,
    String? syncError,
    bool? bluetoothFailed,
    String? bluetoothFailureReason,
    String? uploadDeferredReason,
  }) {
    return WatchTelemetry(
      batteryPercent: batteryPercent,
      batteryMv: batteryMv,
      charging: charging,
      powerPresent: powerPresent,
      heapFree: heapFree,
      fsTotal: fsTotal,
      fsFree: fsFree,
      accelMinutesCount: accelMinutesCount,
      watchId: watchId ?? this.watchId,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      timestamp: timestamp ?? this.timestamp,
      sentToServer: sentToServer ?? this.sentToServer,
      backgroundSync: backgroundSync ?? this.backgroundSync,
      syncAttempted: syncAttempted ?? this.syncAttempted,
      syncSucceeded: syncSucceeded ?? this.syncSucceeded,
      syncError: syncError ?? this.syncError,
      bluetoothFailed: bluetoothFailed ?? this.bluetoothFailed,
      bluetoothFailureReason:
          bluetoothFailureReason ?? this.bluetoothFailureReason,
      uploadDeferredReason: uploadDeferredReason ?? this.uploadDeferredReason,
    );
  }

  static WatchTelemetry fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    bool parseBool(dynamic value) => value == true;

    DateTime? parseTimestamp(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value)?.toUtc();
      }
      return null;
    }

    String? parseString(dynamic value) {
      if (value is String && value.isNotEmpty) return value;
      return null;
    }

    return WatchTelemetry(
      batteryPercent: parseInt(json['batteryPercent']),
      batteryMv: parseInt(json['batteryMv']),
      charging: parseBool(json['charging']),
      powerPresent: parseBool(json['powerPresent']),
      heapFree: parseInt(json['heapFree']),
      fsTotal: parseInt(json['fsTotal']),
      fsFree: parseInt(json['fsFree']),
      accelMinutesCount: parseInt(json['accelMinutesCount']),
      watchId: parseString(json['watchId']),
      firmwareVersion: parseString(json['firmwareVersion']),
      timestamp: parseTimestamp(json['t'] ?? json['timestamp']),
      sentToServer:
          json.containsKey('sentToServer')
              ? json['sentToServer'] == true
              : null,
      backgroundSync:
          json.containsKey('backgroundSync')
              ? json['backgroundSync'] == true
              : null,
      syncAttempted:
          json.containsKey('syncAttempted')
              ? json['syncAttempted'] == true
              : null,
      syncSucceeded:
          json.containsKey('syncSucceeded')
              ? json['syncSucceeded'] == true
              : null,
      syncError: parseString(json['syncError']),
      bluetoothFailed:
          json.containsKey('bluetoothFailed')
              ? json['bluetoothFailed'] == true
              : null,
      bluetoothFailureReason: parseString(json['bluetoothFailureReason']),
      uploadDeferredReason: parseString(json['uploadDeferredReason']),
    );
  }

  Map<String, dynamic> toJson() => {
    'batteryPercent': batteryPercent,
    'batteryMv': batteryMv,
    'charging': charging,
    'powerPresent': powerPresent,
    'heapFree': heapFree,
    'fsTotal': fsTotal,
    'fsFree': fsFree,
    'accelMinutesCount': accelMinutesCount,
    if (watchId != null) 'watchId': watchId,
    if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
    if (timestamp != null) 't': timestamp!.toUtc().toIso8601String(),
    if (sentToServer != null) 'sentToServer': sentToServer,
    if (backgroundSync != null) 'backgroundSync': backgroundSync,
    if (syncAttempted != null) 'syncAttempted': syncAttempted,
    if (syncSucceeded != null) 'syncSucceeded': syncSucceeded,
    if (syncError != null) 'syncError': syncError,
    if (bluetoothFailed != null) 'bluetoothFailed': bluetoothFailed,
    if (bluetoothFailureReason != null)
      'bluetoothFailureReason': bluetoothFailureReason,
    if (uploadDeferredReason != null)
      'uploadDeferredReason': uploadDeferredReason,
  };
}
