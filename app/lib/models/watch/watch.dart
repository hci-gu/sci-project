import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/storage.dart';

enum WatchType { polar, pinetime, demo }

const String kWatchNotFoundError = 'watch_not_found';
const String kBluetoothOffError = 'bluetooth_off';
const String kWatchNotConfiguredError = 'watch_not_configured';
const String kConnectionFailedError = 'watch_connect_failed';

class WatchSyncResult {
  final bool ok;
  final String? error;

  const WatchSyncResult({required this.ok, this.error});
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
    if (state == null) {
      return const WatchSyncResult(ok: false);
    }

    // Both Polar and PineTime sync via the same BLE command
    // BleOwner routes to the correct handler based on watch type
    if (state?.type == WatchType.polar || state?.type == WatchType.pinetime) {
      final result = await sendBleCommand({'cmd': 'sync'});
      return WatchSyncResult(
        ok: result['ok'] == true,
        error: result['error'] as String?,
      );
    }

    return const WatchSyncResult(ok: false);
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
    owner.send({'cmd': 'sync', 'reply': rp.sendPort});

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
