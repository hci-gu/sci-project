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
  StreamSubscription? _featureReadySub;

  final Set<PolarSdkFeature> _readyFeatures = {};
  final Map<PolarSdkFeature, List<Completer<void>>> _featureWaiters = {};

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

  static Future<void> requestPermissions() async {
    return Polar().requestPermissions();
  }

  static Stream<PolarDeviceInfo> searchForDevice() {
    return Polar().searchForDevice();
  }

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

    _featureReadySub?.cancel();
    _featureReadySub = null;

    _resetFeatureState();

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
        _resetFeatureState(
          StateError('Device disconnected before features became ready'),
        );
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

      _featureReadySub = polar.sdkFeatureReady.listen((event) {
        if (event.identifier != identifier) {
          return;
        }

        final PolarSdkFeature feature = event.feature;
        _markFeatureReady(feature);
      });
    }

    if (connected) {
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
      final bool offlineReady = await _waitForOfflineRecordingFeature();
      if (!offlineReady) {
        print(
          'Offline recording feature not ready; returning default PolarState',
        );
        return PolarState(
          isRecording: false,
          recordings: [],
          connected: connected,
        );
      }

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
    final bool offlineReady = await _waitForOfflineRecordingFeature();
    if (!offlineReady) {
      print('Offline recording feature not ready; returning empty list');
      return [];
    }

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
    final bool offlineReady = await _waitForOfflineRecordingFeature();
    if (!offlineReady) {
      print('Cannot start recording; offline recording feature not ready');
      return;
    }

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
        try {
          await polar.startOfflineRecording(
            identifier,
            type,
            settings: PolarSensorSetting(settings),
          );
        } catch (e) {
          print(e);
        }
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
    final bool offlineReady = await _waitForOfflineRecordingFeature();
    if (!offlineReady) {
      print('Cannot stop recording; offline recording feature not ready');
      return;
    }

    List<PolarDataType> currentRecordings = await polar
        .getOfflineRecordingStatus(identifier);

    if (currentRecordings.contains(type)) {
      await polar.stopOfflineRecording(identifier, type);
    }
  }

  Future<bool> deleteAllRecordings(
    List<PolarOfflineRecordingEntry> entries,
  ) async {
    final bool offlineReady = await _waitForOfflineRecordingFeature();
    if (!offlineReady) {
      print('Cannot delete recordings; offline recording feature not ready');
      return false;
    }

    print("Deleting all recordings for $identifier");
    for (var entry in entries) {
      await polar.removeOfflineRecord(identifier, entry);
    }

    await Future.delayed(Duration(seconds: 1));

    // get entries again
    entries = await listRecordings();
    if (entries.isNotEmpty) {
      return false;
    }

    return true;
  }

  Future<void> deleteRecording(PolarOfflineRecordingEntry entry) async {
    final bool offlineReady = await _waitForOfflineRecordingFeature();
    if (!offlineReady) {
      print('Cannot delete recording; offline recording feature not ready');
      return;
    }

    await polar.removeOfflineRecord(identifier, entry);
  }

  Future<(AccOfflineRecording?, HrOfflineRecording?)> getRecordings(
    List<PolarOfflineRecordingEntry> entries,
  ) async {
    final bool offlineReady = await _waitForOfflineRecordingFeature();
    if (!offlineReady) {
      print('Cannot fetch recordings; offline recording feature not ready');
      return (null, null);
    }

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

  void _markFeatureReady(PolarSdkFeature feature) {
    if (_readyFeatures.contains(feature)) {
      return;
    }

    _readyFeatures.add(feature);
    final waiters = _featureWaiters.remove(feature);
    if (waiters != null) {
      for (final completer in waiters) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }
  }

  Future<bool> _waitForOfflineRecordingFeature() {
    return _waitForFeature(PolarSdkFeature.offlineRecording);
  }

  Future<bool> _waitForFeature(
    PolarSdkFeature feature, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_readyFeatures.contains(feature)) {
      return true;
    }

    final completer = Completer<void>();
    final waiters = _featureWaiters.putIfAbsent(
      feature,
      () => <Completer<void>>[],
    );
    waiters.add(completer);

    try {
      await completer.future.timeout(timeout);
      return _readyFeatures.contains(feature);
    } on TimeoutException catch (e) {
      waiters.remove(completer);
      if (waiters.isEmpty) {
        _featureWaiters.remove(feature);
      }
      print('Timed out waiting for feature $feature: $e');
      return false;
    } catch (error, stackTrace) {
      waiters.remove(completer);
      if (waiters.isEmpty) {
        _featureWaiters.remove(feature);
      }
      print('Error waiting for feature $feature: $error');
      print(stackTrace);
      return false;
    }
  }

  void _resetFeatureState([Object? error]) {
    if (_featureWaiters.isNotEmpty) {
      for (final waiters in _featureWaiters.values) {
        for (final completer in waiters) {
          if (!completer.isCompleted) {
            if (error != null) {
              completer.completeError(error);
            } else {
              completer.completeError(
                StateError('Feature readiness wait was reset'),
              );
            }
          }
        }
      }
      _featureWaiters.clear();
    }

    _readyFeatures.clear();
  }
}
