import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/screens/activity.dart';
import 'package:scimovement/screens/calories.dart';
import 'package:scimovement/screens/login.dart';
import 'package:scimovement/screens/main.dart';

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
    final user = _ref.read(userProvider);

    // From here we can use the state and implement our custom logic
    final areWeLoggingIn = state.location == '/login';

    if (user == null) {
      // We're not logged in
      // So, IF we aren't in the login page, go there.
      return areWeLoggingIn ? null : '/login';
    }
    // We're logged in

    // At this point, IF we're in the login page, go to the home page
    if (areWeLoggingIn) return '/';

    // There's no need for a redirect at this point.
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    routes: [
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
        ],
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (_, state) => const LoginScreen(),
      ),
    ],
    redirect: routerNotifier._redirectLogic,
    refreshListenable: routerNotifier,
  );
});
