import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:scimovement/foreground_service/watch_sync.dart';
import 'package:permission_handler/permission_handler.dart';

class ForegroundService {
  ForegroundService._();

  static final ForegroundService instance = ForegroundService._();
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
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
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
        eventAction: ForegroundTaskEventAction.repeat(1000 * 60 * 5),
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

  void _onReceiveTaskData(Object data) async {
    print("ForegroundService::_onReceiveTaskData: $data");
  }
}
