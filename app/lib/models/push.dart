import 'package:flutter/material.dart';
import 'package:push/push.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/storage.dart';

class PushModel extends ChangeNotifier {
  bool _inited = false;
  bool _shouldAsk = false;

  init(bool loggedIn) async {
    _inited = true;

    _shouldAsk = await Storage.getNotificationRequest() == null;

    String? deviceToken = await token;
    if (deviceToken != null && deviceToken.isNotEmpty && loggedIn) {
      await Api().updateUser({
        'deviceId': deviceToken,
      });
    }

    notifyListeners();
  }

  bool get shouldAsk => _shouldAsk;

  Future<String> requestPermission() async {
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

  Future<String?> get token => Push.instance.token;
}

// useEffect(() {
    //   Push.instance.onNewToken.listen((token) {
    //     print("Just got a new FCM registration token: ${token}");
    //   });

    //   Push.instance.onMessage.listen((message) {
    //     print('RemoteMessage received while app is in foreground:\n'
    //         'RemoteMessage.Notification: ${message.notification} \n'
    //         ' title: ${message.notification?.title.toString()}\n'
    //         ' body: ${message.notification?.body.toString()}\n'
    //         'RemoteMessage.Data: ${message.data}');
    //   });

    //   // Handle push notifications
    //   Push.instance.onBackgroundMessage.listen((message) {
    //     print('RemoteMessage received while app is in background:\n'
    //         'RemoteMessage.Notification: ${message.notification} \n'
    //         ' title: ${message.notification?.title.toString()}\n'
    //         ' body: ${message.notification?.body.toString()}\n'
    //         'RemoteMessage.Data: ${message.data}');
    //   });
    // }, []);