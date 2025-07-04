import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class TabScreen extends ConsumerWidget {
  final List<String> routes;
  final StatefulNavigationShell navigationShell;

  const TabScreen({
    super.key,
    required this.navigationShell,
    this.routes = const ['/', '/journal', '/profile'],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: !ref.watch(showTimelineProvider)
            ? Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.colors.black.withValues(alpha: .1),
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
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                ),
              )
            : null,
      ),
    );
  }
}
