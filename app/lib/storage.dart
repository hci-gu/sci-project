import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static Future<String?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    return userId;
  }

  static Future storeUserId(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userId', userId);
  }

  static Future clearUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userId');
  }
}
