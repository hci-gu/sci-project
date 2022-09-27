import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:push/push.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/storage.dart';

class UserState extends StateNotifier<User?> {
  UserState([Credentials? credentials]) : super(null) {
    init(credentials);
  }

  bool _shouldAskForNotifications = false;

  Future<void> init(Credentials? credentials) async {
    if (credentials != null) {
      await login(credentials.email, credentials.password);
    }

    _shouldAskForNotifications = await Storage.getNotificationRequest() == null;

    String? deviceToken = await token;
    if (deviceToken != null && deviceToken.isNotEmpty) {
      await Api().updateUser({
        'deviceId': deviceToken,
      });
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = await Api().login(email, password);
      if (state != null) {
        await Storage.storeCredentails(Credentials(email, password));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    state = null;
    await Storage.clearCredentials();
  }

  Future<void> update(Map<String, dynamic> update) async {
    state = await Api().updateUser(update);
  }

  Future<String?> get token =>
      kIsWeb ? Future.value(null) : Push.instance.token;

  Future<String> requestPermission() async {
    if (kIsWeb) {
      return 'denied';
    }
    bool hasPermission = await Push.instance.requestPermission(
      sound: true,
      alert: true,
      badge: true,
    );
    String? deviceToken = await token;
    if (deviceToken != null) {
      await update({
        'deviceId': deviceToken,
      });
    }
    await Storage.storeNotificationRequest(hasPermission);

    return hasPermission ? 'granted' : 'denied';
  }
}

final userProvider =
    StateNotifierProvider<UserState, User?>((ref) => UserState());
