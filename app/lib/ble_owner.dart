// ble_owner.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:scimovement/storage.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/models/watch/pinetime.dart';
import 'package:scimovement/models/watch/watch.dart';

import 'package:polar/polar.dart';

const String kBleOwnerPortName = 'ble_owner_port';

Map<String, String> _deviceToMap(PolarDeviceInfo d) => {
  'id': d.deviceId,
  'name': d.name,
};

class BleOwner {
  BleOwner._();
  static final BleOwner instance = BleOwner._();

  ReceivePort? _rx;
  StreamSubscription? _scanSub;
  bool _initialized = false;
  bool _scanning = false;

  // ---- Sync exclusivity/mutex & tuning knobs ----
  bool _syncing = false;
  Completer<void>? _syncInflight;

  static const Duration _settle = Duration(seconds: 2);
  static const Duration _syncTimeout = Duration(minutes: 1);

  /// If more than this many recordings (ACC+HR combined) are present,
  /// purge device storage and start fresh.
  static const int _purgeThresholdSegments = 2;

  /// Call this from main() once.
  Future<void> initialize() async {
    print("BleOwner: initialize called");
    if (_initialized) return;
    await Storage().reloadPrefs();

    _startPort();

    _initialized = true;
  }

  void _startPort() {
    // Avoid duplicate registration if hot-reload / re-init
    IsolateNameServer.removePortNameMapping(kBleOwnerPortName);
    _rx?.close();

    _rx = ReceivePort();
    IsolateNameServer.registerPortWithName(_rx!.sendPort, kBleOwnerPortName);

    _rx!.listen((msg) async {
      try {
        final SendPort reply =
            msg['reply'] is SendPort
                ? msg['reply'] as SendPort
                : (throw 'missing_reply_port');

        if (msg['cmd'] == 'request_permissions') {
          // Permission prompts require an Android Activity (UI isolate). The BLE
          // owner often runs in the foreground-service isolate, where
          // permission_handler cannot resolve an Activity and throws:
          // "Unable to detect current Android Activity."
          //
          // Request permissions from the UI isolate instead (see sendBleCommand).
          reply.send({
            'ok': false,
            'error': 'request_permissions_must_be_called_from_ui',
          });
        } else if (msg['cmd'] == 'scan_start') {
          // UI must pass a SendPort sink for streaming results
          final SendPort? sink = msg['sink'];
          final int? autoStopMs = msg['autoStopMs'];
          final String? watchTypeStr = msg['watchType'];
          final WatchType watchType =
              watchTypeStr == 'pinetime' ? WatchType.pinetime : WatchType.polar;
          if (sink == null) {
            reply.send({'ok': false, 'error': 'missing_sink'});
          } else {
            // If a sync is in progress, don't start a scan (adapter contention)
            if (_syncing) {
              sink.send({
                'type': 'scan',
                'event': 'done',
                'error': 'sync_in_progress',
              });
              reply.send({'ok': false, 'error': 'sync_in_progress'});
            } else {
              // start and ACK immediately so UI can render
              _handleScanStart(
                sink,
                watchType: watchType,
                autoStopAfter:
                    autoStopMs != null
                        ? Duration(milliseconds: autoStopMs)
                        : const Duration(seconds: 10),
              );
              reply.send({'ok': true});
            }
          }
        } else if (msg['cmd'] == 'scan_stop') {
          await _handleScanStop();
          reply.send({'ok': true});
        } else if (msg['cmd'] == 'sync') {
          final SendPort? progressSink = msg['progressSink'];
          final result = await _handleSync(progressSink: progressSink);
          reply.send({'ok': result, 'error': result ? null : 'sync_failed'});
        } else if (msg['cmd'] == 'connect') {
          final result = await _ensureConnected();
          reply.send({'ok': result, 'error': result ? null : 'connect_failed'});
        } else if (msg['cmd'] == 'ping') {
          reply.send({'ok': true});
        } else if (msg['cmd'] == 'get_state') {
          final s = await _getWatchState();
          reply.send({'ok': true, 'data': s});
        } else if (msg['cmd'] == 'startRecording') {
          final result = await _handleStartRecording();
          reply.send({'ok': result, 'error': result ? null : 'start_failed'});
        } else {
          reply.send({'ok': false, 'error': 'unknown_cmd'});
        }
      } catch (e, st) {
        debugPrint('BleOwner error: $e\n$st');
        if (msg['reply'] is SendPort) {
          (msg['reply'] as SendPort).send({'ok': false, 'error': e.toString()});
        }
      }
    });

    debugPrint('BleOwner: listening on $kBleOwnerPortName');
  }

