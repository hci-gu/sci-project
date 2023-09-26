import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TabScreen extends StatelessWidget {
  final List<String> routes;
  final StatefulNavigationShell navigationShell;

  const TabScreen(
      {Key? key,
      required this.navigationShell,
      this.routes = const ['/', '/journal', '/profile']})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) => AnnotatedRegion(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: navigationShell,
          bottomNavigationBar: orientation == Orientation.portrait
              ? Container(
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
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.home_outlined),
                        label: AppLocalizations.of(context)!.home,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.menu_book_sharp),
                        label: AppLocalizations.of(context)!.logbook,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.person_outline),
                        label: AppLocalizations.of(context)!.profile,
                      ),
                    ],
                    currentIndex: navigationShell.currentIndex,
                    selectedItemColor: AppTheme.colors.primary,
                    onTap: (index) {
                      if (index == 1) {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                          DeviceOrientation.portraitDown,
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                      } else {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                          DeviceOrientation.portraitDown,
                        ]);
                      }

                      navigationShell.goBranch(index,
                          initialLocation:
                              index == navigationShell.currentIndex);
                      // GoRouter.of(context).go(routes[index]);
                    },
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
