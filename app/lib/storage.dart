import 'package:shared_preferences/shared_preferences.dart';

class Credentials {
  final String email;
  final String password;

  Credentials(this.email, this.password);
}

class Storage {
  static Future<Credentials?> getCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('email');
    final String? password = prefs.getString('password');

    if (email != null && password != null) {
      return Credentials(email, password);
    }

    return null;
  }

  static Future storeCredentails(Credentials credentials) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', credentials.email);
    await prefs.setString('password', credentials.password);
  }

  static Future clearCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('email');
    prefs.remove('password');
  }

  static Future storeNotificationRequest(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationRequest', enabled);
  }

  static Future getNotificationRequest() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationRequest');
  }

  static Future storeOnboardingDone(bool done) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('onboardingDone', done);
  }

  static Future<bool> getOnboardingDone() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboardingDone') == true;
  }
}