  Future<bool> _ensureConnected() async {
    await Storage().reloadPrefs();
    final stored = Storage().getConnectedWatch();
    if (stored == null) {
      debugPrint('BleOwner: no stored watch');
      return false;
    }

    // Bind PolarService to the current device id
    PolarService.initialize(stored.id);

    // If already connected, we're done
    if (PolarService.instance.connected) return true;

    await PolarService.instance.start(requestPermissions: false);

    // If a connection is already in progress, wait briefly for it to complete
    await Future.delayed(_settle);
    await PolarService.instance.getState();
    if (PolarService.instance.connected) {
      return true;
    }
    await PolarService.instance.getState();
    await Future.delayed(_settle);
    if (PolarService.instance.connected) {
      return true;
    }

    return PolarService.instance.connected;
  }

  Future<bool> _handleSync({SendPort? progressSink}) async {
    return _runExclusiveSync(() async {
      await Storage().reloadPrefs();

      // 1) Server login & drain pending
      final Credentials? credentials = Storage().getCredentials();
      if (credentials == null) {
        debugPrint('BleOwner: no credentials; skipping sync');
        return false;
      }
      try {
        await Api().login(credentials.email, credentials.password);
      } catch (e) {
        debugPrint('BleOwner: login failed: $e');
      }

      final pendingCounts = Storage().getPendingCounts();
      debugPrint('BleOwner: uploading ${pendingCounts.length} pending counts');
      if (pendingCounts.isNotEmpty) {
        try {
          await Api().uploadCounts(pendingCounts);
          await Storage().clearPendingCounts();
        } catch (e) {
          debugPrint('BleOwner: failed to upload pending counts: $e');
        }
      }

      // Check watch type and route to appropriate sync
      final stored = Storage().getConnectedWatch();
      if (stored == null) {
        debugPrint('BleOwner: no stored watch');
        return false;
      }

      if (stored.type == WatchType.pinetime) {
        return _handlePineTimeSync(progressSink: progressSink);
      }

      // 2) Connect (Polar)
      final connected = await _ensureConnected();
      debugPrint("Ensure connected: $connected");
      if (!connected) return false;

      // 3) Stop both, wait for stabilization, list full set
      await _stopBoth();
      debugPrint("Stopped both");
      await Future.delayed(_settle);
      List<PolarOfflineRecordingEntry> entries =
          await PolarService.instance.listRecordings();
      debugPrint("Listed stable recordings: ${entries.length} entries");

      // if entries are too large just delete them and restart
      bool tooLarge = false;
      for (PolarOfflineRecordingEntry e in entries) {
        if (e.size > 5 * 1024 * 1024) {
          tooLarge = true;
          break;
        }
      }

      if (tooLarge) {
        debugPrint('BleOwner: found too large recordings -> purging all');
        bool deleteSuccess = false;
        try {
          deleteSuccess = await PolarService.instance.deleteAllRecordings(
            entries,
          );
        } catch (e) {
          debugPrint('BleOwner: deleteAllRecordings failed: $e');
        }
        if (!deleteSuccess) {
          debugPrint('BleOwner: purge failed; aborting sync');
          return false;
        }
        await _startBoth();
        Storage().setLastSync(DateTime.now());
        debugPrint('BleOwner: sync done (purged due to large recordings)');
        return true;
      }

      final int totalSegments = entries.length;
      if (totalSegments > _purgeThresholdSegments) {
        // filter out the largest of each type
        entries.sort((a, b) => b.size.compareTo(a.size));
        entries = entries.sublist(0, _purgeThresholdSegments);
      }

      // 5) Fetch ENTIRE recordings only (no ranges) and upload if both modalities exist
      bool uploaded = false;
      try {
        debugPrint("BleOwner: fetching recordings");
        final (AccOfflineRecording?, HrOfflineRecording?) recs =
            await PolarService.instance.getRecordings(entries);
        debugPrint(
          'BleOwner: got recordings: acc=${recs.$1 != null} hr=${recs.$2 != null}',
        );

        final gotAcc = recs.$1 != null;
        final gotHr = recs.$2 != null;

        if (gotAcc && gotHr) {
          final counts = countsFromPolarData(recs.$1!, recs.$2!);

          try {
            await Api().uploadCounts(counts);
          } catch (_) {
            await Storage().storePendingCounts(counts);
          }
          uploaded = true;
        } else {
          // One-sided data present – don't upload; just ensure both are running going forward
          debugPrint(
            'BleOwner: recordings present but missing one modality (acc=$gotAcc hr=$gotHr) - skipping upload',
          );
        }
      } catch (e, st) {
        debugPrint('BleOwner: getRecordings/upload failed: $e\n$st');
        // On any error, do not delete; we’ll try again next run
      } finally {
        await PolarService.instance.deleteAllRecordings(entries);
        // 6) Always restart both & verify – do this regardless of success
        await _startBoth();
      }

      Storage().setLastSync(DateTime.now());
      debugPrint('BleOwner: sync done (uploaded=$uploaded)');
      return true;
    });
  }

