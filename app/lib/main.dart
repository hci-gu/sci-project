import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/router.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  bool _onboardingDone = await Storage.getOnboardingDone();
  String? _userId = await Storage.getUserId();
  runApp(ProviderScope(
    overrides: [
      userProvider.overrideWithValue(
        _userId != null ? UserState(_userId) : UserState(),
      ),
    ],
    child: App(
      onboardingDone: _onboardingDone,
      userId: _userId,
    ),
  ));
}

class App extends ConsumerWidget {
  final bool onboardingDone;
  final String? userId;

  const App({
    Key? key,
    required this.onboardingDone,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider(RouterProps(
      onboardingDone: onboardingDone,
      userId: userId,
    )));

    return MaterialApp.router(
      title: 'RullaPå',
      theme: AppTheme.theme,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      debugShowCheckedModeBanner: false,
    );
  }
}
