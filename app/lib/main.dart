import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/router.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  bool _onboardingDone = await Storage.getOnboardingDone();
  runApp(ProviderScope(
    child: App(
      onboardingDone: _onboardingDone,
    ),
  ));
}

class App extends ConsumerWidget {
  final bool onboardingDone;

  const App({
    Key? key,
    required this.onboardingDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RullaPå',
      theme: AppTheme.theme,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      debugShowCheckedModeBanner: false,
    );
  }
}
