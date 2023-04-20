import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:push/push.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/storage.dart';

class UserState extends StateNotifier<User?> {
  UserState([Credentials? credentials]) : super(null) {
    init(credentials);
  }

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  Future<void> init(Credentials? credentials) async {
    if (credentials == null) return;
    await login(credentials.email, credentials.password);

    if (state == null) return;
    if (state!.deviceId == null || state!.deviceId!.isEmpty) return;

    String? deviceToken = await token;
    if (deviceToken != null && deviceToken.isNotEmpty) {
      _hasPermission = true;
      await Api().updateUser({
        'deviceId': deviceToken,
      });
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = await Api().login(email, password);
      if (state != null) {
        await Storage().storeCredentails(Credentials(email, password));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String email, String password,
      [Map<dynamic, dynamic> values = emptyBody]) async {
    try {
      state = await Api().register(email, password, values);
      if (state != null) {
        await Storage().storeCredentails(Credentials(email, password));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await Api().deleteAccount();
      logout();
    } catch (e) {}
  }

  Future<void> logout() async {
    state = null;
    await Storage().clearCredentials();
  }

  Future<void> update(Map<String, dynamic> update) async {
    state = await Api().updateUser(update);
  }

  Future updateNotificationSettings(NotificationSettings settings) async {
    state = await Api().updateUser({
      'notificationSettings': settings.toJson(),
    });
  }

  Future<String?> get token =>
      kIsWeb ? Future.value(null) : Push.instance.token;

  Future<String> requestNotificationPermission() async {
    if (kIsWeb) {
      return 'denied';
    }
    _hasPermission = await Push.instance.requestPermission(
      sound: true,
      alert: true,
      badge: true,
    );
    if (_hasPermission) {
      String? deviceToken = await token;
      if (deviceToken != null) {
        await update({
          'deviceId': deviceToken,
        });
      }
    }
    await Storage().storeNotificationRequest(_hasPermission);

    return _hasPermission ? 'granted' : 'denied';
  }

  Future turnOffNotifications() async {
    await update({
      'deviceId': '',
    });
  }

  factory UserState.fromMockUser(User user) {
    UserState userState = UserState();
    userState.state = user;
    return userState;
  }
}

final userProvider =
    StateNotifierProvider<UserState, User?>((ref) => UserState());

final userHasDataProvider = Provider<bool>((ref) {
  User? user = ref.watch(userProvider);
  return user != null && user.hasData;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  User? user = ref.watch(userProvider);
  return user != null && user.deviceId != null && user.deviceId!.isNotEmpty;
});
