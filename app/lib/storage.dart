import 'dart:convert';

import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/models/watch/telemetry.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Credentials {
  final String email;
  final String password;

  Credentials(this.email, this.password);
}

class Storage {
  late SharedPreferences prefs;

  Future reloadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.reload();
  }

  Credentials? getCredentials() {
    final String? email = prefs.getString('email');
    final String? password = prefs.getString('password');

    if (email != null && password != null) {
      return Credentials(email, password);
    }

    return null;
  }

  Future storeCredentails(Credentials credentials) async {
    await reloadPrefs();
    await prefs.setString('email', credentials.email);
    await prefs.setString('password', credentials.password);
  }

  Future clearCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('email');
    prefs.remove('password');
  }

  Future storeNotificationRequest(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationRequest', enabled);
  }

  bool getNotificationRequest() {
    return prefs.getBool('notificationRequest') ?? false;
  }

  Future storeOnboardingDone(bool done) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('onboardingDone', done);
  }

  bool getOnboardingDone() {
    return prefs.getBool('onboardingDone') == true;
  }

  Future storeLanguageCode(String languageCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('languageCode', languageCode);
  }

  String? getLanguageCode() {
    return prefs.getString('languageCode');
  }

  Future storeAppFeatures(List<AppFeature> features) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'appFeatures',
      features.map((e) => e.toString()).toList(),
    );
  }

  List<AppFeature> getAppFeatures() {
    List<String>? features = prefs.getStringList('appFeatures');
    if (features == null) {
      return defaultAppFeatures;
    }

    features =
        features.map((e) {
          if (e == 'AppFeature.bladder') {
            return AppFeature.bladderAndBowel.toString();
          }

          return e;
        }).toList();

    List<AppFeature> storedFeatures =
        features
            .map(
              (e) => AppFeature.values.firstWhere(
                (element) => element.toString() == e,
              ),
            )
            .toList();

    if (!storedFeatures.contains(AppFeature.watch)) {
      storedFeatures = [...storedFeatures, AppFeature.watch];
    }

    return storedFeatures;
  }

  Future storeHomeWidgetPage(int page) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('homeWidgetPage', page);
  }

  int getHomeWidgetPage() {
    return prefs.getInt('homeWidgetPage') ?? 0;
  }

  Future storeConnectedWatch(ConnectedWatch watch) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('connectedWatchId', watch.id);
    prefs.setString('connectedWatchType', watch.type.toString());
  }

  ConnectedWatch? getConnectedWatch() {
    final String? id = prefs.getString('connectedWatchId');
    final String? type = prefs.getString('connectedWatchType');

    if (id != null && type != null) {
      return ConnectedWatch(
        id: id,
        type: WatchType.values.firstWhere((e) => e.toString() == type),
      );
    }

    return null;
  }

  Future removeConnectedWatch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('connectedWatchId');
    prefs.remove('connectedWatchType');
  }

  String _pinetimeLastIndexKey(String deviceId) =>
      'pinetimeLastIndex:$deviceId';

  String _pinetimeLastTimestampKey(String deviceId) =>
      'pinetimeLastTimestamp:$deviceId';
  String _pinetimeNeedsClearKey(String deviceId) =>
      'pinetimeNeedsClear:$deviceId';

  int? getPineTimeLastIndex(String deviceId) {
    return prefs.getInt(_pinetimeLastIndexKey(deviceId));
  }

  Future<void> setPineTimeLastIndex(String deviceId, int? index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = _pinetimeLastIndexKey(deviceId);
    if (index == null) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, index);
    }
  }

  int? getPineTimeLastTimestamp(String deviceId) {
    return prefs.getInt(_pinetimeLastTimestampKey(deviceId));
  }

  Future<void> setPineTimeLastTimestamp(String deviceId, int? timestamp) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = _pinetimeLastTimestampKey(deviceId);
    if (timestamp == null) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, timestamp);
    }
  }

  bool getPineTimeNeedsClear(String deviceId) {
    return prefs.getBool(_pinetimeNeedsClearKey(deviceId)) ?? false;
  }

  Future<void> setPineTimeNeedsClear(String deviceId, bool needsClear) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = _pinetimeNeedsClearKey(deviceId);
    if (needsClear) {
      await prefs.setBool(key, true);
    } else {
      await prefs.remove(key);
    }
  }

  DateTime? getLastSync() {
    final int? timestamp = prefs.getInt('lastSync');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  Future<void> setLastSync(DateTime dateTime) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSync', dateTime.millisecondsSinceEpoch);
  }

  Future<void> storePendingCounts(List<Counts> counts) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final existingCounts = getPendingCounts();
    final Map<String, Counts> byTimestamp = <String, Counts>{};

    for (final count in existingCounts) {
      byTimestamp[count.t.toUtc().toIso8601String()] = count;
    }
    for (final count in counts) {
      byTimestamp[count.t.toUtc().toIso8601String()] = count;
    }

    final deduped =
        byTimestamp.values.toList()..sort((a, b) => a.t.compareTo(b.t));
    final serialized = deduped.map((e) => jsonEncode(e.toJson())).toList();

    await prefs.setStringList('pendingCounts', serialized);
  }

  Future<void> clearPendingCounts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('pendingCounts');
  }

  List<Counts> getPendingCounts() {
    final List<String> stored =
        prefs.getStringList('pendingCounts') ?? <String>[];
    final List<Counts> parsed = [];
    for (final s in stored) {
      try {
        parsed.add(Counts.fromJson(jsonDecode(s)));
      } catch (_) {
        // Skip malformed entries (e.g. legacy Dart map strings)
        continue;
      }
    }
    return parsed;
  }

  Future<void> storePendingTelemetry(WatchTelemetry telemetry) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('pendingTelemetry') ?? <String>[];
    final serialized = [...existing, jsonEncode(telemetry.toJson())];
    await prefs.setStringList('pendingTelemetry', serialized);
  }

  Future<void> clearPendingTelemetry() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('pendingTelemetry');
  }

  List<WatchTelemetry> getPendingTelemetry() {
    final List<String> stored =
        prefs.getStringList('pendingTelemetry') ?? <String>[];
    final List<WatchTelemetry> parsed = [];
    for (final s in stored) {
      try {
        parsed.add(
          WatchTelemetry.fromJson(Map<String, dynamic>.from(jsonDecode(s))),
        );
      } catch (_) {
        // Skip malformed entries (e.g. legacy or partially-written payloads)
        continue;
      }
    }
    return parsed;
  }

  static final Storage _instance = Storage._internal();
  factory Storage() {
    return _instance;
  }
  Storage._internal();
}
