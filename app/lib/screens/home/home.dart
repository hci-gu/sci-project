import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scimovement/models/location.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/date_select.dart';

class HomeScreen extends HookConsumerWidget {
  HomeScreen({Key? key}) : super(key: key);
  final RefreshController _refreshController = RefreshController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(backgroundFetchProvider);
    ref.watch(backgroundStarter);

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () async {
        ref.read(dateProvider.notifier).state = DateTime.now();
        _refreshController.refreshCompleted();
      },
      child: ListView(
        padding: AppTheme.screenPadding,
        children: [
          const DateSelect(),
          AppTheme.spacer4x,
          const ActivityWheel(),
          AppTheme.spacer2x,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: EnergyWidget()),
              AppTheme.spacer2x,
              const Expanded(child: SedentaryWidget()),
            ],
          ),
          AppTheme.spacer2x,
          Button(
              title: ref.watch(locationActivatedProvider)
                  ? 'stäng av bagrkund'
                  : 'Slå på bagrkund',
              onPressed: () {
                ref.read(locationActivatedProvider.notifier).state = true;
              })
        ],
      ),
    );
  }
}
