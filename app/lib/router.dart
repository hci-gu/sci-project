import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:onboarding_overlay/onboarding_overlay.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/detail/activity.dart';
import 'package:scimovement/screens/detail/calories.dart';
import 'package:scimovement/screens/detail/sedentary.dart';
import 'package:scimovement/screens/introduction.dart';
import 'package:scimovement/screens/login.dart';
import 'package:scimovement/screens/main.dart';

List<String> detailRoutes = ['calories', 'activity', 'sedentary'];
final GlobalKey<OnboardingState> onboardingKey = GlobalKey<OnboardingState>();

class RouteChangeObserver extends NavigatorObserver {
  final Ref _ref;

  RouteChangeObserver(this._ref);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (detailRoutes.contains(route.name)) {
      _ref.read(paginationProvider.notifier).state = const Pagination();
    }
  }
}

extension on Route<dynamic> {
  String get name => settings.name ?? '';
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  /// This implementation exploits `ref.listen()` to add a simple callback that
  /// calls `notifyListeners()` whenever there's change onto a desider provider.
  RouterNotifier(this._ref) {
    _ref.listen<User?>(
      userProvider, // In our case, we're interested in the log in / log out events.
      (_, __) => notifyListeners(), // Obviously more logic can be added here
    );
  }

  String? _redirectLogic(GoRouterState state) {
    bool loggedIn = _ref.read(userProvider) != null;

    if (loggedIn && _isLoginRoute(state.subloc)) {
      return '/';
    }
    if (!loggedIn && !_isLoginRoute(state.subloc)) {
      return '/introduction';
    }
    return null;
  }

  bool _isLoginRoute(String route) {
    return route == '/introduction' || route == '/introduction/login';
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);

  GoRoute loggedInRoute = GoRoute(
    name: 'home',
    path: '/',
    builder: (_, __) => Onboarding(
      key: onboardingKey,
      autoSizeTexts: true,
      debugBoundaries: true,
      steps: ref.watch(onboardingStepsProvider),
      child: const MainScreen(),
      onChanged: (step) {
        print('Onboarding changed $step');
      },
    ),
    routes: [
      GoRoute(
        name: 'calories',
        path: 'calories',
        builder: (_, __) => const CaloriesScreen(),
      ),
      GoRoute(
        name: 'activity',
        path: 'activity',
        builder: (_, __) => const ActivityScreen(),
      ),
      GoRoute(
        name: 'sedentary',
        path: 'sedentary',
        builder: (_, __) => const SedentaryScreen(),
      ),
    ],
  );

  return GoRouter(
    initialLocation: '/introduction',
    routes: [
      GoRoute(
        name: 'introduction',
        path: '/introduction',
        builder: (_, state) => const IntroductionScreen(),
        routes: [
          GoRoute(
            name: 'login',
            path: 'login',
            builder: (_, state) => const LoginScreen(),
          ),
        ],
      ),
      loggedInRoute,
    ],
    observers: [RouteChangeObserver(ref)],
    redirect: routerNotifier._redirectLogic,
    refreshListenable: routerNotifier,
  );
});
