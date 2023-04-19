import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
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
        if (ref.watch(notificationsEnabledProvider))
          const NotificationToggles(),
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
        message:
            'Du måste slå på notifikationer i telefonens appinställningar.',
        type: SnackbarType.error,
      ),
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
