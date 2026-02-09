import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/models/watch/telemetry.dart';

/// UUIDs for InfiniTime Accelerometer Data Service
final _accelDataServiceUuid = Guid("adafac00-4669-6c65-5472-616e73666572");
final _transferCharUuid = Guid("adafac01-4669-6c65-5472-616e73666572");

/// UUIDs for Current Time Service (CTS)
final _ctsServiceUuid = Guid("00001805-0000-1000-8000-00805f9b34fb");
final _currentTimeCharUuid = Guid("00002a2b-0000-1000-8000-00805f9b34fb");
final _localTimeInfoCharUuid = Guid("00002a0f-0000-1000-8000-00805f9b34fb");

/// UUIDs for Device Information Service (DIS)
final _deviceInfoServiceUuid = Guid("0000180a-0000-1000-8000-00805f9b34fb");
final _firmwareRevisionCharUuid = Guid("00002a26-0000-1000-8000-00805f9b34fb");

/// UUIDs for telemetry service/characteristic
final _telemetryServiceUuid = Guid("adafac02-4669-6c65-5472-616e73666572");
final _telemetryCharUuid = Guid("adafac03-4669-6c65-5472-616e73666572");

/// Device name to scan for
const String kInfiniTimeDeviceName = 'InfiniTime';

class _AccelCommands {
  static const int getCount = 0x01;
  static const int getCountResponse = 0x02;
  static const int readEntries = 0x10;
  static const int readEntriesResponse = 0x11;
  static const int clearData = 0x20;
  static const int clearDataResponse = 0x21;
}

class _TelemetryCommands {
  static const int getTelemetry = 0x01;
}

/// State of the PineTime connection
class PineTimeState {
  final bool connected;
  final int storedEntries;
  final String? firmwareRevision;

  PineTimeState({
    required this.connected,
    this.storedEntries = 0,
    this.firmwareRevision,
  });
}

/// Service to handle communication with InfiniTime/PineTime watches
class PineTimeService {
  static PineTimeService? _instance;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  BluetoothCharacteristic? _ctsCurrentTimeChar;
  BluetoothCharacteristic? _ctsLocalTimeChar;
  BluetoothCharacteristic? _firmwareRevisionChar;
  BluetoothCharacteristic? _telemetryChar;
  String? _firmwareRevision;
  List<BluetoothService>? _servicesCache;
  bool _accelNotifyEnabled = false;
  bool _telemetryNotifyEnabled = false;
  Future<void> _gattQueue = Future.value();
  bool connected = false;
  bool initialized = false;
  StreamSubscription? _connectionSub;
  Completer<void>? _startInflight;

  final String identifier;

  PineTimeService._(this.identifier);

