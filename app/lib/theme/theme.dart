import 'package:flutter/material.dart';
import 'package:scimovement/theme/utils.dart';

class AppColors {
  final primary = Colors.blueGrey.shade500;
  final primaryDark = Colors.blueGrey.shade700;
  final white = Colors.white;
}

class AppTheme {
  static AppColors colors = AppColors();
  static const MaterialColor primarySwatch = Colors.blueGrey;

  static double basePadding = 8.0;

  static ThemeData theme = ThemeData(
    primarySwatch: primarySwatch,
    primaryColor: colors.primary,
    primaryColorDark: colors.primaryDark,
    backgroundColor: colors.white,
  );

  static TextStyle buttonTextStyle = TextStyle(
    color: colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static EdgeInsetsGeometry screenPadding = EdgeInsets.symmetric(
      horizontal: basePadding * 3, vertical: basePadding * 2);
  static EdgeInsetsGeometry elementPadding = EdgeInsets.symmetric(
    horizontal: basePadding * 2,
    vertical: basePadding * 1.5,
  );

  static ButtonStyle buttonStyle = ButtonStyle(
    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(elementPadding),
    backgroundColor: MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.pressed)) {
          return primarySwatch.shade600;
        }
        return primarySwatch.shade500;
      },
    ),
    textStyle: MaterialStateProperty.all<TextStyle>(buttonTextStyle),
  );
}