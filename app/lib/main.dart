import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/router.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timeago/timeago.dart' as timeago;

void initializeTzAndLocale() {
  tz.initializeTimeZones();
  timeago.setLocaleMessages('sv', timeago.SvMessages());
  Intl.defaultLocale = 'sv_SE';
  initializeDateFormatting();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeTzAndLocale();
  bool onboardingDone = await Storage.getOnboardingDone();
  Credentials? credentials = await Storage.getCredentials();
  LicenseRegistry.addLicense(() async* {
    final license =
        await rootBundle.loadString('assets/licenses/icon_license.txt');
    yield LicenseEntryWithLineBreaks(['thenounproject'], license);
  });

  runApp(
    ProviderScope(
      overrides: [
        userProvider.overrideWithValue(
          credentials != null ? UserState(credentials) : UserState(),
        ),
      ],
      child: App(
        onboardingDone: onboardingDone,
        loggedIn: credentials != null && credentials.email.isNotEmpty,
      ),
    ),
  );
}

class App extends ConsumerWidget {
  final bool onboardingDone;
  final bool loggedIn;

  const App({
    Key? key,
    required this.onboardingDone,
    required this.loggedIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(
      routerProvider(
        RouterProps(
          onboardingDone: onboardingDone,
          loggedIn: loggedIn,
        ),
      ),
    );

    return MaterialApp.router(
      title: 'RullaPå',
      theme: AppTheme.theme,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      debugShowCheckedModeBanner: false,
      locale: const Locale('sv', 'SE'),
    );
  }
}
