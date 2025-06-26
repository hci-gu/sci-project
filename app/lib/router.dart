import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/detail/activity.dart';
import 'package:scimovement/screens/detail/bladder_emptying.dart';
import 'package:scimovement/screens/detail/calories.dart';
import 'package:scimovement/screens/detail/exercise.dart';
import 'package:scimovement/screens/detail/pressure_release.dart';
import 'package:scimovement/screens/detail/sedentary.dart';
import 'package:scimovement/screens/goal/goal.dart';
import 'package:scimovement/screens/goal/goal_reached.dart';
import 'package:scimovement/screens/home/home.dart';
import 'package:scimovement/screens/introduction.dart';
import 'package:scimovement/screens/journal/edit_entry.dart';
import 'package:scimovement/screens/journal/journal.dart';
import 'package:scimovement/screens/journal/perform_pressure_release.dart';
import 'package:scimovement/screens/journal/select_journal_type.dart';
import 'package:scimovement/screens/login.dart';
import 'package:scimovement/screens/settings/settings.dart';
import 'package:scimovement/screens/tab.dart';
import 'package:scimovement/screens/onboarding/onboarding.dart';
import 'package:scimovement/screens/register.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:url_launcher/url_launcher.dart';

List<String> detailRoutes = [
  'calories',
  'activity',
  'sedentary',
  'pressure-release',
  'bladder-emptying'
];
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

  RouterNotifier(this._ref) {
    _ref.listen<bool>(onboardingDoneProvider, (_, done) => notifyListeners());

    _ref.listen<String?>(
      userProvider.select((value) => value?.id),
      (_, __) => notifyListeners(),
    );
  }

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    bool loggedIn = _ref.read(userProvider) != null;
    bool onboardingDone = _ref.read(onboardingDoneProvider);
    if (state.matchedLocation.contains('/demo')) {
      return null;
    }

    // handle logging in
    if (!loggedIn && state.matchedLocation == '/loading') {
      return null;
    } else if (loggedIn && state.matchedLocation == '/loading') {
      return landingRoute;
    }

    if (state.matchedLocation == '/watch-login') {
      return null;
    }

    if (state.matchedLocation == '/forced-login') {
      return null;
    }

    // redirect from login screen to home or onboarding after login
    if (loggedIn && _isLoginRoute(state.matchedLocation)) {
      if (onboardingDone) {
        return landingRoute;
      } else {
        return '/onboarding';
      }
    }

    // kick out user from home if not logged in
    if (!loggedIn && !_isLoginRoute(state.matchedLocation)) {
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
  final routerNotifier = RouterNotifier(ref);

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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
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
                  GoRoute(
                    name: 'pressure-release',
                    path: 'pressure-release',
                    builder: (_, __) => const PressureReleaseScreen(),
                    routes: [
                      GoRoute(
                        path: 'goal',
                        name: 'edit-goal',
                        builder: (_, state) {
                          return GoalScreen(
                            goal: (state.extra as Map?)?['goal'],
                            type: (state.extra as Map?)?['type'],
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    name: 'bladder-emptying',
                    path: 'bladder-emptying',
                    builder: (_, __) => const BladderEmptyingScreen(),
                    routes: [
                      GoRoute(
                        path: 'goal',
                        name: 'edit-goal-bladder',
                        builder: (_, state) {
                          return GoalScreen(
                            goal: (state.extra as Map?)?['goal'],
                            type: (state.extra as Map?)?['type'],
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'exercise',
                    name: 'exercise',
                    builder: (_, state) => const ExerciseScreen(),
                  ),
                  GoRoute(
                    path: 'goal-reached',
                    name: 'goal-reached',
                    builder: (_, __) => const GoalReachedScreen(),
                  ),
                ],
              )
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                name: 'journal',
                builder: (context, state) => const JournalScreen(),
                routes: [
                  GoRoute(
                    name: 'select-journal-type',
                    path: 'type',
                    builder: (_, state) => SelectJournalTypeScreen(
                      initialDate: (state.extra as Map?)?['date'],
                    ),
                    routes: [
                      GoRoute(
                        name: 'create-journal-from-type',
                        path: 'create',
                        builder: (_, state) => EditJournalEntryScreen(
                          type: (state.extra as Map?)?['type'],
                          entry: (state.extra as Map?)?['entry'],
                          initialDate: (state.extra as Map?)?['date'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    name: 'create-journal',
                    path: 'create',
                    builder: (_, state) => EditJournalEntryScreen(
                      type: (state.extra as Map?)?['type'],
                      entry: (state.extra as Map?)?['entry'],
                    ),
                  ),
                  GoRoute(
                    path: 'perform-pressure-release',
                    name: 'perform-pressure-release',
                    builder: (_, state) {
                      return PerformPressureReleaseScreen(
                        exercises: (state.extra as Map?)?['exercises'] ??
                            [
                              PressureReleaseExercise.forwards,
                              PressureReleaseExercise.rightSide,
                              PressureReleaseExercise.leftSide,
                            ],
                      );
                    },
                  )
                ],
              )
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              )
            ],
          ),
        ],
      ),
      GoRoute(
        name: 'onboarding',
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        name: 'watch-login',
        path: '/watch-login',
        builder: (context, state) {
          return RedirectScreen(
            redirectUri: state.queryParameters['redirect_uri'],
            state: state.queryParameters['state'],
          );
        },
      ),
      GoRoute(
        name: 'forced-login',
        path: '/forced-login',
        builder: (context, state) {
          return ForcedLoginScreen(
            userId: state.queryParameters['userId'],
            apiKey: state.queryParameters['apiKey'],
            date: state.queryParameters['date'],
          );
        },
      ),
    ],
    observers: [RouteChangeObserver(ref)],
    redirect: routerNotifier._redirectLogic,
    refreshListenable: routerNotifier,
    debugLogDiagnostics: true,
  );
});

class RedirectScreen extends HookConsumerWidget {
  final String? redirectUri;
  final String? state;

  const RedirectScreen({
    Key? key,
    this.redirectUri,
    this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user = ref.watch(userProvider);

    useEffect(() {
      if (user != null && redirectUri != null && state != null) {
        launchUrl(Uri.parse('$redirectUri?state=$state&userId=${user.id}'));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.goNamed('home');
        });
      }
      if (user == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackbarMessage(
              context: context,
              message: 'You need to be logged in to sync with your watch.',
              type: SnackbarType.error,
            ),
          );
          context.goNamed('introduction');
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackbarMessage(
              context: context,
              message: 'Got invalid information from the Fitbit app.',
              type: SnackbarType.error,
            ),
          );
          context.goNamed('home');
        });
      }
      return () => {};
    }, [user]);

    return const Scaffold(
      body: Center(
        child: Text('Redirecting...'),
      ),
    );
  }
}

