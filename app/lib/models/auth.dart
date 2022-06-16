import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:push/push.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/storage.dart';

class AuthModel extends ChangeNotifier {
  User? _user;
  bool _initialized = false;
  bool _loggedIn = false;
  bool _loading = false;

  bool get initialized => _initialized;
  bool get loggedIn => _loggedIn;
  bool get loading => _loading;
  User? get user => _user;

  Future init() async {
    String? userId = await Storage.getUserId();
    if (userId != null) {
      await login(userId);
    }

    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      _user = await Api().getUser(userId);
    } catch (e) {
      print(e.toString());
    }

    if (_user != null) {
      await Storage.storeUserId(userId);
      _loggedIn = true;

      if (!kIsWeb) {
        // String? token = await Push.instance.token;
        // print(token);
        // if (token != null) {
        // await Api().updateDeviceId(token);
        // }
      }
      _loading = false;
      notifyListeners();
    }

    return _user != null;
  }

  Future logout() async {
    Api().clearUserId();
    await Storage.clearUserId();
    _loggedIn = false;
    notifyListeners();
  }

  Future updateUser(Map<String, dynamic> update) async {
    _loading = true;
    notifyListeners();
    _user = await Api().updateUser(update);
    _loading = false;
    notifyListeners();
  }
}

class IsLoggedInNotifier extends ChangeNotifier {
  late final AuthModel _auth;
  bool _isLoggedIn = false;

  IsLoggedInNotifier(AuthModel auth) {
    _isLoggedIn = auth.loggedIn;
    auth.addListener(() {
      if (_isLoggedIn != auth.loggedIn) {
        _isLoggedIn = auth.loggedIn;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _auth.removeListener(() {});
  }
}
