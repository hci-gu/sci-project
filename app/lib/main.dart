import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:push/push.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/locale.dart';
import 'package:scimovement/router.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:collection/collection.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

    handleRoute(String route) {
      String routeName = route.split('?').first;
      Map<String, String> query = Uri.splitQueryString(route.split('?').last);

      if (routeName == 'create-journal') {
        Map<String, dynamic> extra = {};
        if (query['type'] != null) {
          extra = {
            'type': journalTypeFromString(query['type']!),
          };
        }
        router.goNamed(routeName, extra: extra);
      }
    }

    handleLaunchFromNotification(data) {
      Map<Object?, Object?>? aps = data?['aps'] as Map<Object?, Object?>?;

      if (aps != null) {
        Map<Object?, Object?>? alert = aps['alert'] as Map<Object?, Object?>?;
        if (alert != null) {
          String? action = alert['action'] as String?;
          if (action != null) {
            handleRoute(action);
          }
        }
      }
    }

    // if (!kIsWeb) {
    //   // Handle notification taps
    //   Push.instance.onNotificationTap.listen((data) {
    //     handleLaunchFromNotification(data);
    //   });

    //   Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
    //     if (data != null) {
    //       handleLaunchFromNotification(data);
    //     }
    //   });
    // }

    return MaterialApp.router(
      title: 'RullaPå',
      theme: AppTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (Locale? locale, _) {
        Locale? resolvedLocale = AppLocalizations.supportedLocales
            .firstWhereOrNull((Locale supportedLocale) =>
                supportedLocale.languageCode == locale?.languageCode);
        return resolvedLocale ?? const Locale('en');
      },
      locale: ref.watch(localeProvider),
      builder: (_, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
