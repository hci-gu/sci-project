import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:polar/polar.dart';

class PolarState {
  final bool isRecording;
  final bool connected;
  final List<PolarOfflineRecordingEntry> recordings;

  PolarState({
    required this.isRecording,
    required this.recordings,
    this.connected = false,
  });
}

class PolarService {
  static PolarService? _instance;
  final polar = Polar();
  bool connected = false;
  bool initialized = false;
  bool started = false;
  BluetoothAdapterState? btState;
  StreamSubscription? _connSub;
  StreamSubscription? _discSub;
  StreamSubscription? _connectingSub;
  StreamSubscription? _btStateSub;

  final String identifier;

  PolarService._(this.identifier);

  static PolarService get instance {
    if (_instance == null) {
      throw StateError(
        'PolarService not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  static Polar get sdk => PolarService.instance.polar;

  static void initialize(String identifier) {
    if (_instance != null && _instance!.initialized) {
      print('PolarService already initialized');
      return;
    }
    _instance = PolarService._(identifier);
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
    _connSub?.cancel();
    _connSub = null;

    _discSub?.cancel();
    _discSub = null;

    _connectingSub?.cancel();
    _connectingSub = null;

    _btStateSub?.cancel();
    _btStateSub = null;

    started = false;
    connected = false;
    initialized = false;

    _instance = null;
  }

  Future start({bool requestPermissions = true}) async {
    print("Starting PolarService for $identifier");

    if (!started) {
      // Only attach listeners the first time we start. They stay active across
      // reconnect attempts.
      _connSub = polar.deviceConnected.listen((_) async {
        print("DEVICE IS CONNECTED");
        connected = true;

        try {
          DateTime? watchTime = await polar.getLocalTime(identifier);
          print("Current watch time: $watchTime");
          DateTime now = DateTime.now();
          print("Current system time: $now");

          if (watchTime != null && watchTime.year < now.year) {
            polar.setLocalTime(identifier, now);
            print("Setting watch time to current time");
          }
        } catch (e) {
          print("Error setting watch time: $e");
        }
      });
      _discSub = polar.deviceDisconnected.listen((_) {
        print("DEVICE DISCONNECTED");
        connected = false;
      });

      _btStateSub = FlutterBluePlus.adapterState.listen((
        BluetoothAdapterState state,
      ) {
        print("Bluetooth state changed: $state");
        btState = state;
      });

      _connectingSub = polar.deviceConnecting.listen((
        PolarDeviceInfo deviceInfo,
      ) async {
        print("Device connecting...");
        print("Device info: $deviceInfo");
      });

      started = true;

      // test log on an interval
      Timer.periodic(Duration(seconds: 10), (_) async {
        print("PolarService heartbeat for $identifier");
      });
    } else {
      print('PolarService already started; reusing existing listeners');
    }

    if (connected) {
      print('PolarService already connected');
      return;
    }

    await initialConnection();
    await polar.connectToDevice(
      identifier,
      requestPermissions: requestPermissions,
    );
  }

  Future<void> initialConnection([int attempts = 0]) async {
    if (attempts > 5) {
      return;
    }

    if (await FlutterBluePlus.adapterState.first ==
        BluetoothAdapterState.unknown) {
      await Future.delayed(const Duration(seconds: 1));
      return initialConnection(attempts + 1);
    }

    return;
  }

  Future<PolarState> getState() async {
    print("getState called for $identifier");
    try {
      List<PolarOfflineRecordingEntry> entries = await listRecordings();
      List<PolarDataType> currentRecordings = await polar
          .getOfflineRecordingStatus(identifier);

      bool isRecording = currentRecordings.isNotEmpty;

      connected = true;
      return PolarState(
        isRecording: isRecording,
        recordings: entries,
        connected: connected,
      );
    } catch (e) {
      print("Error getting Polar state: $e");
      return PolarState(isRecording: false, connected: false, recordings: []);
    }
  }

  Future<List<PolarOfflineRecordingEntry>> listRecordings() async {
    try {
      List<PolarOfflineRecordingEntry> entries = await polar
          .listOfflineRecordings(identifier);

      return entries;
    } catch (e) {
      print("is the error here? $e");
      return [];
    }
  }

  Future<void> startRecording(PolarDataType type) async {
    List<PolarDataType> currentRecordings = await polar
        .getOfflineRecordingStatus(identifier);
    if (!currentRecordings.contains(type)) {
      if (type == PolarDataType.acc) {
        Map<PolarSettingType, int> settings = {
          PolarSettingType.sampleRate: 50,
          PolarSettingType.resolution: 16,
          PolarSettingType.range: 8,
          PolarSettingType.channels: 3,
        };
        await polar.startOfflineRecording(
          identifier,
          type,
          settings: PolarSensorSetting(settings),
        );
      } else if (type == PolarDataType.hr) {
        Map<PolarSettingType, int> settings = {};
        await polar.startOfflineRecording(
          identifier,
          type,
          settings: PolarSensorSetting(settings),
        );
      } else {
        throw ArgumentError('Unsupported data type: $type');
      }
    }
  }

  Future<void> stopRecording(PolarDataType type) async {
    List<PolarDataType> currentRecordings = await polar
        .getOfflineRecordingStatus(identifier);

    if (currentRecordings.contains(type)) {
      await polar.stopOfflineRecording(identifier, type);
    }
  }

  Future<void> deleteAllRecordings(
    List<PolarOfflineRecordingEntry> entries,
  ) async {
    print("Deleting all recordings for $identifier");
    for (var entry in entries) {
      await polar.removeOfflineRecord(identifier, entry);
    }
  }

  Future<void> deleteRecording(PolarOfflineRecordingEntry entry) async {
    await polar.removeOfflineRecord(identifier, entry);
  }

  Future<(AccOfflineRecording?, HrOfflineRecording?)> getRecordings(
    List<PolarOfflineRecordingEntry> entries,
  ) async {
    entries.sort((a, b) => b.size.compareTo(a.size));
    PolarOfflineRecordingEntry? accEntry = entries.firstWhereOrNull(
      (e) => e.type == PolarDataType.acc,
    );
    PolarOfflineRecordingEntry? hrEntry = entries.firstWhereOrNull(
      (e) => e.type == PolarDataType.hr,
    );

    if (accEntry == null || hrEntry == null) {
      return (null, null);
    }

    HrOfflineRecording? hrRecording = await polar.getOfflineHrRecord(
      identifier,
      hrEntry,
    );
    AccOfflineRecording? accRecording = await polar.getOfflineAccRecord(
      identifier,
      accEntry,
    );

    return (accRecording, hrRecording);
  }

  Future stop() async {
    await polar.disconnectFromDevice(identifier);
  }
}
