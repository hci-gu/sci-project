import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:push/push.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/storage.dart';

class UserState extends StateNotifier<User?> {
  UserState() : super(null);
  bool _initialized = false;
  bool _shouldAskForNotifications = false;

  Future<void> init() async {
    if (_initialized) return;
    String? userId = await Storage.getUserId();
    _initialized = true;

    if (userId != null) {
      await login(userId);
      _shouldAskForNotifications =
          await Storage.getNotificationRequest() == null;

      String? deviceToken = await token;
      if (deviceToken != null && deviceToken.isNotEmpty) {
        await Api().updateUser({
          'deviceId': deviceToken,
        });
      }
    }
  }

  Future<void> login(String userId) async {
    state = await Api().getUser(userId);
    if (state != null) {
      await Storage.storeUserId(userId);
    }
  }

  Future<void> logout() async {
    state = null;
    await Storage.clearUserId();
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

final userProvider = StateNotifierProvider<UserState, User?>((ref) {
  UserState state = UserState();
  state.init();
  return state;
});
