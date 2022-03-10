import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/screens/home.dart';
import 'package:scimovement/screens/login.dart';
import 'package:scimovement/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthModel();
  await auth.init();
  runApp(App(auth: auth));
}

class App extends StatelessWidget {
  final AuthModel auth;

  App({Key? key, required this.auth}) : super(key: key);

  final ActivityModel activity = ActivityModel();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthModel>.value(value: auth),
        ChangeNotifierProvider<ActivityModel>.value(value: activity),
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
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
    ],
    redirect: (state) {
      if (!auth.loggedIn && state.location != '/login') {
        return '/login';
      }
      return null;
    },
    refreshListenable: auth,
  );
}