  static PineTimeService get instance {
    if (_instance == null) {
      throw StateError(
        'PineTimeService not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Returns the instance if initialized, or null otherwise.
  /// Use this when you need to safely check if the service exists.
  static PineTimeService? get instanceOrNull => _instance;

  BluetoothDevice get device {
    final d = _device;
    if (d == null) {
      throw StateError('pinetime_device_not_connected');
    }
    return d;
  }

  static void initialize(String identifier) {
    if (_instance != null &&
        _instance!.initialized &&
        _instance!.identifier == identifier &&
        _instance!.connected) {
      debugPrint('PineTimeService already initialized');
      return;
    }
    // Dispose any existing instance to avoid leaking subscriptions/resources.
    _instance?.disposeSubs();
    _instance = PineTimeService._(identifier);
    _instance!.initialized = true;
  }

  static void dispose() {
    if (_instance != null) {
      try {
        _instance?.disposeSubs();
      } catch (_) {}
      _instance = null;
    }
  }

  void disposeSubs() {
    _connectionSub?.cancel();
    _connectionSub = null;
    connected = false;
    initialized = false;
    _device = null;
    _characteristic = null;
    _ctsCurrentTimeChar = null;
    _ctsLocalTimeChar = null;
    _firmwareRevisionChar = null;
    _telemetryChar = null;
    _firmwareRevision = null;
    _servicesCache = null;
    _accelNotifyEnabled = false;
    _telemetryNotifyEnabled = false;
    _gattQueue = Future.value();
    _instance = null;
  }

  /// Scan for InfiniTime devices
  static Stream<Map<String, String>> searchForDevice() async* {
    final seen = <String>{};

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        final name =
            r.device.platformName.isNotEmpty
                ? r.device.platformName
                : r.advertisementData.localName;

        if (name.contains(kInfiniTimeDeviceName) &&
            seen.add(r.device.remoteId.str)) {
          yield {'id': r.device.remoteId.str, 'name': name};
        }
      }
    }
  }

  static Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connect to the PineTime device
  Future<void> start() async {
    if (connected) {
      return;
    }
    if (_startInflight != null) {
      await _startInflight!.future;
      return;
    }
    debugPrint("Starting PineTimeService for $identifier");
    _startInflight = Completer<void>();
    // Prevent unhandled errors if nobody awaits this completer.
    _startInflight!.future.catchError((_) {});

    try {
      _resetGattStateForReconnect();
      // Wait for Bluetooth to be ready
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        // Wait up to 5 seconds for Bluetooth to turn on
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw StateError(kBluetoothOffError),
            );
      }

      // Try reusing the known device before scanning again.
      if (_device != null) {
        try {
          await _device!
              .connect(autoConnect: false)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          _device = null;
        }
      }

      if (_device == null) {
        // Find and connect to the device
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

        late final List<ScanResult> scanResult;
        try {
          scanResult = await FlutterBluePlus.scanResults
              .firstWhere((results) {
                return results.any((r) => r.device.remoteId.str == identifier);
              })
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw StateError(kWatchNotFoundError),
              );
        } finally {
          await FlutterBluePlus.stopScan();
        }

        final infiniTimeResult = scanResult.firstWhere(
          (r) => r.device.remoteId.str == identifier,
        );

        _device = infiniTimeResult.device;
        await _device!.connect(autoConnect: false);
      }

