import 'package:polar/polar.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/storage.dart';

enum WatchType { polar }

class ConnectedWatch {
  final String id;
  final WatchType type;

  ConnectedWatch({required this.id, required this.type});

  void initialize() {
    if (type == WatchType.polar) {
      PolarService.initialize(id);
      PolarService.instance.start();
    }
  }

  void dispose() {
    if (type == WatchType.polar) {
      PolarService.instance.stop();
      PolarService.dispose();
    }
  }
}

class ConnectedWatchNotifier extends Notifier<ConnectedWatch?> {
  @override
  ConnectedWatch? build() {
    listenSelf((previous, next) {
      if (previous == null && next != null) {
        Storage().storeConnectedWatch(next);
        next.initialize();
      } else {
        previous?.dispose();
      }
    });

    return Storage().getConnectedWatch();
  }

  void setConnectedWatch(ConnectedWatch watch) {
    state = watch;
    Storage().storeConnectedWatch(watch);
  }

  void removeConnectedWatch() {
    state = null;
    Storage().removeConnectedWatch();
  }

  Future<bool> syncData() async {
    if (state == null) {
      return false;
    }

    if (state?.type == WatchType.polar) {
      await PolarService.instance.stopRecording(PolarDataType.acc);
      await PolarService.instance.stopRecording(PolarDataType.hr);

      await Future.delayed(Duration(seconds: 5));

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

        ref.read(lastSyncProvider.notifier).setLastSync(DateTime.now());
        return true;
      }
    }

    return false;
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