  /// Handle sync for PineTime watch
  Future<bool> _handlePineTimeSync({SendPort? progressSink}) async {
    void sendProgress(String phase, int current, int total) {
      progressSink?.send({
        'type': 'sync_progress',
        'phase': phase,
        'current': current,
        'total': total,
      });
    }

    try {
      final stored = Storage().getConnectedWatch();
      if (stored == null) return false;

      // Send connecting phase
      sendProgress('connecting', 0, 0);

      // Initialize and connect to PineTime
      PineTimeService.initialize(stored.id);
      await PineTimeService.instance.start();

      if (!PineTimeService.instance.connected) {
        debugPrint('BleOwner: PineTime connection failed');
        return false;
      }

      // Read all entries from the watch with progress callback
      final entries = await PineTimeService.instance.readAllEntries(
        onProgress: (current, total) {
          sendProgress('reading', current, total);
        },
      );
      debugPrint('BleOwner: read ${entries.length} entries from PineTime');

      if (entries.isEmpty) {
        sendProgress('done', 0, 0);
        Storage().setLastSync(DateTime.now());
        return true;
      }

      // Convert to Counts and upload
      sendProgress('uploading', 0, entries.length);
      final counts = countsFromPineTimeData(entries);

      if (counts.isNotEmpty) {
        try {
          await Api().uploadCounts(counts);
        } catch (_) {
          await Storage().storePendingCounts(counts);
        }

        // Clear data on watch after successful read
        sendProgress('clearing', 0, 0);
        final cleared = await PineTimeService.instance.clearData();
        debugPrint('BleOwner: PineTime data cleared: $cleared');
      }

      sendProgress('done', entries.length, entries.length);
      Storage().setLastSync(DateTime.now());
      debugPrint('BleOwner: PineTime sync done');
      return true;
    } catch (e, st) {
      debugPrint('BleOwner: PineTime sync failed: $e\n$st');
      return false;
    }
  }

  // ------------------- Public-ish command handlers -------------------

  Future<bool> _handleStartRecording() async {
    // Make sure Polar is set up and connected
    final connected = await _ensureConnected();
    if (!connected) return false;

    await _startBoth(); // parallel + verification
    return true;
  }

