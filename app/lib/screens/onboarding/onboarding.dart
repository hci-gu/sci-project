import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/onboarding/widgets/onboarding_stepper.dart';
import 'package:scimovement/screens/settings/widgets/app_settings.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                bottom: 100,
                top: AppTheme.basePadding * 2,
                left: AppTheme.basePadding * 2,
                right: AppTheme.basePadding * 2,
              ),
              children: const [
                OnboardingStep(),
              ],
            ),
            const Positioned(
              bottom: 0,
              child: OnboardingStepper(),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingStep extends ConsumerWidget {
  const OnboardingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int step = ref.watch(onboardingStepProvider);

    switch (step) {
      case 0:
        return const OnboardingWelcome();
      case 1:
        return const WatchFunctions();
      case 2:
        return const PressureReleaseFunctions();
      case 3:
        return const PainFunctions();
      case 4:
        return const PushNotifications();
      default:
        return Container();
    }
  }
}

class OnboardingWelcome extends StatelessWidget {
  const OnboardingWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(AppLocalizations.of(context)!.introductionWelcome,
            style: AppTheme.headLine3),
        AppTheme.spacer2x,
        SvgPicture.asset(
          'assets/svg/person.svg',
          height: 80,
        ),
        AppTheme.spacer2x,
        Text(AppLocalizations.of(context)!.onboardingIntro,
            style: AppTheme.paragraphMedium),
      ],
    );
  }
}

class WatchFunctions extends ConsumerWidget {
  const WatchFunctions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(AppLocalizations.of(context)!.watchFunctions,
            style: AppTheme.headLine3),
        Image.asset('assets/images/fitbit.png', width: 200),
        AppFeatureWidget(
          asset: 'assets/svg/flame.svg',
          title: AppLocalizations.of(context)!.calories,
          description:
              AppLocalizations.of(context)!.onboardingCaloriesDescription,
        ),
        AppTheme.spacer,
        AppFeatureWidget(
          asset: 'assets/svg/wheelchair.svg',
          title: AppLocalizations.of(context)!.sedentary,
          description:
              AppLocalizations.of(context)!.onboardingSedentaryDescription,
        ),
        AppTheme.spacer,
        AppFeatureWidget(
          asset: 'assets/svg/wheelchair.svg',
          title: AppLocalizations.of(context)!.movement,
          description:
              AppLocalizations.of(context)!.onboardingMovementDescription,
        ),
        AppTheme.spacer4x,
        FeatureToggle(
          feature: AppFeature.watch,
          addText: AppLocalizations.of(context)!.onboardingWantFunctions,
          removeText:
              '${AppLocalizations.of(context)!.onboardingNotInterested} / ${AppLocalizations.of(context)!.onboardingDontHaveWatch}',
        ),
      ],
    );
  }
}

class PressureReleaseFunctions extends ConsumerWidget {
  const PressureReleaseFunctions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(
            AppLocalizations.of(context)!
                .onboardingPressureReleaseAndUlcerTitle,
            style: AppTheme.headLine3),
        Image.asset('assets/images/fitbit.png', width: 200),
        AppFeatureWidget(
          asset: 'assets/svg/alarm.svg',
          title: AppLocalizations.of(context)!.pressureRelease,
          description: AppLocalizations.of(context)!
              .onboardingPressureReleaseDescription,
        ),
        AppTheme.spacer,
        AppFeatureWidget(
          asset: 'assets/svg/wheelchair.svg',
          title: AppLocalizations.of(context)!.pressureUlcer,
          description:
              AppLocalizations.of(context)!.onboaridngPressureUlcerDescription,
        ),
        AppTheme.spacer4x,
        FeatureToggle(
          feature: AppFeature.pressureRelease,
          addText: AppLocalizations.of(context)!.onboardingWantFunctions,
          removeText: AppLocalizations.of(context)!.onboardingNotInterested,
        ),
      ],
    );
  }
}

