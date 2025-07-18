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
  final bool connected;

  ConnectedWatch({
    required this.id,
    required this.type,
    this.connected = false,
  });

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

    final stored = Storage().getConnectedWatch();
    stored?.initialize();

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

  Future<bool> syncData() async {
    if (state == null) {
      return false;
    }

    if (state?.type == WatchType.polar) {
      print("Stop current recordings");
      print("current watch: ${state?.id}");
      try {
        await PolarService.instance.stopRecording(PolarDataType.acc);
        await PolarService.instance.stopRecording(PolarDataType.hr);
      } catch (_) {}

      await Future.delayed(Duration(seconds: 3));

      try {
        print("list entries");
        List<PolarOfflineRecordingEntry> entries =
            await PolarService.instance.listRecordings();
        print("listed");
        (AccOfflineRecording?, HrOfflineRecording?) records = await PolarService
            .instance
            .getRecordings(entries);
        print("got recordings");

        if (records.$1 != null && records.$2 != null) {
          print("calculate counts");
          List<Counts> counts = countsFromPolarData(records.$1!, records.$2!);
          print("pre upload");
          await Api().uploadCounts(counts);
          print("post upload");

          await PolarService.instance.deleteAllRecordings();
          print("delete all recordings");
        }
        // restart offline recording
        await PolarService.instance.startRecording(PolarDataType.acc);
        await PolarService.instance.startRecording(PolarDataType.hr);
        print("start recording");

        ref.read(lastSyncProvider.notifier).setLastSync(DateTime.now());

        return true;
      } catch (e) {
        print("error caught, deleting all recordings: $e");
        await PolarService.instance.deleteAllRecordings();

        print("restart recording");

        // restart offline recording
        await PolarService.instance.startRecording(PolarDataType.acc);
        await PolarService.instance.startRecording(PolarDataType.hr);
        print("restarted");
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
