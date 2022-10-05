import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/demo/demo.dart';
import 'package:scimovement/screens/detail/activity.dart';
import 'package:scimovement/screens/detail/calories.dart';
import 'package:scimovement/screens/detail/sedentary.dart';
import 'package:scimovement/screens/introduction.dart';
import 'package:scimovement/screens/login.dart';
import 'package:scimovement/screens/main.dart';
import 'package:scimovement/screens/onboarding/onboarding.dart';
import 'package:scimovement/screens/register.dart';

List<String> detailRoutes = ['calories', 'activity', 'sedentary'];

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
  bool _onboardingDone = false;

  RouterNotifier(this._ref, this._onboardingDone) {
    _ref.listen<bool>(onboardingDoneProvider, (_, done) {
      _onboardingDone = done;
      notifyListeners();
    });

    _ref.listen<User?>(
      userProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? _redirectLogic(GoRouterState state) {
    bool loggedIn = _ref.read(userProvider) != null;
    if (state.subloc.contains('/demo')) {
      return null;
    }

    // handle logging in
    if (!loggedIn && state.subloc == '/loading') {
      return null;
    } else if (loggedIn && state.subloc == '/loading') {
      return '/';
    }

    // redirect form onboarding to home when done
    if (state.subloc == '/onboarding' && _onboardingDone) {
      return '/';
    }

    // redirect from login screen to home or onboarding after login
    if (loggedIn && _isLoginRoute(state.subloc)) {
      if (_onboardingDone) {
        return '/';
      } else {
        return '/onboarding';
      }
    }

    // kick out user from home if not logged in
    if (!loggedIn && !_isLoginRoute(state.subloc)) {
      return '/introduction';
    }
    return null;
  }

  bool _isLoginRoute(String route) {
    return route == '/introduction' ||
        route == '/introduction/login' ||
        route == '/introduction/register';
  }
}

class RouterProps {
  final bool loggedIn;
  final bool onboardingDone;

  RouterProps({this.loggedIn = false, this.onboardingDone = false});
}

final routerProvider = Provider.family<GoRouter, RouterProps>((ref, props) {
  final routerNotifier = RouterNotifier(ref, props.onboardingDone);

  return GoRouter(
    initialLocation: props.loggedIn ? '/loading' : '/introduction',
    routes: [
      GoRoute(
        name: 'loading',
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),
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
          GoRoute(
            name: 'register',
            path: 'register',
            builder: (_, state) => const RegisterScreen(),
          ),
        ],
      ),
      GoRoute(
        name: 'home',
        path: '/',
        builder: (_, __) => const MainScreen(),
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
      ),
      GoRoute(
        name: 'onboarding',
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        name: 'demo',
        path: '/demo',
        builder: (context, state) => const DemoWrapper(
          child: MainScreen(),
        ),
        routes: [
          GoRoute(
            name: 'demo-calories',
            path: 'calories',
            builder: (_, __) => const DemoWrapper(
              child: CaloriesScreen(),
            ),
          ),
          GoRoute(
            name: 'demo-activity',
            path: 'activity',
            builder: (_, __) => const DemoWrapper(
              child: ActivityScreen(),
            ),
          ),
          GoRoute(
            name: 'demo-sedentary',
            path: 'sedentary',
            builder: (_, __) => const DemoWrapper(
              child: SedentaryScreen(),
            ),
          ),
        ],
      ),
    ],
    observers: [RouteChangeObserver(ref)],
    redirect: routerNotifier._redirectLogic,
    refreshListenable: routerNotifier,
  );
});

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
