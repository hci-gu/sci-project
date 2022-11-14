import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/router.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  bool onboardingDone = await Storage.getOnboardingDone();
  Credentials? credentials = await Storage.getCredentials();
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
    );
  }
}
