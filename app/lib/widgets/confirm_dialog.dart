import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';

Future<bool?> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool?>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(title, style: AppTheme.headLine3),
        content: Text(
          message,
          style: AppTheme.paragraphMedium,
        ),
        titlePadding: EdgeInsets.symmetric(
          horizontal: AppTheme.basePadding * 2,
          vertical: AppTheme.basePadding,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.basePadding * 2,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        actionsPadding: EdgeInsets.all(AppTheme.basePadding * 2),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Button(
                  onPressed: () {
                    Navigator.of(ctx).pop(false);
                  },
                  secondary: true,
                  rounded: true,
                  size: ButtonSize.small,
                  title: 'Avbryt',
                ),
              ),
              SizedBox(width: AppTheme.basePadding * 4),
              Expanded(
                child: Button(
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                  },
                  rounded: true,
                  size: ButtonSize.small,
                  color: AppTheme.colors.error,
                  title: 'Ja',
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
