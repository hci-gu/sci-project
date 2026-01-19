import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/watch/watch.dart';

/// UUIDs for InfiniTime Accelerometer Data Service
final _accelDataServiceUuid = Guid("adafac00-4669-6c65-5472-616e73666572");
final _transferCharUuid = Guid("adafac01-4669-6c65-5472-616e73666572");

/// UUIDs for Current Time Service (CTS)
final _ctsServiceUuid = Guid("00001805-0000-1000-8000-00805f9b34fb");
final _currentTimeCharUuid = Guid("00002a2b-0000-1000-8000-00805f9b34fb");
final _localTimeInfoCharUuid = Guid("00002a0f-0000-1000-8000-00805f9b34fb");

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

/// State of the PineTime connection
class PineTimeState {
  final bool connected;
  final int storedEntries;

  PineTimeState({required this.connected, this.storedEntries = 0});
}

/// Service to handle communication with InfiniTime/PineTime watches
class PineTimeService {
  static PineTimeService? _instance;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  BluetoothCharacteristic? _ctsCurrentTimeChar;
  BluetoothCharacteristic? _ctsLocalTimeChar;
  bool connected = false;
  bool initialized = false;
  StreamSubscription? _connectionSub;

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

  static void initialize(String identifier) {
    if (_instance != null && _instance!.initialized) {
      debugPrint('PineTimeService already initialized');
      return;
    }
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
    debugPrint("Starting PineTimeService for $identifier");

    if (connected) {
      return;
    }

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

    // Find and connect to the device
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    late final List<ScanResult> scanResult;
    try {
      scanResult = await FlutterBluePlus.scanResults.firstWhere((results) {
        return results.any((r) => r.device.remoteId.str == identifier);
      }).timeout(
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

    // Listen for disconnection
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
      throw StateError(kConnectionFailedError);
    }
    await _syncCurrentTime();
  }

  Future<bool> _discoverCharacteristic() async {
    if (_device == null) return false;

    final services = await _device!.discoverServices();

    for (final service in services) {
      if (service.uuid == _accelDataServiceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid == _transferCharUuid) {
            _characteristic = c;
            await _characteristic!.setNotifyValue(true);
            debugPrint('Found and enabled accelerometer data characteristic');
            return true;
          }
        }
      }
    }

    debugPrint('Accelerometer data service not found!');
    return false;
  }

  Future<void> _discoverCtsCharacteristics() async {
    if (_device == null) return;

    final services = await _device!.discoverServices();
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

  int _toUint8(int value) => value & 0xFF;

  Future<void> _syncCurrentTime() async {
    if (_device == null) return;
    try {
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

      await _ctsLocalTimeChar!.write(
        [_toUint8(tzQuarters), _toUint8(dst)],
        withoutResponse: false,
      );

      final year = now.year;
      await _ctsCurrentTimeChar!.write(
        [
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
        ],
        withoutResponse: false,
      );
    } catch (e) {
      debugPrint('Failed to sync watch time: $e');
    }
  }

  /// Get current state of the PineTime
  Future<PineTimeState> getState() async {
    if (!connected || _characteristic == null) {
      return PineTimeState(connected: connected);
    }

    try {
      final count = await _getEntryCount();
      return PineTimeState(connected: connected, storedEntries: count);
    } catch (e) {
      debugPrint('Error getting PineTime state: $e');
      return PineTimeState(connected: connected);
    }
  }

  /// Get count of stored entries on the watch
  Future<int> _getEntryCount() async {
    if (_characteristic == null) {
      throw StateError('Characteristic not available');
    }

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
  }

  /// Read entries from the watch
  Future<List<_MinuteEntry>> _readEntries(int startIndex, int count) async {
    if (_characteristic == null) {
      throw StateError('Characteristic not available');
    }

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

    if (response.isEmpty || response[0] != _AccelCommands.readEntriesResponse) {
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
      debugPrint('Start index ($index) >= total ($totalCount); nothing to read');
      return [];
    }

    while (index < totalCount) {
      final entries = await _readEntries(index, chunkSize);
      if (entries.isEmpty) {
        throw Exception('Empty entries packet');
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
  }

  /// Disconnect from the watch
  Future<void> stop() async {
    await _device?.disconnect();
    connected = false;
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
