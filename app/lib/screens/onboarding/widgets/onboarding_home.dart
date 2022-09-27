import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/screens/onboarding/onboarding.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/date_select.dart';
import 'package:scimovement/widgets/stat_widget.dart';

class OnboardingHomeScreen extends ConsumerWidget {
  const OnboardingHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        energyWidgetProvider.overrideWithValue(
          const AsyncValue.data(WidgetValues(400, 380)),
        ),
        sedentaryWidgetProvider.overrideWithValue(
          const AsyncValue.data(WidgetValues(45, 48)),
        ),
        activityProvider.overrideWithValue(AsyncValue.data([
          ActivityGroup(Activity.sedentary, [
            Energy(time: DateTime.now(), value: 25, minutes: 210),
          ]),
          ActivityGroup(Activity.moving, [
            Energy(time: DateTime.now(), value: 270, minutes: 90),
          ]),
          ActivityGroup(Activity.active, [
            Energy(time: DateTime.now(), value: 80, minutes: 25),
          ]),
        ])),
      ],
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            const DateSelect(),
            const SizedBox(height: 32),
            Discovery(
              visible: ref.watch(onboardingStepProvider) == 0,
              description: const Text('Kalorier'),
              onClose: () => {},
              child: const ActivityWheel(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Discovery(
                  visible: ref.watch(onboardingStepProvider) == 1,
                  description: const Text('Kalorier'),
                  onClose: () => {},
                  child: const EnergyWidget(),
                ),
                AppTheme.spacer,
                Discovery(
                  visible: ref.watch(onboardingStepProvider) == 2,
                  description: const Text('Kalorier'),
                  onClose: () => {},
                  child: const SedentaryWidget(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
