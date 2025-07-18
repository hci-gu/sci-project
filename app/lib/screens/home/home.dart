import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:polar/polar.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/screens/home/widgets/bladder_emptying_widget.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/exercise_widget.dart';
import 'package:scimovement/screens/home/widgets/neuropathic_pain_widgets.dart';
import 'package:scimovement/screens/home/widgets/pressure_release_widget.dart';
import 'package:scimovement/screens/home/widgets/pressure_ulcer_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/screens/home/widgets/uti_widget.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_stepper.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/date_select.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/watch/connect_watch.dart';
import 'package:scimovement/widgets/watch/sync_watch_data.dart';

class HomeWidgetPageNotifier extends Notifier<int> {
  @override
  int build() {
    listenSelf((previous, next) {
      Storage().storeHomeWidgetPage(next);
    });

    return Storage().getHomeWidgetPage();
  }

  void setPage(int value) {
    state = value;
  }
}

final homeWidgetPageProvider = NotifierProvider<HomeWidgetPageNotifier, int>(
  HomeWidgetPageNotifier.new,
);

class PagedWidgets extends HookConsumerWidget {
  const PagedWidgets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<AppFeature> features = ref.watch(appFeaturesProvider);
    bool hasWatchFeatures = features.contains(AppFeature.watch);
    bool hasLogFeatures =
        features.contains(AppFeature.bladderAndBowel) ||
        features.contains(AppFeature.pressureRelease);
    int page = ref.watch(homeWidgetPageProvider);
    bool centerAlignDate = page == 0 && hasLogFeatures;
    PageController controller = useMemoized(
      () => PageController(initialPage: page),
      [page],
    );

    return Column(
      children: [
        SizedBox(
          height: 440,
          child: Stack(
            children: [
              Positioned(
                right: AppTheme.basePadding * 2,
                top: AppTheme.basePadding * 2,
                child: const DateSelectButton(),
              ),
              AnimatedPositioned(
                top: centerAlignDate ? 90 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.decelerate,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 100,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.basePadding * 2,
                    ),
                    child: SelectedDateText(centerAlign: centerAlignDate),
                  ),
                ),
              ),
              Positioned(
                top: 80,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 360,
                  child: PageView(
                    controller: controller,
                    onPageChanged: (value) {
                      ref.read(homeWidgetPageProvider.notifier).setPage(value);
                    },
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (hasLogFeatures)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 120,
                            left: AppTheme.basePadding * 2,
                            right: AppTheme.basePadding * 2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 91,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    features.contains(
                                          AppFeature.pressureRelease,
                                        )
                                        ? const PressureUlcerWidget()
                                        : const SizedBox.shrink(),
                                    if (features.contains(
                                          AppFeature.bladderAndBowel,
                                        ) &&
                                        features.contains(
                                          AppFeature.pressureRelease,
                                        ))
                                      AppTheme.spacer,
                                    features.contains(
                                          AppFeature.bladderAndBowel,
                                        )
                                        ? const UTIWidget()
                                        : const Expanded(
                                          child: SizedBox.shrink(),
                                        ),
                                    if (features.contains(
                                          AppFeature.bladderAndBowel,
                                        ) &&
                                        !features.contains(
                                          AppFeature.pressureRelease,
                                        ))
                                      const Expanded(child: SizedBox.shrink()),
                                  ],
                                ),
                              ),
                              AppTheme.spacer,
                              Text(
                                AppLocalizations.of(context)!.painAndDiscomfort,
                                style: AppTheme.labelLarge,
                              ),
                              AppTheme.spacer,
                              SizedBox(
                                height: 110,
                                child: ListView(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  children: const [NeuroPathicPainWidgets()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      WatchFeaturesWidget(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasWatchFeatures && hasLogFeatures) AppTheme.spacer2x,
        if (hasWatchFeatures && hasLogFeatures)
          StepIndicator(index: page, count: 2),
      ],
    );
  }
}

class WatchFeaturesWidget extends HookConsumerWidget {
  const WatchFeaturesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<AppFeature> features = ref.watch(appFeaturesProvider);
    ConnectedWatch? watch = ref.watch(connectedWatchProvider);

    if (!features.contains(AppFeature.watch)) {
      return const SizedBox.shrink();
    }

    Widget activity = Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.basePadding * 2),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: StaggeredGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.basePadding * 2,
            mainAxisSpacing: AppTheme.basePadding * 2,
            children: const [
              StaggeredGridTile.count(
                crossAxisCellCount: 1,
                mainAxisCellCount: 2,
                child: ActivityWheel(),
              ),
              EnergyWidget(),
              SedentaryWidget(),
            ],
          ),
        ),
      ),
    );

    if (watch == null) {
      return Stack(
        children: [
          Blur(blur: 6, colorOpacity: 0.5, child: activity),
          ConnectWatch(),
        ],
      );
    }

    DateTime? lastSync = ref.watch(lastSyncProvider);
    // if lastsync was less than 15 minutes ago, we don't show the sync data
    if (lastSync != null &&
        DateTime.now().difference(lastSync).inMinutes <= 10) {
      return activity;
    }

    return FutureBuilder(
      future: PolarService.instance.getState(),
      builder: (context, AsyncSnapshot<PolarState> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Stack(
            children: [
              Blur(blur: 6, colorOpacity: 0.5, child: activity),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }

        return Stack(
          children: [
            Blur(blur: 6, colorOpacity: 0.5, child: activity),
            RebuildOnTimer(
              duration: const Duration(seconds: 30),
              child: const SyncWatchData(),
            ),
          ],
        );
      },
    );
  }
}

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<AppFeature> features = ref.watch(appFeaturesProvider);

    return RefreshIndicator(
      color: AppTheme.primarySwatch,
      onRefresh: () async {
        ref.read(dateProvider.notifier).state = DateTime.now();
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          const PagedWidgets(),
          AppTheme.spacer2x,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.basePadding * 2),
            child: StaggeredGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.basePadding * 2,
              mainAxisSpacing: AppTheme.basePadding * 2,
              children: [
                if (features.contains(AppFeature.pressureRelease))
                  const PressureReleaseWidget(),
                if (features.contains(AppFeature.bladderAndBowel))
                  const BladderEmptyingWidget(),
                if (features.contains(AppFeature.exercise))
                  const ExerciseWidget(),
              ],
            ),
          ),
          AppTheme.spacer2x,
        ],
      ),
    );
  }
}
