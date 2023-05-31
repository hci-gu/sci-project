import 'package:scimovement/models/app_features.dart';
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
    final List<String>? features = prefs.getStringList('appFeatures');
    if (features == null) {
      return AppFeature.values.toList();
    }

    return features
        .map((e) =>
            AppFeature.values.firstWhere((element) => element.toString() == e))
        .toList();
  }

  static final Storage _instance = Storage._internal();
  factory Storage() {
    return _instance;
  }
  Storage._internal();
}
