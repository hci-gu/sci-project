import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:push/push.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/foreground_service/foreground_service.dart';
import 'package:scimovement/models/locale.dart';
import 'package:scimovement/router.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:collection/collection.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:scimovement/gen_l10n/app_localizations.dart';

class App extends HookConsumerWidget {
  final bool onboardingDone;
  final bool loggedIn;

  const App({super.key, required this.onboardingDone, required this.loggedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      _startForeGroundService();
      if (!kIsWeb && Platform.isIOS) {
        Future<void> syncIfNeeded() async {
          await ref
              .read(connectedWatchProvider.notifier)
              .syncIfNeeded(minInterval: const Duration(minutes: 12));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          syncIfNeeded();
        });

        final observer = _AppLifecycleObserver(onResumed: syncIfNeeded);
        WidgetsBinding.instance.addObserver(observer);
        return () {
          WidgetsBinding.instance.removeObserver(observer);
        };
      }

      return () {};
    }, []);

    final router = ref.watch(
      routerProvider(
        RouterProps(onboardingDone: onboardingDone, loggedIn: loggedIn),
      ),
    );

    return NotificationLauncherWrapper(
      router: router,
      child: MaterialApp.router(
        title: 'Wheelability',
        theme: AppTheme.theme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (Locale? locale, _) {
          Locale resolvedLocale =
              AppLocalizations.supportedLocales.firstWhereOrNull(
                (Locale supportedLocale) =>
                    supportedLocale.languageCode == locale?.languageCode,
              ) ??
              const Locale('en');
          timeago.setDefaultLocale(resolvedLocale.languageCode);
          return resolvedLocale;
        },
        locale: ref.watch(localeProvider),
        builder: (_, child) {
          return WatchSyncFeedbackListener(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  void _startForeGroundService() async {
    // On iOS, BleOwner is initialized directly in main.dart
    // Skip foreground service which is Android-only
    if (kIsWeb || Platform.isIOS) return;

    try {
      await ForegroundService.instance.ensureStarted();
    } catch (e) {
      print("Error starting foreground service: $e");
    }
  }
}

class WatchSyncFeedbackListener extends HookConsumerWidget {
  final Widget child;

  const WatchSyncFeedbackListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastShownNoticeId = useRef<int?>(null);
    final notice = ref.watch(watchSyncNoticeProvider);

    void showNotice(WatchSyncNotice next) {
      if (!context.mounted || lastShownNoticeId.value == next.id) {
        return;
      }
      lastShownNoticeId.value = next.id;

      final l10n = AppLocalizations.of(context)!;
      final String message;
      switch (next.error) {
        case kBluetoothOffError:
          message = l10n.bluetoothOffRetry;
          break;
        case kWatchNotFoundError:
          message = l10n.watchNotFoundReconnect;
          break;
        case kWatchNotConfiguredError:
          message = l10n.watchNotConfigured;
          break;
        case kConnectionFailedError:
          message = l10n.watchConnectFailed;
          break;
        case kWatchSyncLoginRequired:
          message = l10n.watchSyncLoginRequired;
          break;
        case kPinetimeConnectTimeout:
          message = l10n.pinetimeConnectTimeout;
          break;
        case kPinetimeReadTimeout:
          message = l10n.pinetimeReadTimeout;
          break;
        case kPinetimeBleError:
          message = l10n.pinetimeBleError;
          break;
        case kPinetimeCharacteristicMissing:
          message = l10n.pinetimeCharacteristicMissing;
          break;
        default:
          message = l10n.syncFailed(next.error);
          break;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      });
    }

    ref.listen<WatchSyncNotice?>(watchSyncNoticeProvider, (previous, next) {
      if (next != null) {
        showNotice(next);
      }
    });

    useEffect(() {
      if (notice != null) {
        showNotice(notice);
      }
      return null;
    }, [notice?.id]);

    return child;
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final Future<void> Function() onResumed;

  _AppLifecycleObserver({required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
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

      final onNotificationTap = Push.instance.addOnNotificationTap((data) {
        handleLaunchFromNotification(data);
      });

      final onBackgroundMessageSubscription = Push.instance
          .addOnBackgroundMessage((message) {
            handleLaunchFromNotification(message);
          });

      final onMessageSubscription = Push.instance.addOnMessage((message) {
        handleLaunchFromNotification(message);
      });

      Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
        if (data != null) {
          handleLaunchFromNotification(data);
        }
      });

      return () {
        onNotificationTap();
        onBackgroundMessageSubscription();
        onMessageSubscription();
      };
    }, []);

    return child;
  }

  void handleRoute(String route) {
    String routeName = route.split('?').first;
    Map<String, String> query = Uri.splitQueryString(route.split('?').last);

    if (routeName == 'create-journal') {
      Map<String, dynamic> extra = {};
      if (query['type'] != null) {
        extra = {'type': journalTypeFromString(query['type']!)};
      }
      router.goNamed('create-journal-from-type', extra: extra);
    }
  }

  void handleLaunchFromNotification(dynamic data) {
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
