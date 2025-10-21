import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:polar/polar.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/storage.dart';

enum WatchType { polar, demo }

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
