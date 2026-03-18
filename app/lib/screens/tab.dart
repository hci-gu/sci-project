import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/models/watch/watch.dart';
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
    final isSyncing = ref.watch(watchSyncInProgressProvider);
    final syncProgress = ref.watch(watchSyncProgressProvider);
    final showBottomBar = !ref.watch(showTimelineProvider);
    final showSyncOverlay =
        showBottomBar && isSyncing && navigationShell.currentIndex != 2;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            navigationShell,
            if (showSyncOverlay) _WatchSyncIndicator(progress: syncProgress),
          ],
        ),
        bottomNavigationBar:
            showBottomBar
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

class _WatchSyncIndicator extends StatelessWidget {
  final WatchSyncProgress progress;

  const _WatchSyncIndicator({required this.progress});

  String _phaseText(BuildContext context) {
    switch (progress.phase) {
      case 'connecting':
        return AppLocalizations.of(context)!.syncPhaseConnecting;
      case 'reading':
        return AppLocalizations.of(
          context,
        )!.syncPhaseReading(progress.current, progress.total);
      case 'uploading':
        return AppLocalizations.of(context)!.syncPhaseUploading;
      case 'processing':
        return AppLocalizations.of(context)!.syncPhaseProcessing;
      case 'clearing':
        return AppLocalizations.of(context)!.syncPhaseClearing;
      case 'done':
        return AppLocalizations.of(context)!.syncPhaseDone;
      default:
        return AppLocalizations.of(context)!.syncing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showProgressBar =
        progress.phase == 'reading' && progress.total > 0;

    return Positioned(
      left: 12,
      right: 12,
      bottom: kBottomNavigationBarHeight + 4,
      child: IgnorePointer(
        ignoring: true,
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.colors.black.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.colors.white.withValues(alpha: .08),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.colors.black.withValues(alpha: .12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _phaseText(context),
                        style: AppTheme.paragraphSmall.copyWith(
                          color: AppTheme.colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (showProgressBar) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      minHeight: 5,
                      backgroundColor: AppTheme.colors.white.withValues(
                        alpha: .2,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
