import 'dart:ui';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:polar/polar.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void startSyncWatchService() {
  FlutterForegroundTask.setTaskHandler(WatchSyncHandler());
}

class WatchSyncHandler extends TaskHandler {
  // StreamSubscription<StepCount>? _stepCountSubs;
  // StreamSubscription<PedestrianStatus>? _pedestrianStatusSubs;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();
    print("WatchSyncHandler started at $timestamp");
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    print("WatchSyncHandler repeat event at $timestamp");
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    final watchId = prefs.getString("connectedWatchId");

    if (userId == null || watchId == null) {
      return;
    }

    PolarService.initialize(watchId);
    bool connected = await PolarService.instance.start();

    if (connected == false) {
      return;
    }

    await PolarService.instance.stopRecording(PolarDataType.acc);
    await PolarService.instance.stopRecording(PolarDataType.hr);

    await Future.delayed(Duration(seconds: 3));

    List<PolarOfflineRecordingEntry> entries =
        await PolarService.instance.listRecordings();

    (AccOfflineRecording?, HrOfflineRecording?) records = await PolarService
        .instance
        .getRecordings(entries);

    if (records.$1 != null && records.$2 != null) {
      List<Counts> counts = countsFromPolarData(records.$1!, records.$2!);
      await Api().uploadCounts(counts);

      await PolarService.instance.deleteAllRecordings();

      // restart offline recording
      await PolarService.instance.startRecording(PolarDataType.acc);
      await PolarService.instance.startRecording(PolarDataType.hr);

      Storage().setLastSync(DateTime.now());
    }
    // PolarService.instance.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // _stepCountSubs?.cancel();
    // _pedestrianStatusSubs?.cancel();
  }
}
