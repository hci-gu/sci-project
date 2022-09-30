import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/screens/onboarding/onboarding.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_step.dart';
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
            Discovery(
              visible: ref.watch(onboardingStepProvider) == 0,
              child: const DateSelect(),
              message: Positioned(
                left: MediaQuery.of(context).size.width / 2 - 140 - 16,
                bottom: 24,
                child: const OnboardingStepMessage(
                  title: 'Intro',
                  text:
                      'Hej och välkommen till RullaPå, den här guiden kommer att visa vad det är du ser på skärmen.\n\nTrycka på "Nästa" för att gå vidare.',
                ),
              ),
            ),
            const SizedBox(height: 32),
            Discovery(
              visible: ref.watch(onboardingStepProvider) == 1,
              child: const ActivityWheel(),
              message: const Positioned(
                bottom: -150,
                child: OnboardingStepMessage(
                  title: 'Rörelse',
                  text:
                      'Här visas tiden som du rör dig i låg intensitet, aktiviteter i rörelse som upplevs som lättare ansträngning.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Discovery(
                  visible: ref.watch(onboardingStepProvider) == 2,
                  child: const EnergyWidget(),
                  message: const Positioned(
                    top: -190,
                    child: OnboardingStepMessage(
                      title: 'Kalorier',
                      text:
                          'Här visas en uppskattning av din dagliga åtgång av kalorier utöver de kalorier din kropp behöver i vila. Här ingår vardagsaktiviteter samt promenad/träning utomhus.',
                    ),
                  ),
                ),
                AppTheme.spacer2x,
                Discovery(
                  visible: ref.watch(onboardingStepProvider) == 3,
                  child: const SedentaryWidget(),
                  message: const Positioned(
                    top: -168,
                    right: 0,
                    child: OnboardingStepMessage(
                      title: 'Stillasittande',
                      text:
                          'Här visas en uppskattning av genomsnittstiden du är stillasittande innan du börjar röra på dig i minst 5 minuter.',
                    ),
                  ),
                ),
              ],
            ),
            Discovery(
              visible: ref.watch(onboardingStepProvider) == 4,
              child: const SizedBox(width: 1),
              message: const Positioned(
                left: -140,
                bottom: 24,
                child: OnboardingStepMessage(
                  title: 'Det var allt!',
                  text:
                      'Du kan se mer info kring alla delar vi gick igenom genom att trycka på de olika sektionerna. \n\nVill du tillbaka till guiden igen gör du det genom att trycka på "Gör om intro" i profilsidan.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
