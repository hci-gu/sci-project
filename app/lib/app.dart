import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:push/push.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/locale.dart';
import 'package:scimovement/router.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:collection/collection.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:scimovement/gen_l10n/app_localizations.dart';

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

    return NotificationLauncherWrapper(
      router: router,
      child: MaterialApp.router(
        title: 'RullaPå',
        theme: AppTheme.theme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (Locale? locale, _) {
          Locale resolvedLocale = AppLocalizations.supportedLocales
                  .firstWhereOrNull((Locale supportedLocale) =>
                      supportedLocale.languageCode == locale?.languageCode) ??
              const Locale('en');
          timeago.setDefaultLocale(resolvedLocale.languageCode);
          return resolvedLocale;
        },
        locale: ref.watch(localeProvider),
        builder: (_, child) {
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

class NotificationLauncherWrapper extends HookWidget {
  final GoRouter router;
  final Widget child;

  const NotificationLauncherWrapper({
    super.key,
    required this.router,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      if (kIsWeb) return () => {};

      final onNotificationTap = Push.instance.onNotificationTap.listen((data) {
        handleLaunchFromNotification(data);
      });

      final onBackgroundMessageSubscription =
          Push.instance.onBackgroundMessage.listen((message) {
        handleLaunchFromNotification(message);
      });

      final onMessageSubscription = Push.instance.onMessage.listen((message) {
        handleLaunchFromNotification(message);
      });

      Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
        if (data != null) {
          handleLaunchFromNotification(data);
        }
      });

      return () {
        onNotificationTap.cancel();
        onBackgroundMessageSubscription.cancel();
        onMessageSubscription.cancel();
      };
    }, []);

    return child;
  }

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
      router.goNamed('create-journal-from-type', extra: extra);
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
}
