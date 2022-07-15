import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:push/push.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/storage.dart';

class PushModel extends ChangeNotifier {
  bool _shouldAsk = false;

  init(bool loggedIn) async {
    _shouldAsk = await Storage.getNotificationRequest() == null;

    /*
    String? deviceToken = await token;
    if (deviceToken != null && deviceToken.isNotEmpty && loggedIn) {
      await Api().updateUser({
        'deviceId': deviceToken,
      });
    }*/

    notifyListeners();
  }

  bool get shouldAsk => _shouldAsk;

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
      await Api().updateUser({
        'deviceId': deviceToken,
      });
    }

    return hasPermission ? 'granted' : 'denied';
  }

  Future<String?> get token {
    if (kIsWeb) {
      return Future.value(null);
    }
    return Push.instance.token;
  }
}