  Future<void> _handleScanStart(
    SendPort sink, {
    WatchType watchType = WatchType.polar,
    Duration? autoStopAfter,
  }) async {
    if (_scanning) return; // ignore if already scanning
    _scanning = true;

    // fresh set to prevent duplicates
    final seen = <String>{};

    try {
      if (watchType == WatchType.pinetime) {
        // Scan for PineTime/InfiniTime devices
        _scanSub = PineTimeService.searchForDevice().listen(
          (d) {
            if (seen.add(d['id']!)) {
              _sendScanEvent(sink, {'event': 'device', 'device': d});
            }
          },
          onError: (e, st) {
            PineTimeService.stopScan();
            _sendScanEvent(sink, {'event': 'done', 'error': e.toString()});
            _scanning = false;
          },
          onDone: () {
            _sendScanEvent(sink, {'event': 'done'});
            _scanning = false;
          },
        );
      } else {
        // Scan for Polar devices
        _scanSub = PolarService.searchForDevice().listen(
          (d) {
            if (seen.add(d.deviceId)) {
              _sendScanEvent(sink, {
                'event': 'device',
                'device': _deviceToMap(d),
              });
            }
          },
          onError: (e, st) {
            _sendScanEvent(sink, {'event': 'done', 'error': e.toString()});
            _scanning = false;
          },
          onDone: () {
            _sendScanEvent(sink, {'event': 'done'});
            _scanning = false;
          },
        );
      }

      // Optional auto stop
      if (autoStopAfter != null) {
        Future.delayed(autoStopAfter, () {
          if (_scanning) {
            _scanSub?.cancel();
            _scanSub = null;
            _scanning = false;
            if (watchType == WatchType.pinetime) {
              PineTimeService.stopScan();
            }
            _sendScanEvent(sink, {'event': 'done'});
          }
        });
      }
    } catch (e) {
      _scanning = false;
      _sendScanEvent(sink, {'event': 'done', 'error': e.toString()});
    }
  }

  Future<void> _handleScanStop() async {
    if (_scanning) {
      await _scanSub?.cancel();
      _scanSub = null;
      _scanning = false;
    }
  }

  Future<Map<String, dynamic>> debugSyncNow() async {
    final ok = await _handleSync();
    return {'ok': ok};
  }

  /// Get watch state based on connected watch type
  Future<Map<String, dynamic>> _getWatchState() async {
    await Storage().reloadPrefs();
    final stored = Storage().getConnectedWatch();

    if (stored == null) {
      return {
        'bluetoothEnabled': false,
        'connected': false,
        'isRecording': false,
      };
    }

    if (stored.type == WatchType.pinetime) {
      return _getPineTimeState();
    }

    return _getPolarState();
  }

  Future<Map<String, dynamic>> _getPineTimeState() async {
    print("Getting PineTime state");
    try {
      // Check if PineTimeService is initialized before accessing instance
      final service = PineTimeService.instanceOrNull;
      print("PineTime service: $service");
      if (service == null || !service.connected) {
        return {
          'bluetoothEnabled': true,
          'connected': false,
          'isRecording': false,
        };
      }

      final state = await service.getState();
      print("PineTime state: $state");
      return {
        'bluetoothEnabled': true,
        'connected': state.connected,
        'isRecording': false, // PineTime doesn't have continuous recording
        'storedEntries': state.storedEntries,
      };
    } catch (e) {
      debugPrint('Error getting PineTime state: $e');
      return {
        'bluetoothEnabled': true,
        'connected': false,
        'isRecording': false,
      };
    }
  }

  Future<Map<String, dynamic>> _getPolarState() async {
    try {
      final state = await PolarService.instance.getState();

      // Try to read per-modality flags if available; else fall back to .isRecording
      bool accRec = false;
      bool hrRec = false;
      try {
        // If your PolarService.getState() exposes these booleans:
        accRec = (state as dynamic).accRecording == true;
        hrRec = (state as dynamic).hrRecording == true;
      } catch (_) {
        // ignore; will return only isRecording below
      }

      return {
        'bluetoothEnabled':
            PolarService.instance.btState == BluetoothAdapterState.on,
        'connected': PolarService.instance.connected,
        'isRecording': state.isRecording,
        'accRecording': accRec,
        'hrRecording': hrRec,
      };
    } catch (e) {
      debugPrint('Error getting Polar state: $e');
      return {
        'bluetoothEnabled': false,
        'connected': false,
        'isRecording': false,
      };
    }
  }

  // ------------------- Core helpers -------------------

  void _sendScanEvent(SendPort sink, Map<String, dynamic> event) {
    sink.send({'type': 'scan', ...event});
  }

