import 'dart:isolate';
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

    // Do *non-BLE* prep here (prefs reload, auth if you want),
    // but let the BLE owner handle actual BLE + sync.
    final SendPort? owner = IsolateNameServer.lookupPortByName(
      'ble_owner_port',
    );

    if (owner == null) {
      print('WatchSyncHandler: BLE owner port not available');
      return;
    }

    final rp = ReceivePort();

    owner.send({'cmd': 'sync', 'reply': rp.sendPort});

    // Wait for result (add a timeout so we don't hang forever)
    try {
      final result = await rp.first.timeout(const Duration(minutes: 2));
      print('WatchSyncHandler sync result: $result');
    } catch (e) {
      print('WatchSyncHandler sync timed out or failed: $e');
    } finally {
      rp.close();
    }
  }

  // @override
  // void onRepeatEvent(DateTime timestamp) async {
  //   print("WatchSyncHandler repeat event at $timestamp");
  //   await Storage().reloadPrefs();
  //   final prefs = await SharedPreferences.getInstance();
  //   Credentials? credentials = Storage().getCredentials();
  //   final watchId = prefs.getString("connectedWatchId");

  //   print("WatchSyncHandler credentials: $credentials, watchId: $watchId");

  //   if (credentials == null || watchId == null) {
  //     return;
  //   }

  //   await Api().login(credentials.email, credentials.password);

  //   PolarService.initialize(watchId);
  //   await PolarService.instance.start(requestPermissions: false);
  //   // PolarService.instance.
  //   await Future.delayed(Duration(seconds: 15));
  //   bool connected = PolarService.instance.connected;

  //   print("WatchSyncHandler connected: $connected");

  //   if (connected == false) {
  //     return;
  //   }

  //   print("WatchSyncHandler stopping recordings");

  //   await PolarService.instance.stopRecording(PolarDataType.acc);
  //   await PolarService.instance.stopRecording(PolarDataType.hr);

  //   await Future.delayed(Duration(seconds: 3));

  //   print("WatchSyncHandler listing recordings");

  //   List<PolarOfflineRecordingEntry> entries =
  //       await PolarService.instance.listRecordings();

  //   print("WatchSyncHandler found recordings: ${entries.length}");

  //   (AccOfflineRecording?, HrOfflineRecording?) records = await PolarService
  //       .instance
  //       .getRecordings(entries);

  //   print(
  //     "WatchSyncHandler found recordings: ${records.$1 != null}, ${records.$2 != null}",
  //   );

  //   if (records.$1 != null && records.$2 != null) {
  //     List<Counts> counts = countsFromPolarData(records.$1!, records.$2!);
  //     await Api().uploadCounts(counts);

  //     await PolarService.instance.deleteAllRecordings();

  //     // restart offline recording
  //     await PolarService.instance.startRecording(PolarDataType.acc);
  //     await PolarService.instance.startRecording(PolarDataType.hr);

  //     Storage().setLastSync(DateTime.now());
  //   }

  //   print("DONE");
  //   // PolarService.instance.
  // }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // _stepCountSubs?.cancel();
    // _pedestrianStatusSubs?.cancel();
  }
}
