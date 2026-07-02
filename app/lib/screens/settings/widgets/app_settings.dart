import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/locale_select.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class AppSettings extends ConsumerWidget {
  const AppSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AppTheme.spacer2x,
        _AdaptiveSettingsRow(
          title: AppLocalizations.of(context)!.notifications,
          trailing: CupertinoSwitch(
            thumbColor: AppTheme.colors.white,
            activeTrackColor: AppTheme.colors.primary,
            value: ref.watch(notificationsEnabledProvider),
            onChanged: (value) async {
              if (value) {
                await ref
                    .read(userProvider.notifier)
                    .requestNotificationPermission();
                if (!ref.read(notificationsEnabledProvider) &&
                    context.mounted) {
                  _displayNotificationPermissionDialog(context);
                }
              } else {
                ref.read(userProvider.notifier).turnOffNotifications();
              }
            },
          ),
        ),
        if (ref.watch(notificationsEnabledProvider))
          const NotificationToggles(),
        AppTheme.spacer2x,
        const AppFeatureToggles(),
        AppTheme.spacer2x,
        _AdaptiveSettingsRow(
          title: AppLocalizations.of(context)!.language,
          trailing: LocaleSelect(),
        ),
        AppTheme.spacer,
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

class AppFeatureToggles extends ConsumerWidget {
  const AppFeatureToggles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.enableDisableFeatures,
          style: AppTheme.labelLarge,
        ),
        AppTheme.spacer,
        _row(
          AppLocalizations.of(context)!.onboardingPainFeature,
          AppFeature.pain,
          ref,
        ),
        _row(
          AppLocalizations.of(context)!.onboardingPressureReleaseAndUlcerTitle,
          AppFeature.pressureRelease,
          ref,
        ),
        _row(
          AppLocalizations.of(context)!.onboardingBladderAndBowelFunctions,
          AppFeature.bladderAndBowel,
          ref,
        ),
      ],
    );
  }

  Widget _row(String title, AppFeature feature, WidgetRef ref) {
    List<AppFeature> features = ref.watch(appFeaturesProvider);
    return _AdaptiveSettingsRow(
      title: title,
      trailing: CupertinoSwitch(
        thumbColor: AppTheme.colors.white,
        activeTrackColor: AppTheme.colors.primary,
        value: features.contains(feature),
        onChanged: (add) async {
          final List<AppFeature> nextFeatures =
              add
                  ? {...features, feature}.toList()
                  : features.where((f) => f != feature).toList();

          if (add) {
            ref.read(appFeaturesProvider.notifier).addFeature(feature);
          } else {
            ref.read(appFeaturesProvider.notifier).removeFeature(feature);
          }

          if (ref.read(userProvider) != null) {
            await ref.read(userProvider.notifier).update({
              'features': appFeaturesToJson(nextFeatures),
            });
          }
        },
      ),
    );
  }
}

class NotificationToggles extends ConsumerWidget {
  const NotificationToggles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User user = ref.watch(userProvider)!;

    return Padding(
      padding: EdgeInsets.only(left: AppTheme.basePadding),
      child: Column(
        children: [
          AppTheme.spacer,
          if (ref.watch(appFeaturesProvider).contains(AppFeature.watch))
            _AdaptiveSettingsRow(
              title: AppLocalizations.of(context)!.movementReminders,
              trailing: CupertinoSwitch(
                thumbColor: AppTheme.colors.white,
                activeTrackColor: AppTheme.colors.primary,
                value: user.notificationSettings.activity,
                onChanged: (value) async {
                  ref
                      .read(userProvider.notifier)
                      .updateNotificationSettings(
                        NotificationSettings(
                          activity: value,
                          data: user.notificationSettings.data,
                          journal: user.notificationSettings.journal,
                        ),
                      );
                },
              ),
            ),
          if (ref.watch(appFeaturesProvider).contains(AppFeature.watch))
            AppTheme.spacer,
          _AdaptiveSettingsRow(
            title: AppLocalizations.of(context)!.logbookReminders,
            trailing: CupertinoSwitch(
              thumbColor: AppTheme.colors.white,
              activeTrackColor: AppTheme.colors.primary,
              value: user.notificationSettings.journal,
              onChanged: (value) async {
                ref
                    .read(userProvider.notifier)
                    .updateNotificationSettings(
                      NotificationSettings(
                        activity: user.notificationSettings.activity,
                        data: user.notificationSettings.data,
                        journal: value,
                      ),
                    );
              },
            ),
          ),
          AppTheme.spacer,
          if (ref.watch(appFeaturesProvider).contains(AppFeature.watch))
            _AdaptiveSettingsRow(
              title: AppLocalizations.of(context)!.noDataWarning,
              trailing: CupertinoSwitch(
                thumbColor: AppTheme.colors.white,
                activeTrackColor: AppTheme.colors.primary,
                value: user.notificationSettings.data,
                onChanged: (value) async {
                  ref
                      .read(userProvider.notifier)
                      .updateNotificationSettings(
                        NotificationSettings(
                          activity: user.notificationSettings.activity,
                          data: value,
                          journal: user.notificationSettings.journal,
                        ),
                      );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AdaptiveSettingsRow extends StatelessWidget {
  final String title;
  final Widget trailing;

  const _AdaptiveSettingsRow({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final shouldStack = MediaQuery.textScalerOf(context).scale(1) > 1.15;

    if (shouldStack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.paragraphMedium),
          AppTheme.spacer,
          Align(alignment: Alignment.centerLeft, child: trailing),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(title, style: AppTheme.paragraphMedium)),
        AppTheme.spacer2x,
        trailing,
      ],
    );
  }
}
