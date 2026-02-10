// watch_sync.dart
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/storage.dart';

@pragma('vm:entry-point')
void startSyncWatchService() {
  FlutterForegroundTask.setTaskHandler(WatchSyncHandler());
}

class WatchSyncHandler extends TaskHandler {
  void _sendEvent(Map<String, dynamic> data) {
    FlutterForegroundTask.sendDataToMain({'type': 'watch_sync', ...data});
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();
    debugPrint("WatchSyncHandler started at $timestamp");
    _sendEvent({
      'event': 'onStart',
      'starter': starter.name,
      'timestamp': timestamp.toIso8601String(),
    });
    try {
      await BleOwner.instance.initialize();
      debugPrint('BleOwner initialized in foreground service isolate');
      _sendEvent({
        'event': 'ble_owner_initialized',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e, st) {
      debugPrint('BleOwner init failed in service: $e\n$st');
      _sendEvent({
        'event': 'ble_owner_init_failed',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    debugPrint("WatchSyncHandler repeat event at $timestamp");
    _sendEvent({
      'event': 'onRepeatEvent',
      'timestamp': timestamp.toIso8601String(),
    });
    // Do *non-BLE* prep here (prefs reload, auth if you want),
    // but let the BLE owner handle actual BLE + sync.
    final SendPort? owner = IsolateNameServer.lookupPortByName(
      'ble_owner_port',
    );

    if (owner == null) {
      debugPrint('WatchSyncHandler: BLE owner port not available');
      _sendEvent({
        'event': 'ble_owner_port_missing',
        'timestamp': DateTime.now().toIso8601String(),
      });
      return;
    }

    debugPrint('WatchSyncHandler: sending sync command to BLE owner');

    final rp = ReceivePort();
    owner.send({'cmd': 'sync', 'reply': rp.sendPort, 'backgroundSync': true});

    // Wait for result (add a timeout so we don't hang forever)
    try {
      final _ = await rp
          .where((msg) => msg is Map && msg['type'] == 'sync_result')
          .first
          .timeout(const Duration(minutes: 3));
      Storage().setLastSync(DateTime.now());
      _sendEvent({
        'event': 'sync_result_received',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('WatchSyncHandler sync timed out or failed: $e');
      _sendEvent({
        'event': 'sync_failed_or_timeout',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } finally {
      debugPrint(
        'WatchSyncHandler: sync command completed, closing receive port',
      );
      _sendEvent({
        'event': 'sync_command_completed',
        'timestamp': DateTime.now().toIso8601String(),
      });
      rp.close();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint(
      "WatchSyncHandler destroyed at $timestamp, isTimeout: $isTimeout",
    );
    _sendEvent({
      'event': 'onDestroy',
      'isTimeout': isTimeout,
      'timestamp': timestamp.toIso8601String(),
    });
  }
}