class LoadingScreen extends HookConsumerWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<bool> waitedLongEnough = useState(false);

    useEffect(() {
      Future.delayed(const Duration(seconds: 5), () {
        if (context.mounted) {
          waitedLongEnough.value = true;
        }
      });
      return () => {};
    }, []);

    return Scaffold(
      body: waitedLongEnough.value
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: CircularProgressIndicator()),
                AppTheme.spacer4x,
                Center(
                  child: Button(
                    onPressed: () {
                      ref.read(userProvider.notifier).logout();
                      context.goNamed('introduction');
                    },
                    title: 'Abort',
                  ),
                )
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class ForcedLoginScreen extends HookConsumerWidget {
  final String? userId;
  final String? apiKey;
  final String? date;

  const ForcedLoginScreen({
    Key? key,
    this.userId,
    this.apiKey,
    this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user = ref.watch(userProvider);

    useEffect(() {
      if (userId != null && apiKey != null) {
        // Attempt forced login
        ref.read(userProvider.notifier).forcedLogin(userId!, apiKey!).then((_) {
          // Set the date if provided
          if (date != null) {
            try {
              DateTime parsedDate = DateTime.parse(date!);
              ref.read(dateProvider.notifier).state = parsedDate;
            } catch (e) {
              // If date parsing fails, ignore and use current date
              print('Failed to parse date: $date');
            }
          }

          // Redirect to home after successful login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.goNamed('home');
          });
        }).catchError((e) {
          // Show error message and redirect to introduction
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackbarMessage(
                context: context,
                message: 'Failed to login with provided credentials.',
                type: SnackbarType.error,
              ),
            );
            context.goNamed('introduction');
          });
        });
      } else {
        // Missing parameters, redirect to introduction
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackbarMessage(
              context: context,
              message: 'Missing userId or apiKey parameters.',
              type: SnackbarType.error,
            ),
          );
          context.goNamed('introduction');
        });
      }
      return () => {};
    }, [userId, apiKey, date, user]);

    return const Scaffold(
      body: Center(
        child: Text('Authenticating...'),
      ),
    );
  }
}
