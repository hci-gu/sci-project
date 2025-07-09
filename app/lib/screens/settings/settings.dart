import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/screens/settings/widgets/app_settings.dart';
import 'package:scimovement/screens/settings/widgets/user_settings.dart';
import 'package:scimovement/screens/settings/widgets/watch_settings.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
        padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 16),
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Text(
            AppLocalizations.of(context)!.profile,
            style: AppTheme.headLine1,
          ),
          AppTheme.spacer2x,
          UserSettings(user: user),
          AppTheme.separator,
          Text(
            AppLocalizations.of(context)!.watchSettings,
            style: AppTheme.labelXLarge,
          ),
          const WatchSettings(),
          AppTheme.separator,
          Text(
            AppLocalizations.of(context)!.appSettings,
            style: AppTheme.labelXLarge,
          ),
          const AppSettings(),
          AppTheme.separator,
          const Center(child: LogoutButton()),
          AppTheme.spacer2x,
          const Center(child: OnboardingButton()),
          AppTheme.spacer2x,
          const Center(child: DeleteAccountButton()),
          AppTheme.separator,
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: user.id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackbarMessage(
                    context: context,
                    message: AppLocalizations.of(context)!.userIdCopyMessage,
                  ),
                );
              }
            },
            child: Column(
              children: [
                Text(
                  '${AppLocalizations.of(context)!.userId}:',
                  style: AppTheme.labelMedium,
                ),
                Text(user.id, style: AppTheme.paragraphSmall),
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
  const AboutInfo({super.key});

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
      onTap: () => showLicensePage(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline),
              AppTheme.spacer,
              Text(info?.appName ?? '', style: AppTheme.labelMedium),
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
              AppLocalizations.of(context)!.showLicenses,
              style: AppTheme.paragraphSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      title: AppLocalizations.of(context)!.logout,
      width: 220,
      secondary: true,
      icon: Icons.logout_outlined,
      color: Colors.black,
      onPressed: () => ref.read(userProvider.notifier).logout(),
    );
  }
}

class OnboardingButton extends ConsumerWidget {
  const OnboardingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      title: AppLocalizations.of(context)!.redoIntro,
      width: 220,
      secondary: true,
      onPressed: () {
        Storage().storeOnboardingDone(false);
        ref.read(onboardingStepProvider.notifier).state = 0;
        context.goNamed('onboarding');
      },
    );
  }
}

class DeleteAccountButton extends ConsumerWidget {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      title: AppLocalizations.of(context)!.deleteAccount,
      width: 220,
      secondary: true,
      color: AppTheme.colors.error,
      icon: Icons.delete_forever_outlined,
      onPressed: () async {
        bool? confirmed = await confirmDialog(
          context,
          title: AppLocalizations.of(context)!.deleteAccount,
          message: AppLocalizations.of(context)!.deleteAccountConfirmation,
        );
        if (confirmed == true) {
          ref.read(userProvider.notifier).deleteAccount();
        }
      },
    );
  }
}
