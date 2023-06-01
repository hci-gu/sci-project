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

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom: 100,
              top: AppTheme.basePadding * 2,
              left: AppTheme.basePadding * 2,
              right: AppTheme.basePadding * 2,
            ),
            children: [
              OnboardingStep(),
            ],
          ),
          const Positioned(
            bottom: 0,
            child: OnboardingStepper(),
          ),
        ],
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
        Text('Välkommen till RullaPå!', style: AppTheme.headLine3),
        AppTheme.spacer2x,
        SvgPicture.asset(
          'assets/svg/person.svg',
          height: 80,
        ),
        AppTheme.spacer2x,
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
        Text('Klockfunktioner', style: AppTheme.headLine3),
        Image.asset('assets/images/fitbit.png', width: 200),
        const AppFeatureWidget(
          asset: 'assets/svg/flame.svg',
          title: 'Kalorier',
          description:
              'Här visas en uppskattning av din dagliga energiförbrukning (kalorier) du. Du kan även  jämföra med en genomsnittlig dag under senaste veckan.',
        ),
        AppTheme.spacer,
        const AppFeatureWidget(
          asset: 'assets/svg/wheelchair.svg',
          title: 'Stillasittande',
          description:
              'Här får du information om hur länge du sitter still sammanlagt under en dag, hur ofta du bryter upp ditt stillasittande samt hur länge du sitter still innan du är aktiv. ',
        ),
        AppTheme.spacer,
        const AppFeatureWidget(
          asset: 'assets/svg/wheelchair.svg',
          title: 'Rörelse',
          description:
              'Här visas hur länge och när du är fysiskt  aktiv, beskrivet som låg, medlel och hög intensitet',
        ),
        AppTheme.spacer4x,
        const FeatureToggle(
          feature: AppFeature.watch,
          addText: 'Jag vill ha dessa funktioner',
          removeText: 'Inte intresserad / Har inte en klocka',
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
        Text('Trycksår & avlastning', style: AppTheme.headLine3),
        Image.asset('assets/images/fitbit.png', width: 200),
        const AppFeatureWidget(
          asset: 'assets/svg/alarm.svg',
          title: 'Tryckavlastning',
          description:
              'Här får du information om hur ofta du har tryckavlastat samt hur länge du suttit still mellan dina tryckavlastningar. Du kan även ställa in hur många gånger under dagen som du skall påminnas.',
        ),
        AppTheme.spacer,
        const AppFeatureWidget(
          asset: 'assets/svg/wheelchair.svg',
          title: 'Trycksår',
          description:
              'Här kan du registrera placering, grad samt fotografera utbredningen av trycksår för att kunna följa utvecklingen av ditt trycksår.',
        ),
        AppTheme.spacer4x,
        const FeatureToggle(
          feature: AppFeature.pressureRelease,
          addText: 'Jag vill ha dessa funktioner',
          removeText: 'Inte intresserad',
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
        Text('Smärta i muskler & leder', style: AppTheme.headLine3),
        SizedBox(
          height: 200,
          child: Center(
            child: SvgPicture.asset('assets/svg/scapula.svg', height: 100),
          ),
        ),
        const AppFeatureWidget(
          asset: 'assets/svg/alarm.svg',
          title: 'Logga din smärta',
          description:
              'Här kan du registrera vart du har smärta samt vilken nivå av smärta du har just idag.',
        ),
        AppTheme.spacer4x,
        const FeatureToggle(
          feature: AppFeature.pain,
          addText: 'Jag vill ha dessa funktioner',
          removeText: 'Inte intresserad',
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
        Text('Pushnotiser', style: AppTheme.headLine3),
        const SizedBox(
          height: 200,
          child: Center(
            child: Icon(Icons.notifications_active_outlined, size: 100),
          ),
        ),
        Text(
          'För att kunna få påminnelser eller rekommendationer genom pushnotiser så behöver du ge ditt godkännande att appen ska få skicka pushnotiser till dig.',
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
        Row(
          children: [
            Text('Aktivera pushnotiser', style: AppTheme.labelLarge),
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
          'Du kan när som helst ändra dina inställningar i appen.',
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
        message:
            'Du måste slå på notifikationer i telefonens appinställningar.',
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

    return Column(
      children: [
        Row(
          children: [
            Radio(
              value: Selected.yes,
              groupValue: selection,
              onChanged: (_) {
                if (!hasFeature) {
                  ref.read(appFeaturesProvider.notifier).state = [
                    ...features,
                    feature
                  ];
                }
              },
            ),
            AppTheme.spacer,
            Text(addText, style: AppTheme.paragraphMedium),
          ],
        ),
        Row(
          children: [
            Radio(
              value: Selected.no,
              groupValue: selection,
              onChanged: (_) {
                if (hasFeature) {
                  ref.read(appFeaturesProvider.notifier).state =
                      features.whereNot((e) => e == feature).toList();
                }
              },
            ),
            AppTheme.spacer,
            Text(removeText, style: AppTheme.paragraphMedium),
          ],
        ),
      ],
    );
  }
}
