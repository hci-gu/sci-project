import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/settings/widgets/app_settings.dart';
import 'package:scimovement/screens/settings/widgets/user_settings.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user = ref.watch(userProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 16),
      children: [
        const Text(
          'Profil',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        AppTheme.spacer2x,
        UserSettings(user: user),
        AppTheme.separator,
        Text(
          'Appinställningar',
          style: AppTheme.labelXLarge,
        ),
        const AppSettings(),
        AppTheme.separator,
        const LogoutButton(),
        AppTheme.spacer2x,
        const OnboardingButton(),
        AppTheme.separator,
        Column(
          children: [
            Text(
              'AnvändarID:',
              style: AppTheme.labelMedium,
            ),
            Text(
              user.id,
              style: AppTheme.paragraphSmall,
            ),
          ],
        ),
      ],
    );
  }
}

class LogoutButton extends ConsumerWidget {
  const LogoutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      title: 'Logga ut',
      width: 220,
      secondary: true,
      icon: Icons.logout_outlined,
      color: Colors.black,
      onPressed: () => ref.read(userProvider.notifier).logout(),
    );
  }
}

class OnboardingButton extends ConsumerWidget {
  const OnboardingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      title: 'Gör om intro',
      width: 220,
      secondary: true,
      onPressed: () async {
        ref.read(onboardingStepProvider.notifier).state = ONBOARDING_STEP_COUNT;
        await Future.delayed(const Duration(milliseconds: 100));
        ref.read(onboardingStepProvider.notifier).state = 0;
        await Future.delayed(const Duration(milliseconds: 100));
        context.goNamed('onboarding');
      },
    );
  }
}
