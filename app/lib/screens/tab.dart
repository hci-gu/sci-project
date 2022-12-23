import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/screens/home/home.dart';
import 'package:scimovement/screens/journal/journal.dart';
import 'package:scimovement/screens/settings/settings.dart';
import 'package:scimovement/theme/theme.dart';

class TabScreen extends StatelessWidget {
  final List<String> routes;

  const TabScreen({Key? key, this.routes = const ['/', '/journal', '/profile']})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int index = routes.contains(GoRouter.of(context).location)
        ? routes.indexOf(GoRouter.of(context).location)
        : 0;

    return Scaffold(
      body: SafeArea(
        child: _page(index),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.colors.black.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: AppTheme.colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Hem',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_sharp),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
          currentIndex: index,
          selectedItemColor: AppTheme.colors.primary,
          onTap: (index) {
            GoRouter.of(context).go(routes[index]);
          },
        ),
      ),
    );
  }

  _page(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return const JournalScreen();
      case 2:
        return const SettingsScreen();
      default:
        return HomeScreen();
    }
  }
}
