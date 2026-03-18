import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/models/home_refresh.dart';
import 'package:scimovement/storage.dart';

enum WatchType { polar, pinetime, demo }

const String kWatchNotFoundError = 'watch_not_found';
const String kBluetoothOffError = 'bluetooth_off';
const String kWatchNotConfiguredError = 'watch_not_configured';
const String kConnectionFailedError = 'watch_connect_failed';
const String kWatchSyncLoginRequired = 'watch_sync_login_required';
const String kSyncSkippedDfuInProgress = 'sync_skipped_dfu_in_progress';
const String kSyncSkippedSyncInProgress = 'sync_skipped_sync_in_progress';
const String kPinetimeConnectTimeout = 'pinetime_connect_timeout';
const String kPinetimeReadTimeout = 'pinetime_read_timeout';
const String kPinetimeBleError = 'pinetime_ble_error';
const String kPinetimeCharacteristicMissing = 'pinetime_characteristic_missing';

class WatchSyncResult {
  final bool ok;
  final String? error;
  final int? dataCount;
  final bool? uploaded;

  const WatchSyncResult({
    required this.ok,
    this.error,
    this.dataCount,
    this.uploaded,
  });
}

class WatchSyncProgress {
  final String phase;
  final int current;
  final int total;

  const WatchSyncProgress({this.phase = '', this.current = 0, this.total = 0});

  double get progress => total > 0 ? current / total : 0.0;
  bool get isActive => phase.isNotEmpty;
}

class WatchSyncNotice {
  final int id;
  final String error;

  const WatchSyncNotice({required this.id, required this.error});
}

class ConnectedWatch {
  final String id;
  final WatchType type;
  final bool connected;
  static const int _maxConnectAttempts = 3;
  bool _disposed = false;

  ConnectedWatch({
    required this.id,
    required this.type,
    this.connected = false,
  });

  Future<void> initialize() async {
    if (_disposed) {
      return;
    }

    // For Polar, we auto-connect and start recording
    // For PineTime, connection happens during manual sync only
    if (type == WatchType.polar) {
      await _connectWithRetry();
    }
    // PineTime doesn't need initialization - sync is manual
  }

  Future<void> _connectWithRetry([int attempt = 0]) async {
    if (_disposed) return;

    try {
      await sendBleCommand({'cmd': 'connect'});
    } catch (e) {
      debugPrint('ConnectedWatch: connect attempt ${attempt + 1} failed: $e');
      if (attempt + 1 >= _maxConnectAttempts || _disposed) {
        return;
      }
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      await _connectWithRetry(attempt + 1);
    }
  }

  void dispose() {
    _disposed = true;
    // if (type == WatchType.polar) {
    //   PolarService.instance.stop();
    //   PolarService.dispose();
    // }
  }
}

class ConnectedWatchNotifier extends Notifier<ConnectedWatch?> {
  Future<WatchSyncResult>? _activeSync;
  static const Duration _postSyncRefreshDelay = Duration(seconds: 3);

  @override
  ConnectedWatch? build() {
    listenSelf((previous, next) {
      if (previous == null && next != null) {
        Storage().storeConnectedWatch(next);
        unawaited(next.initialize());
      } else {
        previous?.dispose();
      }
    });

    final stored = Storage().getConnectedWatch();
    if (stored != null) {
      unawaited(stored.initialize());
    }

    return stored;
  }

  void setConnectedWatch(ConnectedWatch watch) {
    state = watch;
    Storage().storeConnectedWatch(watch);
  }

  void removeConnectedWatch() {
    state = null;
    Storage().removeConnectedWatch();
  }

  Future<WatchSyncResult> syncData() async {
    return syncDataWithOptions();
  }

