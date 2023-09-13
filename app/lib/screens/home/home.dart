import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/exercise_widget.dart';
import 'package:scimovement/screens/home/widgets/pressure_release_widget.dart';
import 'package:scimovement/screens/home/widgets/pressure_ulcer_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/screens/home/widgets/uti_widget.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_stepper.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/date_select.dart';

final homeWidgetPageProvider = StateProvider<int>((ref) {
  ref.listenSelf((previous, next) {
    Storage().storeHomeWidgetPage(next);
  });

  return Storage().getHomeWidgetPage();
});

class PagedWidgets extends HookConsumerWidget {
  final bool hasWatchFeatures;

  const PagedWidgets({
    super.key,
    this.hasWatchFeatures = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int page = ref.watch(homeWidgetPageProvider);
    PageController controller =
        useMemoized(() => PageController(initialPage: page), [page]);

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
                top: page == 0 ? 90 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.decelerate,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 100,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.basePadding * 2,
                    ),
                    child: SelectedDateText(
                      centerAlign: page == 0,
                    ),
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
                      ref.read(homeWidgetPageProvider.notifier).state = value;
                    },
                    scrollDirection: Axis.horizontal,
                    children: [
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
                              height: 90,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const PressureUlcerWidget(),
                                  AppTheme.spacer,
                                  const UTIWidget(),
                                ],
                              ),
                            ),
                            AppTheme.spacer,
                            Text('Utrustning & Medicin',
                                style: AppTheme.labelLarge),
                          ],
                        ),
                      ),
                      if (hasWatchFeatures)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.basePadding * 2,
                          ),
                          child: Center(
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasWatchFeatures) AppTheme.spacer2x,
        if (hasWatchFeatures)
          StepIndicator(
            index: page,
            count: 2,
          )
      ],
    );
  }
}

class HomeScreen extends HookConsumerWidget {
  HomeScreen({Key? key}) : super(key: key);
  final RefreshController _refreshController = RefreshController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<AppFeature> features = ref.watch(appFeaturesProvider);

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () async {
        ref.read(dateProvider.notifier).state = DateTime.now();
        _refreshController.refreshCompleted();
      },
      child: ListView(
        children: [
          PagedWidgets(
            hasWatchFeatures: features.contains(AppFeature.watch),
          ),
          AppTheme.spacer2x,
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.basePadding * 2,
            ),
            child: StaggeredGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.basePadding * 2,
              mainAxisSpacing: AppTheme.basePadding * 2,
              children: [
                if (features.contains(AppFeature.exercise))
                  const ExerciseWidget(),
                if (features.contains(AppFeature.pressureRelease))
                  const PressureReleaseWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
