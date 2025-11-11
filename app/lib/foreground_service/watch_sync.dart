// watch_sync.dart
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:polar/polar.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/storage.dart';

@pragma('vm:entry-point')
void startSyncWatchService() {
  FlutterForegroundTask.setTaskHandler(WatchSyncHandler());
}

class WatchSyncHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();
    debugPrint("WatchSyncHandler started at $timestamp");
    try {
      await BleOwner.instance.initialize();
      debugPrint('BleOwner initialized in foreground service isolate');
    } catch (e, st) {
      debugPrint('BleOwner init failed in service: $e\n$st');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // Do *non-BLE* prep here (prefs reload, auth if you want),
    // but let the BLE owner handle actual BLE + sync.
    final SendPort? owner = IsolateNameServer.lookupPortByName(
      'ble_owner_port',
    );

    if (owner == null) {
      debugPrint('WatchSyncHandler: BLE owner port not available');
      return;
    }

    final rp = ReceivePort();
    owner.send({'cmd': 'sync', 'reply': rp.sendPort});

    // Wait for result (add a timeout so we don't hang forever)
    try {
      final _ = await rp.first.timeout(const Duration(minutes: 3));
      Storage().setLastSync(DateTime.now());
    } catch (e) {
      debugPrint('WatchSyncHandler sync timed out or failed: $e');
    } finally {
      rp.close();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint(
      "WatchSyncHandler destroyed at $timestamp, isTimeout: $isTimeout",
    );
  }
}
