import 'package:flutter/material.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/storage.dart';

class AuthModel extends ChangeNotifier {
  bool _initialized = false;
  bool _loggedIn = false;

  bool get initialized => _initialized;
  bool get loggedIn => _loggedIn;

  Future init() async {
    String? userId = await Storage.getUserId();
    if (userId != null) {
      await login(userId);
    }

    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String userId) async {
    User? user = await Api().getUser(userId);

    if (user != null) {
      await Storage.storeUserId(userId);
      _loggedIn = true;
      notifyListeners();
    }

    return user != null;
  }

  Future logout() async {
    Api().clearUserId();
    await Storage.clearUserId();
    _loggedIn = false;
    notifyListeners();
  }
}
