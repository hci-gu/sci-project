import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/app.dart';
import 'package:scimovement/models/auth.dart';
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
  bool onboardingDone = Storage().getOnboardingDone();
  Credentials? credentials = Storage().getCredentials();
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
    ProviderScope(
      overrides: credentials != null
          ? [userProvider.overrideWith((ref) => UserState(credentials))]
          : [],
      child: App(
        onboardingDone: onboardingDone,
        loggedIn: credentials != null && credentials.email.isNotEmpty,
      ),
    ),
  );
}
