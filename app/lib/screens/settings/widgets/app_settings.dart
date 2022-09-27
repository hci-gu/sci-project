import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/theme/theme.dart';

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
              value: false,
              onChanged: (value) {},
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
}