class PainFunctions extends ConsumerWidget {
  const PainFunctions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(AppLocalizations.of(context)!.musclePainTitle,
            style: AppTheme.headLine3),
        SizedBox(
          height: 200,
          child: Center(
            child: SvgPicture.asset('assets/svg/scapula.svg', height: 100),
          ),
        ),
        AppFeatureWidget(
          asset: 'assets/svg/alarm.svg',
          title: AppLocalizations.of(context)!.onboardingPainFeature,
          description: AppLocalizations.of(context)!.onboardingPainDescription,
        ),
        AppTheme.spacer4x,
        FeatureToggle(
          feature: AppFeature.pain,
          addText: AppLocalizations.of(context)!.onboardingWantFunctions,
          removeText: AppLocalizations.of(context)!.onboardingNotInterested,
        ),
      ],
    );
  }
}

class PushNotifications extends ConsumerWidget {
  const PushNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.pushNotifications,
          style: AppTheme.headLine3,
        ),
        const SizedBox(
          height: 200,
          child: Center(
            child: Icon(Icons.notifications_active_outlined, size: 100),
          ),
        ),
        Text(
          AppLocalizations.of(context)!.onboardingPushDescription,
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.onboardingActivatePush,
              style: AppTheme.labelLarge,
            ),
            AppTheme.spacer2x,
            CupertinoSwitch(
              thumbColor: AppTheme.colors.white,
              activeColor: AppTheme.colors.primary,
              value: ref.watch(notificationsEnabledProvider),
              onChanged: (value) async {
                if (value) {
                  await ref
                      .read(userProvider.notifier)
                      .requestNotificationPermission();
                  if (!ref.read(notificationsEnabledProvider)) {
                    _displayNotificationPermissionDialog(context);
                  }
                } else {
                  ref.read(userProvider.notifier).turnOffNotifications();
                }
              },
            ),
          ],
        ),
        AppTheme.spacer2x,
        Text(
          AppLocalizations.of(context)!.onboardingSettingsInfo,
          style: AppTheme.paragraphMedium,
        ),
        if (ref.watch(notificationsEnabledProvider))
          const NotificationToggles(),
      ],
    );
  }

  void _displayNotificationPermissionDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackbarMessage(
        context: context,
        message: AppLocalizations.of(context)!.pushPermissionsErrorMessage,
        type: SnackbarType.error,
      ),
    );
  }
}

class AppFeatureWidget extends StatelessWidget {
  final String asset;
  final String title;
  final String description;

  const AppFeatureWidget({
    super.key,
    required this.asset,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(asset, width: 24),
            AppTheme.spacer,
            Text(title, style: AppTheme.headLine3),
          ],
        ),
        AppTheme.spacer,
        Text(description, style: AppTheme.paragraphMedium),
      ],
    );
  }
}

enum Selected { yes, no }

class FeatureToggle extends ConsumerWidget {
  final AppFeature feature;
  final String addText;
  final String removeText;

  const FeatureToggle({
    super.key,
    required this.feature,
    required this.addText,
    required this.removeText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<AppFeature> features = ref.watch(appFeaturesProvider);

    bool hasFeature = features.contains(feature);
    Selected selection = hasFeature ? Selected.yes : Selected.no;

    didChange(bool remove) {
      if (!hasFeature && !remove) {
        ref.read(appFeaturesProvider.notifier).state = [...features, feature];
      }
      if (hasFeature && remove) {
        ref.read(appFeaturesProvider.notifier).state =
            features.whereNot((e) => e == feature).toList();
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => didChange(false),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Radio(
                value: Selected.yes,
                groupValue: selection,
                onChanged: (_) => didChange(false),
              ),
              AppTheme.spacer,
              Text(addText, style: AppTheme.paragraphMedium),
            ],
          ),
        ),
        AppTheme.spacer,
        GestureDetector(
          onTap: () => didChange(true),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Radio(
                value: Selected.no,
                groupValue: selection,
                onChanged: (_) => didChange(true),
              ),
              AppTheme.spacer,
              Text(removeText, style: AppTheme.paragraphMedium),
            ],
          ),
        ),
      ],
    );
  }
}
