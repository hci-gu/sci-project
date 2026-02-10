import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:scimovement/foreground_service/watch_sync.dart';

class ForegroundService {
  ForegroundService._();

  static final ForegroundService instance = ForegroundService._();
  static const int _repeatIntervalMs = 1000 * 15 * 60;
  Completer<void>? _startCompleter;

  Future<void> _requestPlatformPermissions() async {
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }

  void init() {
    debugPrint("ForegroundService: init called");
    FlutterForegroundTask.initCommunicationPort();
    if (kDebugMode) {
      FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'watch_sync_service',
        channelName: 'Wheelability data sync',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_repeatIntervalMs),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> start() async {
    if (await isRunningService) {
      return;
    }
    await _requestPlatformPermissions();

    final ServiceRequestResult result =
        await FlutterForegroundTask.startService(
          serviceTypes: [ForegroundServiceTypes.dataSync],
          serviceId: 500,
          notificationTitle: 'WatchSync is running',
          notificationText: '',
          callback: startSyncWatchService,
        );

    if (result is ServiceRequestFailure) {
      throw result.error;
    }
  }

  Future<void> ensureStarted() async {
    if (await isRunningService) {
      return;
    }
    if (_startCompleter != null) {
      return _startCompleter!.future;
    }

    _startCompleter = Completer<void>();
    try {
      await start();
      _startCompleter!.complete();
    } catch (e, st) {
      _startCompleter!.completeError(e, st);
      rethrow;
    } finally {
      _startCompleter = null;
    }
  }

  Future<bool> get isRunningService => FlutterForegroundTask.isRunningService;

  /// Waits for the BLE owner port to become available.
  /// This ensures the foreground service has fully initialized.
  Future<bool> waitForBleOwner({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final owner = IsolateNameServer.lookupPortByName('ble_owner_port');
      if (owner != null) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return false;
  }

  void _onReceiveTaskData(Object data) {
    debugPrint('ForegroundService::_onReceiveTaskData: $data');
  }
}
