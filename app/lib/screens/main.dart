import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scimovement/screens/home/home.dart';
import 'package:scimovement/screens/settings/settings.dart';
import 'package:scimovement/theme/theme.dart';

class MainScreen extends HookWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ValueNotifier<int> screen = useState(0);

    return Scaffold(
      body: SafeArea(
        child: _page(screen.value),
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
              icon: Icon(Icons.settings_outlined),
              label: 'Inställningar',
            ),
          ],
          currentIndex: screen.value,
          selectedItemColor: AppTheme.colors.primary,
          onTap: (index) {
            screen.value = index;
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
        return const SettingsScreen();
    }
  }
}
