import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:onboarding_overlay/onboarding_overlay.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/date_select.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({Key? key}) : super(key: key);
  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);

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
              Focus(
                focusNode: ref.watch(onboardingNodesProvider)[1],
                child: const EnergyWidget(),
              ),
              AppTheme.spacer,
              const SedentaryWidget(),
            ],
          ),
          const SizedBox(height: 16),
          IconButton(
            focusNode: ref.watch(onboardingNodesProvider)[0],
            onPressed: () {},
            icon: Icon(Icons.ac_unit_rounded),
          ),
          Button(
            title: 'Start Onboarding',
            onPressed: () {
              final OnboardingState? onboarding = Onboarding.of(context);
              if (onboarding != null) {
                print('start onboarding');
                onboarding.show();
              }
            },
          )
        ],
      ),
    );
  }
}