  Future<WatchSyncResult> syncDataWithOptions({
    bool backgroundSync = false,
    SendPort? progressSink,
    bool userInitiated = true,
  }) async {
    if (state == null) {
      return const WatchSyncResult(ok: false);
    }

    if (_activeSync != null) {
      return _activeSync!;
    }

    ref.read(watchSyncInProgressProvider.notifier).state = true;
    ref
        .read(watchSyncProgressProvider.notifier)
        .state = const WatchSyncProgress(phase: 'connecting');
    ref.read(lastWatchSyncAttemptProvider.notifier).state = DateTime.now();

    // Both Polar and PineTime sync via the same BLE command
    // BleOwner routes to the correct handler based on watch type
    if (state?.type != WatchType.polar && state?.type != WatchType.pinetime) {
      ref.read(watchSyncInProgressProvider.notifier).state = false;
      ref.read(watchSyncProgressProvider.notifier).state =
          const WatchSyncProgress();
      return const WatchSyncResult(ok: false);
    }

    final future = () async {
      void dispatchProgress({
        required String phase,
        int current = 0,
        int total = 0,
      }) {
        final progress = WatchSyncProgress(
          phase: phase,
          current: current,
          total: total,
        );
        ref.read(watchSyncProgressProvider.notifier).state = progress;
        progressSink?.send({
          'type': 'sync_progress',
          'phase': phase,
          'current': current,
          'total': total,
        });
      }

      final ReceivePort? internalProgressPort =
          backgroundSync ? null : ReceivePort();
      final StreamSubscription<dynamic>? progressSubscription =
          internalProgressPort?.listen((msg) {
            if (msg is Map && msg['type'] == 'sync_progress') {
              dispatchProgress(
                phase: msg['phase']?.toString() ?? '',
                current: msg['current'] as int? ?? 0,
                total: msg['total'] as int? ?? 0,
              );
            }
          });

      final result = await sendBleCommand({
        'cmd': 'sync',
        'backgroundSync': backgroundSync,
        if (internalProgressPort != null)
          'progressSink': internalProgressPort.sendPort
        else if (progressSink != null)
          'progressSink': progressSink,
      });

      try {
        final watchSyncResult = WatchSyncResult(
          ok: result['ok'] == true,
          error: result['error'] as String?,
          dataCount: result['dataCount'] as int?,
          uploaded: result['uploaded'] as bool?,
        );

        if (watchSyncResult.ok) {
          ref.read(lastSyncProvider.notifier).setLastSync(DateTime.now());
          if (!backgroundSync) {
            await _refreshAppDataAfterSync(
              watchSyncResult,
              onProgress: dispatchProgress,
            );
          }
        } else if (!userInitiated && watchSyncResult.error != null) {
          ref.read(watchSyncNoticeProvider.notifier).state = WatchSyncNotice(
            id: DateTime.now().microsecondsSinceEpoch,
            error: watchSyncResult.error!,
          );
        }

        return watchSyncResult;
      } finally {
        await progressSubscription?.cancel();
        internalProgressPort?.close();
      }
    }();

    _activeSync = future;
    try {
      return await future;
    } finally {
      _activeSync = null;
      ref.read(watchSyncInProgressProvider.notifier).state = false;
      ref.read(watchSyncProgressProvider.notifier).state =
          const WatchSyncProgress();
    }
  }

  Future<void> _refreshAppDataAfterSync(
    WatchSyncResult result, {
    void Function({required String phase, int current, int total})? onProgress,
  }) async {
    final bool waitForServerProcessing =
        result.ok && (result.dataCount ?? 0) > 0 && result.uploaded != false;

    if (waitForServerProcessing) {
      onProgress?.call(phase: 'processing');
      await Future.delayed(_postSyncRefreshDelay);
    }

    refreshHomeProviders(ref.invalidate);
  }

  Future<bool> syncIfNeeded({
    Duration minInterval = const Duration(minutes: 12),
  }) async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.iOS ||
        state == null) {
      return false;
    }

    final isSyncing = ref.read(watchSyncInProgressProvider);
    if (isSyncing) {
      return false;
    }

    final now = DateTime.now();
    final lastSync = ref.read(lastSyncProvider);
    if (lastSync != null && now.difference(lastSync) < minInterval) {
      return false;
    }

    final lastAttempt = ref.read(lastWatchSyncAttemptProvider);
    if (lastAttempt != null && now.difference(lastAttempt) < minInterval) {
      return false;
    }

    final result = await syncDataWithOptions(
      backgroundSync: false,
      userInitiated: false,
    );
    return result.ok;
  }

  Future<bool> startRecording() async {
    final SendPort? owner = IsolateNameServer.lookupPortByName(
      'ble_owner_port',
    );

    if (owner == null) {
      print('WatchSyncHandler: BLE owner port not available');
      return false;
    }

    final rp = ReceivePort();
    owner.send({'cmd': 'startRecording', 'reply': rp.sendPort});

    // Wait for result (add a timeout so we don't hang forever)
    try {
      final result = await rp.first.timeout(const Duration(minutes: 2));
      print('WatchSyncHandler sync result: $result');
      return result['ok'] == true;
    } catch (e) {
      print('WatchSyncHandler sync timed out or failed: $e');
    } finally {
      rp.close();
    }

    return false;

    // Map<String, dynamic> result = await sendBleCommand({'cmd': 'sync'});
  }
}

final connectedWatchProvider =
    NotifierProvider<ConnectedWatchNotifier, ConnectedWatch?>(
      ConnectedWatchNotifier.new,
    );

final watchSyncInProgressProvider = StateProvider<bool>((ref) => false);
final watchSyncProgressProvider = StateProvider<WatchSyncProgress>(
  (ref) => const WatchSyncProgress(),
);
final watchSyncNoticeProvider = StateProvider<WatchSyncNotice?>((ref) => null);
final lastWatchSyncAttemptProvider = StateProvider<DateTime?>((ref) => null);

class LastSyncNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    listenSelf((previous, next) {
      if (next != null) {
        Storage().setLastSync(next);
      }
    });

    return Storage().getLastSync();
  }

  void setLastSync(DateTime dateTime) {
    state = dateTime;
  }
}

final lastSyncProvider = NotifierProvider<LastSyncNotifier, DateTime?>(
  LastSyncNotifier.new,
);
