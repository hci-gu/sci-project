import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/settings/widgets/app_settings.dart';
import 'package:scimovement/screens/settings/widgets/user_settings.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:scimovement/widgets/snackbar_message.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user = ref.watch(userProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scrollbar(
      thumbVisibility: true,
      child: ListView(
        primary: true,
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 16),
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
          AppTheme.spacer2x,
          const DeleteAccountButton(),
          AppTheme.separator,
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: user.id));
              ScaffoldMessenger.of(context).showSnackBar(SnackbarMessage(
                context: context,
                message: 'Användar-ID kopierat till urklipp',
              ));
            },
            child: Column(
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
          ),
          AppTheme.spacer2x,
          const AboutInfo(),
        ],
      ),
    );
  }
}

class AboutInfo extends StatelessWidget {
  const AboutInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _body(context, snapshot.data);
        }
        return const SizedBox();
      },
    );
  }

  Widget _body(BuildContext context, PackageInfo? info) {
    return GestureDetector(
      onTap: () => showLicensePage(
        context: context,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline),
              AppTheme.spacer,
              Text(
                info?.appName ?? '',
                style: AppTheme.labelMedium,
              ),
              AppTheme.spacer,
              Text(
                '${info?.version} (${info?.buildNumber})',
                style: AppTheme.paragraphSmall,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'Visa licenser',
              style: AppTheme.paragraphSmall,
            ),
          ),
        ],
      ),
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
        ref.read(onboardingStepProvider.notifier).state = onboardingStepCount;
        await Future.delayed(const Duration(milliseconds: 100));
        ref.read(onboardingStepProvider.notifier).state = 0;
        await Future.delayed(const Duration(milliseconds: 100));
        context.goNamed('onboarding');
      },
    );
  }
}

class DeleteAccountButton extends ConsumerWidget {
  const DeleteAccountButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      title: 'Radera konto',
      width: 220,
      secondary: true,
      color: AppTheme.colors.error,
      icon: Icons.delete_forever_outlined,
      onPressed: () async {
        bool? confirmed = await confirmDialog(
          context,
          title: 'Radera konto',
          message:
              'Är du säker att du vill radera ditt konto? Du kan inte ångra dig och din data försvinner efter du har raderat ditt konto.',
        );
        if (confirmed == true) {
          ref.read(userProvider.notifier).deleteAccount();
        }
      },
    );
  }
}
