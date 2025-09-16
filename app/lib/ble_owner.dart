// ble_owner.dart
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:polar/polar.dart';

const String kBleOwnerPortName = 'ble_owner_port';

class BleOwner {
  BleOwner._();
  static final BleOwner instance = BleOwner._();

  ReceivePort? _rx;
  bool _connecting = false;
  bool _initialized = false;

  /// Call this from main() once.
  Future<void> initialize() async {
    if (_initialized) return;
    await Storage().reloadPrefs();

    _startPort();

    _initialized = true;
  }

  void _startPort() {
    // Avoid duplicate registration if hot-reload / re-init
    IsolateNameServer.removePortNameMapping(kBleOwnerPortName);
    _rx?.close();

    _rx = ReceivePort();
    IsolateNameServer.registerPortWithName(_rx!.sendPort, kBleOwnerPortName);

    _rx!.listen((msg) async {
      try {
        final SendPort reply = msg['reply'];
        if (msg is Map && msg['cmd'] == 'sync') {
          final result = await _handleSync();
          reply.send({'ok': result, 'error': result ? null : 'sync_failed'});
        } else if (msg is Map && msg['cmd'] == 'connect') {
          final result = await _ensureConnected();
          reply.send({'ok': result, 'error': result ? null : 'connect_failed'});
        } else if (msg is Map && msg['cmd'] == 'ping') {
          reply.send({'ok': true});
        } else if (msg is Map && msg['cmd'] == 'get_state') {
          final s = await _getPolarState();
          reply.send({'ok': true, 'data': s});
        }
      } catch (e, st) {
        debugPrint('BleOwner error: $e\n$st');
        if (msg is Map && msg['reply'] is SendPort) {
          (msg['reply'] as SendPort).send({'ok': false, 'error': e.toString()});
        }
      }
    });

    debugPrint('BleOwner: listening on $kBleOwnerPortName');
  }

  Future<bool> _handleSync() async {
    // Credentials, login, etc., live in the owner
    await Storage().reloadPrefs();
    final Credentials? credentials = Storage().getCredentials();
    if (credentials == null) {
      debugPrint('BleOwner: no credentials');
      return false;
    }
    await Api().login(credentials.email, credentials.password);

    final pendingCounts = Storage().getPendingCounts();
    if (pendingCounts.isNotEmpty) {
      debugPrint('BleOwner: uploading ${pendingCounts.length} pending counts');
      try {
        await Api().uploadCounts(pendingCounts);
        await Storage().clearPendingCounts();
      } catch (e) {
        debugPrint('BleOwner: failed to upload pending counts: $e');
      }
    }

    // Make sure Polar is set up and connected
    final connected = await _ensureConnected();
    if (!connected) {
      debugPrint('BleOwner: unable to connect');
      return false;
    }

    debugPrint('BleOwner: stopping offline recordings');
    await PolarService.instance.stopRecording(PolarDataType.acc);
    await PolarService.instance.stopRecording(PolarDataType.hr);
    // stop recordings so we can fetch and upload them

    // immediately restart so we don't miss data
    await PolarService.instance.startRecording(PolarDataType.acc);
    await PolarService.instance.startRecording(PolarDataType.hr);

    await Future.delayed(const Duration(seconds: 1));

    debugPrint('BleOwner: listing recordings');
    final entries = await PolarService.instance.listRecordings();
    debugPrint('BleOwner: found ${entries.length} entries');

    final (AccOfflineRecording?, HrOfflineRecording?) recs = await PolarService
        .instance
        .getRecordings(entries);

    final gotAcc = recs.$1 != null;
    final gotHr = recs.$2 != null;
    debugPrint('BleOwner: got acc=$gotAcc hr=$gotHr');

    if (gotAcc && gotHr) {
      final counts = countsFromPolarData(recs.$1!, recs.$2!);

      try {
        await Api().uploadCounts(counts);
      } catch (_) {
        await Storage().storePendingCounts(counts);
      }

      await PolarService.instance.deleteAllRecordings();
    }

    Storage().setLastSync(DateTime.now());

    debugPrint('BleOwner: sync done');
    return true;
  }

  Future<bool> _ensureConnected() async {
    await Storage().reloadPrefs();
    final stored = Storage().getConnectedWatch();

    if (stored == null) {
      debugPrint('BleOwner: no stored watch');
      return false;
    }

    PolarService.initialize(stored.id);

    PolarService.instance.start(requestPermissions: false);

    // Start plugin (set up listeners etc.)
    // NOTE: your PolarService.start should return when connected or time out.
    if (PolarService.instance.connected) return true;

    // Guard against re-entrancy
    if (_connecting) {
      // Wait briefly for the in-flight connect to finish
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (PolarService.instance.connected) return true;
      }
      return PolarService.instance.connected;
    }

    _connecting = true;
    try {
      // Try a few times with backoff
      const attempts = 3;
      for (int i = 0; i < attempts; i++) {
        final ok = await PolarService.instance.start(requestPermissions: false);
        if (ok == true || PolarService.instance.connected) return true;

        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
      return PolarService.instance.connected;
    } finally {
      _connecting = false;
    }
  }

  /// Optional: expose a manual trigger callable from UI for testing
  Future<Map<String, dynamic>> debugSyncNow() async {
    final ok = await _handleSync();
    return {'ok': ok};
  }

  Future<Map<String, dynamic>> _getPolarState() async {
    final state = await PolarService.instance.getState();

    return {
      'isRecording': state.isRecording,
      // add more fields if you want (battery, FW, etc.)
    };
  }
}

Future<Map<String, dynamic>> sendBleCommand(Map<String, dynamic> cmd) async {
  final SendPort? owner = IsolateNameServer.lookupPortByName(kBleOwnerPortName);
  if (owner == null) {
    throw Exception('BLE owner not available');
  }

  final rp = ReceivePort();
  owner.send({...cmd, 'reply': rp.sendPort});

  final result = await rp.first as Map<String, dynamic>;
  rp.close();
  return result;
}
