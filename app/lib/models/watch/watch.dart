import 'package:polar/polar.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/ble_owner.dart';
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

  void initialize() async {
    if (type == WatchType.polar) {
      await sendBleCommand({'cmd': 'connect'});
    }
  }

  void dispose() {
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
      await sendBleCommand({'cmd': 'sync'});
    }

    return false;
  }

  Future startRecording() async {
    // await PolarService.instance.deleteAllRecordings();
    // ref.read(lastSyncProvider.notifier).setLastSync(DateTime.now());

    // print("restart recording");

    // // restart offline recording
    // await PolarService.instance.startRecording(PolarDataType.acc);
    // await PolarService.instance.startRecording(PolarDataType.hr);
    // print("restarted");
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
