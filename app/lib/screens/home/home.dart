import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/models/pagination.dart';
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
    bool hasLogFeatures =
        features.contains(AppFeature.bladderAndBowel) ||
        features.contains(AppFeature.pressureRelease);
    int page = ref.watch(homeWidgetPageProvider);
    int pageCount = 1 + (hasLogFeatures ? 1 : 0);
    int clampedPage = pageCount > 0 ? page.clamp(0, pageCount - 1) : 0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final sectionHeightScale = (textScale - 1).clamp(0, 1.5).toDouble();
    final extraHeight = (((textScale - 1).clamp(0, 1.5)) * 180).toDouble();
    final dateHeaderHeight =
        (100 + (((textScale - 1).clamp(0, 1.5)) * 40)).toDouble();
    final summaryRowHeight = 91 + (sectionHeightScale * 24);
    final painRowHeight = 110 + (sectionHeightScale * 72);

    useEffect(() {
      if (clampedPage != page) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(homeWidgetPageProvider.notifier).setPage(clampedPage);
        });
      }
      return null;
    }, [page, clampedPage]);

    bool centerAlignDate = hasLogFeatures && clampedPage == 1;
    double pageSize = 440 + extraHeight;
    double topPadding =
        clampedPage == 0
            ? 0
            : (44 + (((textScale - 1).clamp(0, 1.5)) * 20)).toDouble();
    PageController controller = useMemoized(
      () => PageController(initialPage: clampedPage),
      [clampedPage],
    );

    final pages = <Widget>[
      // SizedBox(height: pageSize, child: GeneratedImageView()),
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
                height: summaryRowHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    features.contains(AppFeature.pressureRelease)
                        ? const PressureUlcerWidget()
                        : const SizedBox.shrink(),
                    if (features.contains(AppFeature.bladderAndBowel) &&
                        features.contains(AppFeature.pressureRelease))
                      AppTheme.spacer,
                    features.contains(AppFeature.bladderAndBowel)
                        ? const UTIWidget()
                        : const Expanded(child: SizedBox.shrink()),
                    if (features.contains(AppFeature.bladderAndBowel) &&
                        !features.contains(AppFeature.pressureRelease))
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
                height: painRowHeight,
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: const [NeuroPathicPainWidgets()],
                ),
              ),
            ],
          ),
        ),
      const WatchFeaturesWidget(),
    ];

    return Column(
      children: [
        SizedBox(
          height: pageSize,
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
                  height: dateHeaderHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.basePadding * 2,
                    ),
                    child: SelectedDateText(centerAlign: centerAlignDate),
                  ),
                ),
              ),
              Positioned(
                top: topPadding,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.decelerate,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: pageSize - topPadding,
                    child: PageView(
                      controller: controller,
                      onPageChanged: (value) {
                        ref
                            .read(homeWidgetPageProvider.notifier)
                            .setPage(value);
                      },
                      scrollDirection: Axis.horizontal,
                      children: pages,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasLogFeatures) ...[
          AppTheme.spacer2x,
          StepIndicator(index: clampedPage, count: pageCount),
        ],
      ],
    );
  }
}

class WatchFeaturesWidget extends HookConsumerWidget {
  const WatchFeaturesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ConnectedWatch? watch = ref.watch(connectedWatchProvider);

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
      return activity;
    }

    DateTime? lastSync = ref.watch(lastSyncProvider);
    // if lastsync was less than 15 minutes ago, we don't show the sync data
    if (lastSync != null &&
        DateTime.now().difference(lastSync).inMinutes <= 10) {
      return activity;
    }

    return FutureBuilder(
      future: sendBleCommand({
        'cmd': 'get_state',
      }).then((m) => m['data'] as Map),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Stack(
            children: [
              Blur(blur: 6, colorOpacity: 0.5, child: activity),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }

        return activity;
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