      // Wait for an actual connected state before service discovery
      await _device!.connectionState
          .where((state) => state == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 5));

      // Listen for disconnection
      await _connectionSub?.cancel();
      _connectionSub = _device!.connectionState.listen((state) {
        connected = state == BluetoothConnectionState.connected;
        debugPrint('PineTime connection state: $state');
      });

      connected = true;

      // Discover services and find the accelerometer characteristic
      bool discovered = await _discoverCharacteristic();
      if (!discovered) {
        await Future.delayed(const Duration(milliseconds: 500));
        discovered = await _discoverCharacteristic();
      }
      if (!discovered || _characteristic == null) {
        await _device?.disconnect();
        connected = false;
        throw StateError(kPinetimeCharacteristicMissing);
      }
      await _syncCurrentTime();
      _startInflight?.complete();
      _startInflight = null;
      return;
    } catch (e) {
      if (e is StateError) {
        _startInflight?.completeError(e);
        _startInflight = null;
        rethrow;
      }
      final code = _mapBleErrorCode(e, op: 'connect');
      _startInflight?.completeError(StateError(code));
      _startInflight = null;
      throw StateError(code);
    }
  }

  Future<bool> _discoverCharacteristic() async {
    if (_device == null) return false;

    return await _queueGatt(() async {
      final services = await _ensureServicesDiscovered();

      for (final service in services) {
        if (service.uuid == _accelDataServiceUuid) {
          for (final c in service.characteristics) {
            if (c.uuid == _transferCharUuid) {
              _characteristic = c;
              await _ensureAccelNotifyEnabled();
              debugPrint('Found and enabled accelerometer data characteristic');
              return true;
            }
          }
        }
      }

      debugPrint('Accelerometer data service not found!');
      return false;
    });
  }

  Future<void> _discoverCtsCharacteristics() async {
    if (_device == null) return;

    final services = await _ensureServicesDiscovered();
    for (final service in services) {
      if (service.uuid == _ctsServiceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid == _currentTimeCharUuid) {
            _ctsCurrentTimeChar = c;
          } else if (c.uuid == _localTimeInfoCharUuid) {
            _ctsLocalTimeChar = c;
          }
        }
      }
    }
  }

  Future<void> _discoverDeviceInfoCharacteristics() async {
    if (_device == null) return;

    final services = await _ensureServicesDiscovered();
    for (final service in services) {
      if (service.uuid == _deviceInfoServiceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid == _firmwareRevisionCharUuid) {
            _firmwareRevisionChar = c;
          }
        }
      }
    }
  }

  Future<void> _discoverTelemetryCharacteristic() async {
    if (_device == null) return;

    final services = await _ensureServicesDiscovered();
    debugPrint('PineTime telemetry: discovered ${services.length} services');
    for (final service in services) {
      if (service.uuid != _telemetryServiceUuid) continue;
      debugPrint('PineTime telemetry: service found');
      for (final c in service.characteristics) {
        if (c.uuid == _telemetryCharUuid) {
          _telemetryChar = c;
          debugPrint('PineTime telemetry: characteristic found ${c.uuid.str}');
          return;
        }
      }
    }

    if (_telemetryChar == null) {
      debugPrint(
        'PineTime telemetry: service/characteristic not found '
        '(likely older firmware without telemetry)',
      );
    }
  }

  int _toUint8(int value) => value & 0xFF;

  Future<void> _syncCurrentTime() async {
    if (_device == null) return;
    try {
      await _queueGatt(() async {
        if (_ctsCurrentTimeChar == null || _ctsLocalTimeChar == null) {
          await _discoverCtsCharacteristics();
        }
        if (_ctsCurrentTimeChar == null || _ctsLocalTimeChar == null) {
          debugPrint('CTS characteristics not found; skipping time sync');
          return;
        }

        final now = DateTime.now();
        final tzQuarters = (now.timeZoneOffset.inMinutes / 15).round();
        // Dart DateTime has no DST flag; use 255 (unknown) per CTS spec.
        const int dst = 255;

        await _ctsLocalTimeChar!.write([
          _toUint8(tzQuarters),
          _toUint8(dst),
        ], withoutResponse: false);

        final year = now.year;
        await _ctsCurrentTimeChar!.write([
          _toUint8(year),
          _toUint8(year >> 8),
          _toUint8(now.month),
          _toUint8(now.day),
          _toUint8(now.hour),
          _toUint8(now.minute),
          _toUint8(now.second),
          _toUint8(now.weekday),
          0, // fractions256
          0, // adjustReason
        ], withoutResponse: false);
      });
    } catch (e) {
      debugPrint('Failed to sync watch time: $e');
    }
  }

  /// Get current state of the PineTime
  Future<PineTimeState> getState({bool refreshFirmware = false}) async {
    if (!connected || _characteristic == null) {
      return PineTimeState(connected: connected);
    }

    // Entry count must be reliable for sync cursor decisions.
    // If this read fails, propagate the error instead of pretending 0 entries.
    final count = await _getEntryCount();
    String? firmwareRevision;
    try {
      firmwareRevision = await getFirmwareRevision(refresh: refreshFirmware);
    } catch (e) {
      debugPrint('Failed to refresh firmware revision: $e');
    }

    return PineTimeState(
      connected: connected,
      storedEntries: count,
      firmwareRevision: firmwareRevision,
    );
  }

  Future<String?> getFirmwareRevision({bool refresh = false}) async {
    if (!connected || _device == null) return null;
    if (!refresh && _firmwareRevision != null) {
      return _firmwareRevision;
    }

    try {
      return await _queueGatt(() async {
        if (_firmwareRevisionChar == null) {
          await _discoverDeviceInfoCharacteristics();
        }
        if (_firmwareRevisionChar == null) {
          return _firmwareRevision;
        }
        final value = await _firmwareRevisionChar!.read();
        if (value.isEmpty) return _firmwareRevision;
        final revision = utf8.decode(value, allowMalformed: true).trim();
        if (revision.isEmpty) return _firmwareRevision;
        _firmwareRevision = revision;
        return revision;
      });
    } catch (e) {
      debugPrint('Failed to read firmware revision: $e');
      return _firmwareRevision;
    }
  }

  Future<WatchTelemetry?> getTelemetry() async {
    if (!connected || _device == null) return null;

    try {
      return await _retry<WatchTelemetry?>(() async {
        return await _queueGatt(() async {
          if (_telemetryChar == null) {
            await _discoverTelemetryCharacteristic();
          }
          if (_telemetryChar == null) {
            debugPrint('PineTime telemetry: characteristic not found');
            return null;
          }

          final char = _telemetryChar!;
          final supportsNotify = char.properties.notify;
          final supportsRead = char.properties.read;
          final supportsWrite = char.properties.write;
          final supportsWriteNoResp = char.properties.writeWithoutResponse;

          if (supportsNotify) {
            try {
              await _ensureTelemetryNotifyEnabled();
            } catch (e) {
              debugPrint('PineTime telemetry: notify not permitted: $e');
            }
          }

          Future<List<int>>? responseFuture;
          if (supportsNotify) {
            responseFuture = char.onValueReceived.first;
          }

          if (supportsWrite || supportsWriteNoResp) {
            await char.write([
              _TelemetryCommands.getTelemetry,
            ], withoutResponse: !supportsWrite && supportsWriteNoResp);
          }

          if (responseFuture != null) {
            final response = await responseFuture.timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw TimeoutException('telemetry timed out'),
            );
            return WatchTelemetry.fromBytes(response);
          }

          if (supportsRead) {
            await Future.delayed(const Duration(milliseconds: 200));
            final response = await char.read();
            if (response.length < 22) {
              debugPrint(
                'PineTime telemetry: read payload too short (${response.length})',
              );
              return null;
            }
            return WatchTelemetry.fromBytes(response);
          }

          debugPrint('PineTime telemetry: no read/notify support');
          return null;
        });
      }, attempts: 2);
    } catch (e) {
      debugPrint('Failed to read telemetry via notify: $e');
      try {
        if (_telemetryChar == null) return null;
        final response = await _queueGatt(() async {
          return _telemetryChar!.read();
        });
        if (response.length < 22) {
          debugPrint(
            'PineTime telemetry: read payload too short (${response.length})',
          );
          return null;
        }
        return WatchTelemetry.fromBytes(response);
      } catch (readError) {
        debugPrint('Failed to read telemetry via read: $readError');
        return null;
      }
    }
  }

  /// Get count of stored entries on the watch
  Future<int> _getEntryCount() async {
    if (_characteristic == null) {
      throw StateError('Characteristic not available');
    }

    try {
      return await _queueGatt(() async {
        final responseFuture = _characteristic!.onValueReceived.first;

        await _characteristic!.write([
          _AccelCommands.getCount,
        ], withoutResponse: false);

        final response = await responseFuture.timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('getCount timed out'),
        );

        if (response.isNotEmpty &&
            response[0] == _AccelCommands.getCountResponse &&
            response.length >= 6 &&
            response[1] == 0x01) {
          final count =
              response[2] |
              (response[3] << 8) |
              (response[4] << 16) |
              (response[5] << 24);
          return count;
        }

        throw Exception('Invalid response for getCount');
      });
    } catch (e) {
      if (e is StateError) rethrow;
      throw StateError(_mapBleErrorCode(e, op: 'read'));
    }
  }

  /// Read entries from the watch
  Future<List<_MinuteEntry>> _readEntries(int startIndex, int count) async {
    if (_characteristic == null) {
      throw StateError('Characteristic not available');
    }

    return await _retry<List<_MinuteEntry>>(
      () async {
        return await _queueGatt(() async {
          final command = [
            _AccelCommands.readEntries,
            0x00, // padding
            startIndex & 0xFF,
            (startIndex >> 8) & 0xFF,
            (startIndex >> 16) & 0xFF,
            (startIndex >> 24) & 0xFF,
            count & 0xFF,
          ];

          final responseFuture = _characteristic!.onValueReceived.first;

          await _characteristic!.write(command, withoutResponse: false);

          final response = await responseFuture.timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('readEntries timed out'),
          );

          if (response.isEmpty ||
              response[0] != _AccelCommands.readEntriesResponse) {
            throw Exception('Invalid response for readEntries');
          }

          if (response.length < 11) {
            throw Exception('Response too short');
          }

          final status = response[1];
          if (status != 0x01) {
            throw Exception('Error status: $status');
          }

          final entriesInPacket = response[10];
          final entries = <_MinuteEntry>[];

          for (int i = 0; i < entriesInPacket; i++) {
            final offset = 11 + (i * 10);
            if (offset + 10 > response.length) break;

            // float count (little-endian, IEEE 754)
            final countBytes = ByteData.sublistView(
              Uint8List.fromList(response.sublist(offset, offset + 4)),
            );
            final count = countBytes.getFloat32(0, Endian.little);

            // int16 heartRate (little-endian, signed)
            int hr = response[offset + 4] | (response[offset + 5] << 8);
            if (hr >= 0x8000) hr -= 0x10000;

            // uint32 timestamp (little-endian)
            final ts =
                response[offset + 6] |
                (response[offset + 7] << 8) |
                (response[offset + 8] << 16) |
                (response[offset + 9] << 24);

            entries.add(
              _MinuteEntry(
                count: count,
                heartRate: hr,
                timestamp: ts,
              ), // renamed from acceleration to counts
            );
          }

          return entries;
        });
      },
      attempts: 3,
      timeoutCode: kPinetimeReadTimeout,
      bleErrorCode: kPinetimeBleError,
    );
  }

  /// Read all stored entries from the watch
  /// [onProgress] is called with (current, total) after each chunk is read
  Future<List<_MinuteEntry>> readAllEntries({
    int startIndex = 0,
    void Function(int current, int total)? onProgress,
  }) async {
    final totalCount = await _getEntryCount();
    debugPrint('Total entries to read: $totalCount');

    // Report initial progress
    onProgress?.call(0, totalCount);

    if (totalCount == 0) {
      return [];
    }

    final allEntries = <_MinuteEntry>[];
    int index = startIndex < 0 ? 0 : startIndex;
    const chunkSize = 20;

    if (index >= totalCount) {
      debugPrint(
        'Start index ($index) >= total ($totalCount); nothing to read',
      );
      return [];
    }

    while (index < totalCount) {
      List<_MinuteEntry> entries = [];
      bool gotEntries = false;
      for (int attempt = 0; attempt < 3; attempt++) {
        entries = await _readEntries(index, chunkSize);
        if (entries.isNotEmpty) {
          gotEntries = true;
          break;
        }
        debugPrint('Empty entries packet at index=$index attempt=$attempt');
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (!gotEntries) {
        debugPrint('Giving up on empty entries packet at index=$index');
        break;
      }
      allEntries.addAll(entries);
      index += entries.length;
      debugPrint('Read ${allEntries.length}/$totalCount entries');

      // Report progress after each chunk
      onProgress?.call(allEntries.length, totalCount);

      // Small delay to avoid overwhelming BLE
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return allEntries;
  }

  /// Clear all stored data on the watch
  Future<bool> clearData() async {
    if (_characteristic == null) {
      throw StateError('Characteristic not available');
    }

    return await _queueGatt(() async {
      final responseFuture = _characteristic!.onValueReceived.first;

      await _characteristic!.write([
        _AccelCommands.clearData,
      ], withoutResponse: false);

      final response = await responseFuture.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('clearData timed out'),
      );

      if (response.length >= 2 &&
          response[0] == _AccelCommands.clearDataResponse) {
        return response[1] == 0x01;
      }

      return false;
    });
  }

  /// Disconnect from the watch
  Future<void> stop() async {
    await _device?.disconnect();
    connected = false;
  }

  /// Disconnect and dispose all resources/subscriptions.
  Future<void> stopAndDispose() async {
    try {
      await stop();
    } finally {
      disposeSubs();
    }
  }

  Future<T> _retry<T>(
    Future<T> Function() fn, {
    int attempts = 2,
    Duration delay = const Duration(milliseconds: 200),
    String? timeoutCode,
    String? bleErrorCode,
  }) async {
    Object? lastError;
    for (int i = 0; i < attempts; i++) {
      try {
        return await fn();
      } catch (e) {
        lastError = e;
        if (i + 1 < attempts) {
          await Future.delayed(delay);
        }
      }
    }
    if (timeoutCode != null && _isTimeoutError(lastError)) {
      throw StateError(timeoutCode);
    }
    if (bleErrorCode != null && _isBleError(lastError)) {
      throw StateError(bleErrorCode);
    }
    throw lastError ?? StateError('retry_failed');
  }

  bool _isTimeoutError(Object? e) {
    if (e is TimeoutException) return true;
    return e != null && e.toString().contains('Timed out');
  }

  bool _isBleError(Object? e) {
    return e is FlutterBluePlusException ||
        (e != null && e.toString().contains('FlutterBluePlusException'));
  }

  String _mapBleErrorCode(Object e, {required String op}) {
    if (_isTimeoutError(e)) {
      return op == 'connect' ? kPinetimeConnectTimeout : kPinetimeReadTimeout;
    }
    if (_isBleError(e)) {
      return kPinetimeBleError;
    }
    return kPinetimeBleError;
  }

  void _resetGattStateForReconnect() {
    _servicesCache = null;
    _accelNotifyEnabled = false;
    _telemetryNotifyEnabled = false;
    _characteristic = null;
    _ctsCurrentTimeChar = null;
    _ctsLocalTimeChar = null;
    _firmwareRevisionChar = null;
    _telemetryChar = null;
    _firmwareRevision = null;
    _gattQueue = Future.value();
  }

  Future<List<BluetoothService>> _ensureServicesDiscovered() async {
    if (_device == null) return const [];
    if (_servicesCache != null) return _servicesCache!;
    final services = await _device!.discoverServices();
    _servicesCache = services;
    return services;
  }

  Future<void> _ensureAccelNotifyEnabled() async {
    if (_characteristic == null) return;
    if (_accelNotifyEnabled) return;
    await _characteristic!.setNotifyValue(true);
    _accelNotifyEnabled = true;
  }

  Future<void> _ensureTelemetryNotifyEnabled() async {
    if (_telemetryChar == null) return;
    if (_telemetryNotifyEnabled) return;
    await _telemetryChar!.setNotifyValue(true);
    _telemetryNotifyEnabled = true;
  }

  Future<T> _queueGatt<T>(Future<T> Function() op) {
    final completer = Completer<T>();
    _gattQueue = _gattQueue
        .then((_) async {
          try {
            final result = await op();
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          } catch (e, st) {
            if (!completer.isCompleted) {
              completer.completeError(e, st);
            }
          }
        })
        .catchError((_) {});
    return completer.future;
  }
}

/// Internal data structure for minute entries from PineTime
class _MinuteEntry {
  final double count; // Pre-computed acceleration value (counts)
  final int heartRate;
  final int timestamp; // Unix timestamp in seconds

  _MinuteEntry({
    required this.count,
    required this.heartRate,
    required this.timestamp,
  });

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  @override
  String toString() {
    return '_MinuteEntry(count: $count, hr: $heartRate, time: $dateTime)';
  }
}

/// Convert PineTime minute entries to Counts objects
List<Counts> countsFromPineTimeData(List<_MinuteEntry> entries) {
  if (entries.isEmpty) {
    debugPrint("countsFromPineTimeData: empty entries");
    return [];
  }

  // Sort by timestamp
  entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final List<Counts> counts = [];

  for (final entry in entries) {
    // PineTime already stores pre-computed acceleration values and heart rate
    // The acceleration value is already "counts" computed on the watch
    counts.add(
      Counts(t: entry.dateTime, hr: entry.heartRate.toDouble(), a: entry.count),
    );
  }

  debugPrint("done PineTime counts, length = ${counts.length}");
  return counts;
}
