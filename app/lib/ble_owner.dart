// ble_owner.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:scimovement/storage.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/watch/dfu/dfu_progress.dart';
import 'package:scimovement/models/watch/dfu/dfu_transport.dart';
import 'package:scimovement/models/watch/dfu/dfu_zip.dart';
import 'package:scimovement/models/watch/dfu/legacy_dfu_controller.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/models/watch/pinetime.dart';
import 'package:scimovement/models/watch/telemetry.dart';
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
  bool _dfuRunning = false;
  Completer<void>? _dfuInflight;
  DfuCancelToken? _dfuCancelToken;
  Map<String, dynamic>? _stateCache;
  DateTime? _stateCacheAt;
  static const Duration _stateCacheTtl = Duration(seconds: 1);
  String? _firmwareCache;
  DateTime? _firmwareCacheAt;
  static const Duration _firmwareCacheTtl = Duration(seconds: 30);

  // ---- Sync exclusivity/mutex & tuning knobs ----
  bool _syncing = false;
  Completer<void>? _syncInflight;

  static const Duration _settle = Duration(seconds: 2);
  static const Duration _syncTimeout = Duration(minutes: 4);
  static const Duration _dfuTimeout = Duration(minutes: 15);
  static const Duration _bleOpTimeout = Duration(seconds: 45);
  static const Duration _bleReadTimeout = Duration(minutes: 2);

  /// If more than this many recordings (ACC+HR combined) are present,
  /// purge device storage and start fresh.
  static const int _purgeThresholdSegments = 2;

  Map<String, dynamic> _okResult([Map<String, dynamic>? extra]) {
    return {'ok': true, if (extra != null) ...extra};
  }

  Map<String, dynamic> _errorResult(String code) {
    return {'ok': false, 'error': code};
  }

  Future<T> _withTimeout<T>(
    Future<T> future,
    Duration timeout,
    String code,
  ) async {
    try {
      return await future.timeout(timeout);
    } catch (_) {
      throw StateError(code);
    }
  }

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
            // If a sync or DFU is in progress, don't start a scan (contention)
            if (_syncing || _dfuRunning) {
              sink.send({'type': 'scan', 'event': 'done', 'error': 'busy'});
              reply.send({'ok': false, 'error': 'busy'});
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
          final bool backgroundSync = msg['backgroundSync'] == true;
          final result = await _handleSync(
            progressSink: progressSink,
            backgroundSync: backgroundSync,
          );
          reply.send({...result, 'type': 'sync_result'});
        } else if (msg['cmd'] == 'dfu_start') {
          final SendPort? progressSink = msg['progressSink'];
          final String? version = msg['version'];
          final result = await _handleDfuStart(
            progressSink: progressSink,
            version: version,
          );
          reply.send({'ok': result, 'error': result ? null : 'dfu_failed'});
        } else if (msg['cmd'] == 'dfu_cancel') {
          _dfuCancelToken?.cancel();
          reply.send({'ok': true});
        } else if (msg['cmd'] == 'connect') {
          final result = await _ensureConnected();
          reply.send({'ok': result, 'error': result ? null : 'connect_failed'});
        } else if (msg['cmd'] == 'ping') {
          reply.send({'ok': true});
        } else if (msg['cmd'] == 'get_firmware_version') {
          final s = await _getFirmwareVersion();
          reply.send({'ok': true, 'data': s});
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
          final error =
              e is StateError && e.message is String
                  ? e.message as String
                  : e.toString();
          final payload = {'ok': false, 'error': error};
          if (msg['cmd'] == 'sync') {
            (msg['reply'] as SendPort).send({
              ...payload,
              'type': 'sync_result',
            });
          } else {
            (msg['reply'] as SendPort).send(payload);
          }
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

  Future<Map<String, dynamic>> _handleSync({
    SendPort? progressSink,
    bool backgroundSync = false,
  }) async {
    debugPrint('BleOwner: _handleSync called (backgroundSync=$backgroundSync)');
    return _runExclusiveSync(() async {
      await Storage().reloadPrefs();

      // 1) Server login & drain pending
      final Credentials? credentials = Storage().getCredentials();
      if (credentials == null) {
        debugPrint('BleOwner: no credentials; skipping sync');
        return _errorResult(kWatchSyncLoginRequired);
      }
      try {
        await Api().login(credentials.email, credentials.password);
      } catch (e) {
        debugPrint('BleOwner: login failed: $e');
        return _errorResult(kWatchSyncLoginRequired);
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
        return _errorResult(kWatchNotConfiguredError);
      }

      if (stored.type == WatchType.pinetime) {
        return _handlePineTimeSync(
          progressSink: progressSink,
          backgroundSync: backgroundSync,
        );
      }

      // 2) Connect (Polar)
      final connected = await _ensureConnected();
      debugPrint("Ensure connected: $connected");
      if (!connected) {
        if (PolarService.instance.btState == BluetoothAdapterState.off) {
          return _errorResult(kBluetoothOffError);
        }
        return _errorResult(kConnectionFailedError);
      }

      // 3) Stop both, wait for stabilization, list full set
      await _stopBoth();
      debugPrint("Stopped both");
      await Future.delayed(_settle);
      List<PolarOfflineRecordingEntry> entries = await _withTimeout(
        PolarService.instance.listRecordings(),
        _bleOpTimeout,
        'polar_list_timeout',
      );
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
          deleteSuccess = await _withTimeout(
            PolarService.instance.deleteAllRecordings(entries),
            _bleOpTimeout,
            'polar_delete_timeout',
          );
        } catch (e) {
          debugPrint('BleOwner: deleteAllRecordings failed: $e');
        }
        if (!deleteSuccess) {
          debugPrint('BleOwner: purge failed; aborting sync');
          return _errorResult('polar_purge_failed');
        }
        await _startBoth();
        Storage().setLastSync(DateTime.now());
        debugPrint('BleOwner: sync done (purged due to large recordings)');
        return _okResult();
      }

      final int totalSegments = entries.length;
      if (totalSegments > _purgeThresholdSegments) {
        // filter out the largest of each type
        entries.sort((a, b) => b.size.compareTo(a.size));
        entries = entries.sublist(0, _purgeThresholdSegments);
      }

      // 5) Fetch ENTIRE recordings only (no ranges) and upload if both modalities exist
      bool uploaded = false;
      bool uploadSucceeded = true;
      int dataCount = 0;
      bool deleteAfterUpload = false;
      try {
        debugPrint("BleOwner: fetching recordings");
        final (AccOfflineRecording?, HrOfflineRecording?) recs =
            await _withTimeout(
              PolarService.instance.getRecordings(entries),
              _bleReadTimeout,
              'polar_get_recordings_timeout',
            );
        debugPrint(
          'BleOwner: got recordings: acc=${recs.$1 != null} hr=${recs.$2 != null}',
        );

        final gotAcc = recs.$1 != null;
        final gotHr = recs.$2 != null;

        if (gotAcc && gotHr) {
          final counts = countsFromPolarData(recs.$1!, recs.$2!);
          dataCount = counts.length;

          try {
            await Api().uploadCounts(counts);
            deleteAfterUpload = true;
          } catch (_) {
            await Storage().storePendingCounts(counts);
            uploadSucceeded = false;
          }
          uploaded = true;
        } else {
          // One-sided data present – don't upload; just ensure both are running going forward
          debugPrint(
            'BleOwner: recordings present but missing one modality (acc=$gotAcc hr=$gotHr) - skipping upload',
          );
          dataCount = 0;
        }
      } catch (e, st) {
        debugPrint('BleOwner: getRecordings/upload failed: $e\n$st');
        // On any error, do not delete; we’ll try again next run
      } finally {
        if (deleteAfterUpload) {
          try {
            await _withTimeout(
              PolarService.instance.deleteAllRecordings(entries),
              _bleOpTimeout,
              'polar_delete_timeout',
            );
          } catch (e) {
            debugPrint('BleOwner: deleteAllRecordings failed: $e');
          }
        }
        // 6) Always restart both & verify – do this regardless of success
        await _startBoth();
      }

      Storage().setLastSync(DateTime.now());
      debugPrint('BleOwner: sync done (uploaded=$uploaded)');
      return _okResult({
        'dataCount': dataCount,
        'uploaded': dataCount == 0 ? true : uploadSucceeded,
      });
    });
  }

  Future<bool> _handleDfuStart({
    SendPort? progressSink,
    String? version,
  }) async {
    return _runExclusiveDfu(() async {
      await Storage().reloadPrefs();
      final stored = Storage().getConnectedWatch();
      if (stored == null || stored.type != WatchType.pinetime) {
        return false;
      }

      PineTimeService.initialize(stored.id);
      try {
        await PineTimeService.instance.start();

        final cancelToken = DfuCancelToken();
        _dfuCancelToken = cancelToken;

        String? targetVersion = version;
        if (targetVersion == null) {
          final latest = await Api().getLatestDfuRelease();
          targetVersion = latest?.version;
        }

        if (targetVersion == null || targetVersion == 'unknown') {
          throw StateError('dfu_no_version');
        }

        progressSink?.send(const DfuProgress(phase: 'downloading').toMap());
        final zipBytes = await Api().downloadDfuZip(
          version: targetVersion,
          onProgress: (received, total) {
            progressSink?.send(
              DfuProgress(
                phase: 'downloading',
                current: received,
                total: total,
              ).toMap(),
            );
          },
        );

        progressSink?.send(const DfuProgress(phase: 'preparing').toMap());
        final package = DfuZipParser.parse(zipBytes, version: targetVersion);

        final transport = DfuTransport(PineTimeService.instance.device);
        final controller = LegacyDfuController(
          transport: transport,
          cancelToken: cancelToken,
        );

        await controller.run(
          package,
          onProgress: (progress) => progressSink?.send(progress.toMap()),
        );

        return true;
      } finally {
        try {
          await PineTimeService.instance.stopAndDispose();
        } catch (_) {}
      }
    });
  }

  /// Handle sync for PineTime watch
  Future<Map<String, dynamic>> _handlePineTimeSync({
    SendPort? progressSink,
    bool backgroundSync = false,
  }) async {
    void sendProgress(String phase, int current, int total) {
      progressSink?.send({
        'type': 'sync_progress',
        'phase': phase,
        'current': current,
        'total': total,
      });
    }

    final stored = Storage().getConnectedWatch();
    String? storedId;
    WatchTelemetry? preSyncTelemetry;

    try {
      if (stored == null) {
        return _errorResult(kWatchNotConfiguredError);
      }
      storedId = stored.id;
      final String watchId = storedId!;

      // Send connecting phase
      sendProgress('connecting', 0, 0);

      // Avoid scan/connect contention from any in-flight scan workflow.
      await _handleScanStop();

      // Initialize and connect to PineTime
      PineTimeService.initialize(watchId);
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          await PineTimeService.instance.start();
          break;
        } catch (e) {
          if (attempt == 2) {
            rethrow;
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (!PineTimeService.instance.connected) {
        debugPrint('BleOwner: PineTime connection failed');
        try {
          await PineTimeService.instance.stopAndDispose();
        } catch (_) {}
        return _errorResult(kConnectionFailedError);
      }

      // Fetch telemetry before sync so minute counters reflect pre-sync state.
      preSyncTelemetry = await _fetchPineTimeTelemetryBeforeSync();
      // Give Android GATT a brief cooldown to avoid transient BUSY right after
      // telemetry operations on some devices.
      await Future.delayed(const Duration(milliseconds: 250));

      final state = await _withTimeout(
        PineTimeService.instance.getState(),
        _bleOpTimeout,
        'pinetime_state_timeout',
      );
      final int totalCount = state.storedEntries;

      int lastIndex = Storage().getPineTimeLastIndex(watchId) ?? -1;
      int lastTimestamp = Storage().getPineTimeLastTimestamp(watchId) ?? 0;
      int startIndex = lastIndex + 1;

      if (totalCount == 0) {
        await Storage().setPineTimeLastIndex(watchId, null);
        await Storage().setPineTimeLastTimestamp(watchId, null);
        sendProgress('done', 0, 0);
        Storage().setLastSync(DateTime.now());
        return _okResult({'dataCount': 0});
      }

      if (startIndex > totalCount) {
        // Device likely cleared or rolled over; reset cursor.
        await Storage().setPineTimeLastIndex(watchId, null);
        await Storage().setPineTimeLastTimestamp(watchId, null);
        lastIndex = -1;
        lastTimestamp = 0;
        startIndex = 0;
      }

      // Read entries from the watch with progress callback
      final entries = await _withTimeout(
        PineTimeService.instance.readAllEntries(
          startIndex: startIndex,
          onProgress: (current, total) {
            sendProgress('reading', current, total);
          },
        ),
        _bleReadTimeout,
        'pinetime_read_timeout',
      );
      debugPrint('BleOwner: read ${entries.length} entries from PineTime');

      if (entries.isEmpty) {
        sendProgress('done', 0, 0);
        Storage().setLastSync(DateTime.now());
        return _okResult({'dataCount': 0});
      }

      final int maxTimestamp = entries
          .map((e) => e.timestamp)
          .reduce((a, b) => a > b ? a : b);
      final int newLastIndex = startIndex + entries.length - 1;

      // Filter out already-uploaded timestamps as a safety net
      final filteredEntries =
          lastTimestamp > 0
              ? entries.where((e) => e.timestamp > lastTimestamp).toList()
              : entries;

      // Convert to Counts and upload
      sendProgress('processing', 0, entries.length);
      final counts = countsFromPineTimeData(filteredEntries);
      sendProgress('uploading', 0, entries.length);
      final int dataCount = counts.length;
      bool uploadSucceeded = true;

      if (counts.isNotEmpty) {
        try {
          await Api().uploadCounts(counts);
        } catch (_) {
          await Storage().storePendingCounts(counts);
          uploadSucceeded = false;
        }

        await Storage().setPineTimeLastIndex(watchId, newLastIndex);
        await Storage().setPineTimeLastTimestamp(watchId, maxTimestamp);

        // Clear data on watch after successful upload/persist
        sendProgress('clearing', 0, 0);
        bool cleared = false;
        for (int i = 0; i < 2; i++) {
          try {
            cleared = await PineTimeService.instance.clearData();
          } catch (_) {
            cleared = false;
          }
          if (cleared) break;
        }
        debugPrint('BleOwner: PineTime data cleared: $cleared');
        if (!cleared) {
          return _errorResult('pinetime_clear_failed');
        }

        await Storage().setPineTimeLastIndex(watchId, null);
        await Storage().setPineTimeLastTimestamp(watchId, null);
      } else {
        // Don't advance the cursor when nothing was uploaded/persisted.
        // Advancing here can mark watch data as consumed without upload.
        debugPrint(
          'BleOwner: PineTime produced zero counts; leaving cursor unchanged',
        );
      }

      sendProgress('done', entries.length, entries.length);
      Storage().setLastSync(DateTime.now());
      await _uploadPineTimeTelemetry(
        storedId: watchId,
        dataCount: dataCount,
        uploadSucceeded: uploadSucceeded,
        telemetry: preSyncTelemetry,
        backgroundSync: backgroundSync,
      );
      debugPrint('BleOwner: PineTime sync done');
      return _okResult({
        'dataCount': dataCount,
        'uploaded': dataCount == 0 ? true : uploadSucceeded,
      });
    } catch (e, st) {
      if (e is StateError && e.message is String) {
        debugPrint('BleOwner: PineTime sync failed: ${e.message}');
        return _errorResult(e.message as String);
      }
      debugPrint('BleOwner: PineTime sync failed: $e\n$st');
      return _errorResult('sync_failed');
    } finally {
      try {
        // Attempt telemetry upload even on failure; include "sentToServer=false".
        if (storedId != null) {
          await _uploadPineTimeTelemetry(
            storedId: storedId!,
            dataCount: 0,
            uploadSucceeded: false,
            telemetry: preSyncTelemetry,
            backgroundSync: backgroundSync,
          );
        }
      } catch (_) {}
      try {
        await PineTimeService.instance.stopAndDispose();
      } catch (_) {
        // ignore disconnect errors
      }
    }
  }

  Future<void> _uploadPineTimeTelemetry({
    required String storedId,
    required int dataCount,
    required bool uploadSucceeded,
    WatchTelemetry? telemetry,
    bool backgroundSync = false,
  }) async {
    try {
      if (telemetry != null) {
        final firmwareVersion =
            await PineTimeService.instance.getFirmwareRevision();
        final enriched = telemetry.withContext(
          watchId: storedId,
          firmwareVersion: firmwareVersion,
          timestamp: DateTime.now(),
          sentToServer: dataCount > 0 && uploadSucceeded,
          backgroundSync: backgroundSync,
        );
        await Api().uploadTelemetry(enriched);
        debugPrint('BleOwner: telemetry upload ok');
      } else {
        debugPrint('BleOwner: telemetry fetch empty');
      }
    } catch (e) {
      debugPrint('BleOwner: telemetry upload failed: $e');
    }
  }

  Future<WatchTelemetry?> _fetchPineTimeTelemetryBeforeSync() async {
    const maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        debugPrint(
          'BleOwner: telemetry fetch start (attempt ${attempt + 1}/$maxAttempts)',
        );
        final telemetry = await PineTimeService.instance.getTelemetry();
        if (telemetry != null) {
          debugPrint('BleOwner: telemetry fetch ok');
          return telemetry;
        }
        debugPrint('BleOwner: telemetry fetch empty');
      } catch (e) {
        debugPrint('BleOwner: telemetry fetch failed: $e');
      }

      if (attempt + 1 < maxAttempts) {
        // Keep the same connection and just back off. Reconnect here increases
        // watch_not_found risk when advertisement is brief.
        final bool busy = PineTimeService.instance.lastTelemetryGattBusy;
        final int delayMs =
            busy ? (400 * (attempt + 1)) : (250 * (attempt + 1));
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    return null;
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
            PineTimeService.stopScan();
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
      PineTimeService.stopScan();
    }
  }

  Future<Map<String, dynamic>> debugSyncNow() async {
    return _handleSync();
  }

  /// Get watch state based on connected watch type
  Future<Map<String, dynamic>> _getWatchState() async {
    final now = DateTime.now();
    if (_stateCacheAt != null &&
        now.difference(_stateCacheAt!) < _stateCacheTtl &&
        _stateCache != null) {
      return _stateCache!;
    }

    await Storage().reloadPrefs();
    final stored = Storage().getConnectedWatch();

    if (stored == null) {
      final state = {
        'bluetoothEnabled': false,
        'connected': false,
        'isRecording': false,
      };
      _stateCache = state;
      _stateCacheAt = now;
      return state;
    }

    if (stored.type == WatchType.pinetime) {
      final state = await _getPineTimeState();
      _stateCache = state;
      _stateCacheAt = now;
      return state;
    }

    final state = await _getPolarState();
    _stateCache = state;
    _stateCacheAt = now;
    return state;
  }

  Future<Map<String, dynamic>> _getFirmwareVersion() async {
    if (_syncing || _dfuRunning) {
      debugPrint('PineTime firmware version skipped: busy');
      return {'firmwareVersion': _firmwareCache};
    }
    if (_firmwareCacheAt != null &&
        DateTime.now().difference(_firmwareCacheAt!) < _firmwareCacheTtl &&
        _firmwareCache != null) {
      return {'firmwareVersion': _firmwareCache};
    }
    await Storage().reloadPrefs();
    final stored = Storage().getConnectedWatch();

    if (stored == null || stored.type != WatchType.pinetime) {
      return {'firmwareVersion': null};
    }

    try {
      final service = PineTimeService.instanceOrNull;
      if (service == null || !service.connected) {
        return {'firmwareVersion': null};
      }
      final version = await PineTimeService.instance.getFirmwareRevision(
        refresh: true,
      );
      if (version != null) {
        _firmwareCache = version;
        _firmwareCacheAt = DateTime.now();
      }
      return {'firmwareVersion': version};
    } catch (e) {
      if (e is StateError &&
          (e.message == kWatchNotFoundError ||
              e.message == kBluetoothOffError)) {
        debugPrint('PineTime firmware version unavailable: ${e.message}');
      } else {
        debugPrint('Error getting PineTime firmware version: $e');
      }
      return {'firmwareVersion': null};
    }
  }

  Future<Map<String, dynamic>> _getPineTimeState() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    final bool? bluetoothEnabled =
        adapterState == BluetoothAdapterState.on
            ? true
            : adapterState == BluetoothAdapterState.off
            ? false
            : null;
    try {
      // Check if PineTimeService is initialized before accessing instance
      final service = PineTimeService.instanceOrNull;
      if (service == null || !service.connected) {
        return {
          'bluetoothEnabled': bluetoothEnabled,
          'connected': false,
          'isRecording': false,
        };
      }

      final state = await service.getState(refreshFirmware: true);
      return {
        'bluetoothEnabled': bluetoothEnabled,
        'connected': state.connected,
        'isRecording': false, // PineTime doesn't have continuous recording
        'storedEntries': state.storedEntries,
        'firmwareVersion': state.firmwareRevision,
      };
    } catch (e) {
      debugPrint('Error getting PineTime state: $e');
      return {
        'bluetoothEnabled': bluetoothEnabled,
        'connected': false,
        'isRecording': false,
      };
    }
  }

  Future<Map<String, dynamic>> _getPolarState() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    final bool? bluetoothEnabled =
        adapterState == BluetoothAdapterState.on
            ? true
            : adapterState == BluetoothAdapterState.off
            ? false
            : null;
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
        'bluetoothEnabled': bluetoothEnabled,
        'connected': PolarService.instance.connected,
        'isRecording': state.isRecording,
        'accRecording': accRec,
        'hrRecording': hrRec,
      };
    } catch (e) {
      debugPrint('Error getting Polar state: $e');
      return {
        'bluetoothEnabled': bluetoothEnabled,
        'connected': false,
        'isRecording': false,
      };
    }
  }

  // ------------------- Core helpers -------------------

  void _sendScanEvent(SendPort sink, Map<String, dynamic> event) {
    sink.send({'type': 'scan', ...event});
  }

  Future<Map<String, dynamic>> _runExclusiveSync(
    Future<Map<String, dynamic>> Function() fn,
  ) async {
    if (_dfuRunning) {
      await _dfuInflight?.future;
    }
    if (_syncing) {
      // Coalesce: allow caller to "succeed" by piggy-backing on the in-flight sync.
      await _syncInflight?.future;
      return _okResult();
    }
    _syncing = true;
    _syncInflight = Completer<void>();
    try {
      final result = Completer<Map<String, dynamic>>();
      () async {
        try {
          result.complete(await fn());
        } catch (e) {
          if (!result.isCompleted) {
            if (e is StateError && e.message is String) {
              result.complete(_errorResult(e.message as String));
            } else {
              result.complete(_errorResult('sync_failed'));
            }
          }
        } finally {
          _syncing = false;
          _syncInflight!.complete();
        }
      }();

      return await result.future.timeout(
        _syncTimeout,
        onTimeout: () => _errorResult('sync_timeout'),
      );
    } finally {
      // Lock is released when the sync task actually finishes.
    }
  }

  Future<bool> _runExclusiveDfu(Future<bool> Function() fn) async {
    if (_syncing) {
      await _syncInflight?.future;
    }
    if (_dfuRunning) {
      await _dfuInflight?.future;
      return true;
    }

    _dfuRunning = true;
    _dfuInflight = Completer<void>();

    try {
      final result = Completer<bool>();
      () async {
        try {
          result.complete(await fn());
        } catch (_) {
          if (!result.isCompleted) {
            result.complete(false);
          }
        } finally {
          _dfuRunning = false;
          _dfuCancelToken = null;
          _dfuInflight?.complete();
        }
      }();

      return await result.future.timeout(_dfuTimeout, onTimeout: () => false);
    } finally {
      // Lock is released when the DFU task actually finishes.
    }
  }

  Future<void> _stopBoth() async {
    try {
      await _withTimeout(
        Future.wait([
          PolarService.instance.stopRecording(PolarDataType.acc),
          PolarService.instance.stopRecording(PolarDataType.hr),
        ]),
        _bleOpTimeout,
        'polar_stop_timeout',
      );
    } catch (_) {
      // tolerate "already stopped"
    }

    // Wait until device reports not recording (bounded backoff)
    for (int i = 0; i < 5; i++) {
      final s = await _withTimeout(
        PolarService.instance.getState(),
        _bleOpTimeout,
        'polar_state_timeout',
      );
      if (!s.isRecording) break;
      await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
    }
  }

  Future<void> _startBoth() async {
    // Start in parallel
    await _withTimeout(
      PolarService.instance.startRecording(PolarDataType.acc),
      _bleOpTimeout,
      'polar_start_acc_timeout',
    );
    await Future.delayed(_settle);
    await _withTimeout(
      PolarService.instance.startRecording(PolarDataType.hr),
      _bleOpTimeout,
      'polar_start_hr_timeout',
    );
    await Future.delayed(_settle);

    // Verify both are running (best-effort if per-modality flags exist)
    for (int i = 0; i < 3; i++) {
      final s = await _withTimeout(
        PolarService.instance.getState(),
        _bleOpTimeout,
        'polar_state_timeout',
      );
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
  final ownerPort = owner;

  if (cmd['cmd'] != 'ping') {
    bool ok = await _pingOwner(owner);
    if (!ok && ensureService) {
      owner = await _waitForBleOwnerPort(timeout: const Duration(seconds: 5));
      if (owner != null) {
        ok = await _pingOwner(owner);
      }
    }
    if (!ok) {
      throw Exception('BLE owner not responding');
    }
  }

  final rp = ReceivePort();
  ownerPort.send({...cmd, 'reply': rp.sendPort});

  final result = await rp.first as Map<String, dynamic>;
  rp.close();
  return result;
}

Future<bool> _pingOwner(SendPort owner) async {
  final rp = ReceivePort();
  try {
    owner.send({'cmd': 'ping', 'reply': rp.sendPort});
    final result = await rp.first.timeout(const Duration(seconds: 2));
    return result is Map<String, dynamic> && result['ok'] == true;
  } catch (_) {
    return false;
  } finally {
    rp.close();
  }
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
