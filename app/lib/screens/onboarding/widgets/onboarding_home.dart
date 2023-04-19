import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/screens/onboarding/onboarding.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_step.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/date_select.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnboardingHomeScreen extends ConsumerWidget {
  const OnboardingHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        energyWidgetProvider
            .overrideWith((ref) => const WidgetValues(400, 380)),
        sedentaryWidgetProvider
            .overrideWith((ref) => const WidgetValues(45, 48)),
        activityProvider.overrideWith(
          (ref) => [
            ActivityGroup(Activity.sedentary, [
              Energy(time: DateTime.now(), value: 25, minutes: 210),
            ]),
            ActivityGroup(Activity.moving, [
              Energy(time: DateTime.now(), value: 270, minutes: 90),
            ]),
            ActivityGroup(Activity.active, [
              Energy(time: DateTime.now(), value: 80, minutes: 25),
            ]),
          ],
        ),
      ],
      child: ListView(
        padding: AppTheme.screenPadding,
        children: [
          Discovery(
            visible: ref.watch(onboardingStepProvider) == 0,
            child: const DateSelect(),
            message: Positioned(
              left: 0,
              bottom: 24,
              child: OnboardingStepMessage(
                title: AppLocalizations.of(context)!.intro,
                text: AppLocalizations.of(context)!.onboardingIntro,
                action: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: ref.watch(notificationsEnabledProvider)
                        ? Text(
                            AppLocalizations.of(context)!
                                .onboardingNotificationsOn,
                            style: AppTheme.labelMedium,
                          )
                        : Button(
                            width: 140,
                            title: AppLocalizations.of(context)!
                                .onboardingTurnOnNotifications,
                            onPressed: () => ref
                                .read(userProvider.notifier)
                                .requestNotificationPermission(),
                          ),
                  ),
                ),
              ),
            ),
          ),
          AppTheme.spacer4x,
          Discovery(
            visible: ref.watch(onboardingStepProvider) == 1,
            child: const SizedBox(
              height: 300,
              child: ActivityWheel(),
              width: 100000,
            ),
            message: Positioned(
              bottom: -150,
              child: OnboardingStepMessage(
                title: AppLocalizations.of(context)!.movement,
                text: AppLocalizations.of(context)!.onboardingMovement,
              ),
            ),
          ),
          AppTheme.spacer2x,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Discovery(
                visible: ref.watch(onboardingStepProvider) == 2,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 2 - 24,
                  child: const EnergyWidget(),
                ),
                message: Positioned(
                  top: -190,
                  child: OnboardingStepMessage(
                    title: AppLocalizations.of(context)!.calories,
                    text: AppLocalizations.of(context)!.onboardingCalories,
                  ),
                ),
              ),
              AppTheme.spacer2x,
              Expanded(
                child: Discovery(
                  visible: ref.watch(onboardingStepProvider) == 3,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    child: const SedentaryWidget(),
                  ),
                  message: Positioned(
                    top: -168,
                    right: 0,
                    child: OnboardingStepMessage(
                      title: AppLocalizations.of(context)!.sedentary,
                      text: AppLocalizations.of(context)!.onboardingSedentary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Discovery(
            visible: ref.watch(onboardingStepProvider) == 4,
            child: const SizedBox(width: 1),
            message: Positioned(
              left: -140,
              bottom: 24,
              child: OnboardingStepMessage(
                title: AppLocalizations.of(context)!.onboardingDoneTitle,
                text: AppLocalizations.of(context)!.onboardingDone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
