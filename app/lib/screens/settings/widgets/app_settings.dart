import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/snackbar_message.dart';

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
            Text('Notifikationer', style: AppTheme.paragraphMedium),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Språk', style: AppTheme.paragraphMedium),
            Container(),
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
