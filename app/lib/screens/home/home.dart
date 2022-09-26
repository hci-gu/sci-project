import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/date_select.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({Key? key}) : super(key: key);
  final RefreshController _refreshController = RefreshController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () async {
        ref.read(dateProvider.notifier).state = DateTime.now();
        _refreshController.refreshCompleted();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          const DateSelect(),
          const SizedBox(height: 32),
          const ActivityWheel(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const EnergyWidget(),
              AppTheme.spacer,
              const SedentaryWidget(),
            ],
          ),
        ],
      ),
    );
  }
}
