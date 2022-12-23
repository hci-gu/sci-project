import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/demo/demo.dart';
import 'package:scimovement/screens/detail/activity.dart';
import 'package:scimovement/screens/detail/calories.dart';
import 'package:scimovement/screens/detail/sedentary.dart';
import 'package:scimovement/screens/introduction.dart';
import 'package:scimovement/screens/journal/edit_entry.dart';
import 'package:scimovement/screens/journal/journal_list.dart';
import 'package:scimovement/screens/login.dart';
import 'package:scimovement/screens/tab.dart';
import 'package:scimovement/screens/onboarding/onboarding.dart';
import 'package:scimovement/screens/register.dart';

List<String> detailRoutes = ['calories', 'activity', 'sedentary'];
String landingRoute = '/';

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

    _ref.listen<String?>(
      userProvider.select((value) => value?.id),
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
      return landingRoute;
    }

    // redirect form onboarding to home when done
    if (state.subloc == '/onboarding' && _onboardingDone) {
      return landingRoute;
    }

    // redirect from login screen to home or onboarding after login
    if (loggedIn && _isLoginRoute(state.subloc)) {
      if (_onboardingDone) {
        return landingRoute;
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

final profileKey = UniqueKey();
final journalKey = UniqueKey();

final routerProvider = Provider.family<GoRouter, RouterProps>((ref, props) {
  final routerNotifier = RouterNotifier(ref, props.onboardingDone);

  return GoRouter(
    initialLocation: props.loggedIn ? '/loading' : '/introduction',
    routes: [
      GoRoute(
        name: 'loading',
        path: '/loading',
        builder: (_, __) => const LoadingScreen(),
      ),
      GoRoute(
        name: 'introduction',
        path: '/introduction',
        builder: (_, __) => const IntroductionScreen(),
        routes: [
          GoRoute(
            name: 'login',
            path: 'login',
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            name: 'register',
            path: 'register',
            builder: (_, __) => const RegisterScreen(),
          ),
        ],
      ),
      GoRoute(
        name: 'home',
        path: '/',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TabScreen(),
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
      ),
      GoRoute(
        name: 'profile',
        path: '/profile',
        pageBuilder: (context, _) => NoTransitionPage(
          key: profileKey,
          child: const TabScreen(),
        ),
      ),
      GoRoute(
        name: 'journal',
        path: '/journal',
        pageBuilder: (context, _) => NoTransitionPage(
          key: journalKey,
          child: const TabScreen(),
        ),
        routes: [
          GoRoute(
            name: 'create-journal',
            path: 'create',
            builder: (_, state) => EditJournalEntryScreen(
              bodyPart: (state.extra as Map?)?['bodyPart'],
            ),
          ),
          GoRoute(
              name: 'journal-list',
              path: 'list',
              builder: (_, state) => const JournalListScreen(),
              routes: [
                GoRoute(
                  name: 'update-journal',
                  path: ':id',
                  builder: (_, state) => EditJournalEntryScreen(
                    entry: (state.extra as Map?)?['entry'],
                  ),
                ),
              ]),
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
          child: TabScreen(
            routes: [
              '/demo',
              '/demo/journal',
              '/demo/profile',
            ],
          ),
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
      GoRoute(
        name: 'demo-profile',
        path: '/demo/profile',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TabScreen(
            routes: [
              '/demo',
              '/demo/journal',
              '/demo/profile',
            ],
          ),
        ),
      ),
      GoRoute(
        name: 'demo-journal',
        path: '/demo/journal',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TabScreen(
            routes: [
              '/demo',
              '/demo/journal',
              '/demo/profile',
            ],
          ),
        ),
        routes: [],
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
