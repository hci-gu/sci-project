import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/exercise_widget.dart';
import 'package:scimovement/screens/home/widgets/pressure_release_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/date_select.dart';

class HomeScreen extends HookConsumerWidget {
  HomeScreen({Key? key}) : super(key: key);
  final RefreshController _refreshController = RefreshController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // bool showDataWidgets = ref.watch(userHasDataProvider);
    List<AppFeature> features = ref.watch(appFeaturesProvider);

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () async {
        ref.read(dateProvider.notifier).state = DateTime.now();
        _refreshController.refreshCompleted();
      },
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.basePadding * 2,
        ),
        children: [
          const DateSelect(),
          AppTheme.spacer2x,
          StaggeredGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.basePadding * 2,
            mainAxisSpacing: AppTheme.basePadding * 2,
            children: [
              if (features.contains(AppFeature.watch))
                const StaggeredGridTile.count(
                  crossAxisCellCount: 2,
                  mainAxisCellCount: 1,
                  child: ActivityWheel(),
                ),
              if (features.contains(AppFeature.watch)) const EnergyWidget(),
              if (features.contains(AppFeature.watch)) const SedentaryWidget(),
              if (features.contains(AppFeature.exercise))
                const ExerciseWidget(),
              if (features.contains(AppFeature.pressureRelease))
                const PressureReleaseWidget(),
            ],
          ),
          // if (showDataWidgets)
          //   Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       const Expanded(child: EnergyWidget()),
          //       AppTheme.spacer2x,
          //       const Expanded(child: SedentaryWidget()),
          //     ],
          //   ),
          // if (!showDataWidgets) const NoDataMessage(),
          // AppTheme.spacer2x,
          // if (showDataWidgets)
          //   Row(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       const Expanded(child: ExerciseWidget()),
          //       AppTheme.spacer2x,
          //       if (features.contains(AppFeature.pressureRelease))
          //         const Expanded(child: PressureReleaseWidget()),
          //       // const Expanded(child: SedentaryWidget()),
          //     ],
          //   ),
        ],
      ),
    );
  }
}
