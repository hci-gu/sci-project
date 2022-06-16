import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:push/push.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/settings.dart';
import 'package:scimovement/screens/home.dart';
import 'package:scimovement/screens/login.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final auth = AuthModel();
  await auth.init();
  runApp(App(auth: auth));
}

class App extends StatelessWidget {
  final AuthModel auth;

  App({Key? key, required this.auth}) : super(key: key);

  final ActivityModel activity = ActivityModel();
  final EnergyModel energy = EnergyModel();
  final SettingsModel settings = SettingsModel();

  @override
  Widget build(BuildContext context) {
    // useEffect(() {
    //   Push.instance.requestPermission(
    //     sound: true,
    //     alert: true,
    //     badge: true,
    //   );
    //   Push.instance.onNewToken.listen((token) {
    //     print("Just got a new FCM registration token: ${token}");
    //   });

    //   Push.instance.onMessage.listen((message) {
    //     print('RemoteMessage received while app is in foreground:\n'
    //         'RemoteMessage.Notification: ${message.notification} \n'
    //         ' title: ${message.notification?.title.toString()}\n'
    //         ' body: ${message.notification?.body.toString()}\n'
    //         'RemoteMessage.Data: ${message.data}');
    //   });

    //   // Handle push notifications
    //   Push.instance.onBackgroundMessage.listen((message) {
    //     print('RemoteMessage received while app is in background:\n'
    //         'RemoteMessage.Notification: ${message.notification} \n'
    //         ' title: ${message.notification?.title.toString()}\n'
    //         ' body: ${message.notification?.body.toString()}\n'
    //         'RemoteMessage.Data: ${message.data}');
    //   });
    // }, []);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthModel>.value(value: auth),
        ChangeNotifierProvider<ActivityModel>.value(value: activity),
        ChangeNotifierProvider<EnergyModel>.value(value: energy),
        ChangeNotifierProvider<SettingsModel>.value(value: settings),
      ],
      child: MaterialApp.router(
        title: 'SCI-Movement',
        theme: AppTheme.theme,
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  late final _router = GoRouter(
    initialLocation: auth.loggedIn ? '/' : '/login',
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (_, __) => const MainScreen(),
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (_, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'auto-login',
        path: '/auto-login/:userId',
        builder: (_, state) {
          String? userId = state.params['userId'];
          if (userId != null) {
            return FutureBuilder(
              future: auth.login(userId),
              builder: (context, snapshot) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            );
          }
          return const LoginScreen();
        },
      ),
    ],
    redirect: (state) {
      if (!auth.loggedIn && state.location == '/') {
        return '/login';
      }
      return null;
    },
    refreshListenable: IsLoggedInNotifier(auth),
  );
}
