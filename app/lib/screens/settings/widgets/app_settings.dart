import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/locale_select.dart';
import 'package:scimovement/widgets/snackbar_message.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppSettings extends ConsumerWidget {
  const AppSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AppTheme.spacer2x,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.notifications,
                style: AppTheme.paragraphMedium),
            CupertinoSwitch(
              thumbColor: AppTheme.colors.white,
              activeColor: AppTheme.colors.primary,
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
          ],
        ),
        if (ref.watch(notificationsEnabledProvider))
          const NotificationToggles(),
        AppTheme.spacer2x,
        const AppFeatureToggles(),
        AppTheme.spacer2x,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.language,
              style: AppTheme.paragraphMedium,
            ),
            LocaleSelect(),
          ],
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
          AppLocalizations.of(context)!.watchFunctions,
          AppFeature.watch,
          ref,
        ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.paragraphMedium,
        ),
        CupertinoSwitch(
          thumbColor: AppTheme.colors.white,
          activeColor: AppTheme.colors.primary,
          value: features.contains(feature),
          onChanged: (add) async {
            if (add) {
              ref.read(appFeaturesProvider.notifier).state = [
                ...features,
                feature
              ];
            } else {
              ref.read(appFeaturesProvider.notifier).state =
                  features.whereNot((e) => e == feature).toList();
            }
          },
        ),
      ],
    );
  }
}

class NotificationToggles extends ConsumerWidget {
  const NotificationToggles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User user = ref.watch(userProvider)!;

    return Padding(
      padding: EdgeInsets.only(left: AppTheme.basePadding),
      child: Column(
        children: [
          AppTheme.spacer,
          if (ref.watch(appFeaturesProvider).contains(AppFeature.watch))
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.movementReminders,
                  style: AppTheme.paragraphMedium,
                ),
                CupertinoSwitch(
                  thumbColor: AppTheme.colors.white,
                  activeColor: AppTheme.colors.primary,
                  value: user.notificationSettings.activity,
                  onChanged: (value) async {
                    ref
                        .read(userProvider.notifier)
                        .updateNotificationSettings(NotificationSettings(
                          activity: value,
                          data: user.notificationSettings.data,
                          journal: user.notificationSettings.journal,
                        ));
                  },
                ),
              ],
            ),
          if (ref.watch(appFeaturesProvider).contains(AppFeature.watch))
            AppTheme.spacer,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.logbookReminders,
                style: AppTheme.paragraphMedium,
              ),
              CupertinoSwitch(
                thumbColor: AppTheme.colors.white,
                activeColor: AppTheme.colors.primary,
                value: user.notificationSettings.journal,
                onChanged: (value) async {
                  ref
                      .read(userProvider.notifier)
                      .updateNotificationSettings(NotificationSettings(
                        activity: user.notificationSettings.activity,
                        data: user.notificationSettings.data,
                        journal: value,
                      ));
                },
              ),
            ],
          ),
          AppTheme.spacer,
          if (ref.watch(appFeaturesProvider).contains(AppFeature.watch))
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.noDataWarning,
                  style: AppTheme.paragraphMedium,
                ),
                CupertinoSwitch(
                  thumbColor: AppTheme.colors.white,
                  activeColor: AppTheme.colors.primary,
                  value: user.notificationSettings.data,
                  onChanged: (value) async {
                    ref
                        .read(userProvider.notifier)
                        .updateNotificationSettings(NotificationSettings(
                          activity: user.notificationSettings.activity,
                          data: value,
                          journal: user.notificationSettings.journal,
                        ));
                  },
                ),
              ],
            )
        ],
      ),
    );
  }
}
