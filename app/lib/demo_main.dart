import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/app.dart';
import 'package:scimovement/screens/demo/demo.dart';
import 'package:scimovement/storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/date_symbol_data_local.dart';

void initializeTzAndLocale(String? languageCode) {
  tz.initializeTimeZones();
  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('sv', timeago.SvMessages());
  timeago.setDefaultLocale(languageCode ?? 'en');
  Intl.defaultLocale = languageCode;
  initializeDateFormatting(languageCode);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage().reloadPrefs();
  String? languageCode = Storage().getLanguageCode();
  initializeTzAndLocale(languageCode);
  LicenseRegistry.addLicense(() async* {
    final license =
        await rootBundle.loadString('assets/licenses/icon_license.txt');
    yield LicenseEntryWithLineBreaks(['thenounproject'], license);
  });
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const DemoWrapper(
      child: App(
        onboardingDone: true,
        loggedIn: true,
      ),
    ),
  );
}