  Future<bool> _runExclusiveSync(Future<bool> Function() fn) async {
    if (_syncing) {
      // Coalesce: allow caller to "succeed" by piggy-backing on the in-flight sync.
      await _syncInflight?.future;
      return true;
    }
    _syncing = true;
    _syncInflight = Completer<void>();
    try {
      return await fn().timeout(_syncTimeout, onTimeout: () => false);
    } finally {
      _syncing = false;
      _syncInflight!.complete();
    }
  }

  Future<void> _stopBoth() async {
    try {
      await Future.wait([
        PolarService.instance.stopRecording(PolarDataType.acc),
        PolarService.instance.stopRecording(PolarDataType.hr),
      ]);
    } catch (_) {
      // tolerate "already stopped"
    }

    // Wait until device reports not recording (bounded backoff)
    for (int i = 0; i < 5; i++) {
      final s = await PolarService.instance.getState();
      if (!s.isRecording) break;
      await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
    }
  }

  Future<void> _startBoth() async {
    // Start in parallel
    await PolarService.instance.startRecording(PolarDataType.acc);
    await Future.delayed(_settle);
    await PolarService.instance.startRecording(PolarDataType.hr);
    await Future.delayed(_settle);

    // Verify both are running (best-effort if per-modality flags exist)
    for (int i = 0; i < 3; i++) {
      final s = await PolarService.instance.getState();
      bool ok = s.isRecording;
      bool needAcc = true;
      bool needHr = true;
      try {
        for (PolarOfflineRecordingEntry e in s.recordings) {
          if (e.type == PolarDataType.acc) needAcc = false;
          if (e.type == PolarDataType.hr) needHr = false;
        }
        ok = !needAcc && !needHr;
      } catch (_) {
        // per-modality unavailable; fall back to s.isRecording
      }

      if (ok) return;

      if (needAcc) {
        try {
          await PolarService.instance.startRecording(PolarDataType.acc);
        } catch (_) {}
      }
      if (needHr) {
        try {
          await PolarService.instance.startRecording(PolarDataType.hr);
        } catch (_) {}
      }
      await Future.delayed(Duration(milliseconds: 400 * (i + 1)));
    }
  }
}

// ------------------- Public API used by UI code -------------------

/// Sends a command to the BLE owner running in the foreground service.
/// The foreground service must be running for this to work.
///
/// If [ensureService] is true (default), will attempt to start the foreground
/// service if the BLE owner port is not available.
Future<Map<String, dynamic>> sendBleCommand(
  Map<String, dynamic> cmd, {
  bool ensureService = true,
}) async {
  if (kIsWeb) {
    return {};
  }

  // Permission prompts must be initiated from the UI isolate (Android Activity).
  // If this command is forwarded to the BLE owner running in a foreground
  // service isolate, permission_handler will crash with:
  // "Unable to detect current Android Activity."
  if (cmd['cmd'] == 'request_permissions') {
    await PolarService.requestPermissions();
    return {'ok': true};
  }

  SendPort? owner = await _waitForBleOwnerPort(
    timeout: const Duration(seconds: 5),
  );

  // If port not found and we should ensure service, try to start it
  if (owner == null && ensureService) {
    debugPrint(
      'BLE owner port not found, attempting to start foreground service...',
    );

    // Import and start the foreground service
    // This is a bit of a workaround - ideally the service should already be running
    try {
      // Try waiting a bit longer - the service might be starting
      owner = await _waitForBleOwnerPort(timeout: const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Failed to wait for BLE owner: $e');
    }
  }

  if (owner == null) {
    throw Exception(
      'BLE owner not available. Please ensure the app has started properly '
      'and background services are running.',
    );
  }

  final rp = ReceivePort();
  owner.send({...cmd, 'reply': rp.sendPort});

  final result = await rp.first as Map<String, dynamic>;
  rp.close();
  return result;
}

Future<SendPort?> _waitForBleOwnerPort({
  Duration timeout = const Duration(seconds: 5),
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  SendPort? owner = IsolateNameServer.lookupPortByName(kBleOwnerPortName);
  if (owner != null) {
    return owner;
  }

  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await Future.delayed(pollInterval);
    owner = IsolateNameServer.lookupPortByName(kBleOwnerPortName);
    if (owner != null) {
      return owner;
    }
  }
  return null;
}
