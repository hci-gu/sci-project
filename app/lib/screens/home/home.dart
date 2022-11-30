import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/no_data_message.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/date_select.dart';

class HomeScreen extends HookConsumerWidget {
  HomeScreen({Key? key}) : super(key: key);
  final RefreshController _refreshController = RefreshController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool showDataWidgets = ref.watch(userHasDataProvider);

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () async {
        ref.read(dateProvider.notifier).state = DateTime.now();
        _refreshController.refreshCompleted();
      },
      child: ListView(
        padding: AppTheme.screenPadding,
        children: [
          if (showDataWidgets) const DateSelect(),
          AppTheme.spacer4x,
          if (showDataWidgets) const ActivityWheel(),
          AppTheme.spacer2x,
          if (showDataWidgets)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: EnergyWidget()),
                AppTheme.spacer2x,
                const Expanded(child: SedentaryWidget()),
              ],
            ),
          if (!showDataWidgets) const NoDataMessage(),
        ],
      ),
    );
  }
}
