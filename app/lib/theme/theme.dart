import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:scimovement/theme/utils.dart';

class AppColors {
  final primary = HexColor('##d5454f');
  final primaryDark = HexColor('#9d2235');
  final white = HexColor('#F5F7FA');
  final success = HexColor('#118A2E');
  final error = HexColor('#D62F3A');
}

class AppTheme {
  static AppColors colors = AppColors();
  static MaterialColor primarySwatch =
      createMaterialColor(const Color.fromARGB(255, 213, 69, 79));

  static double basePadding = 8.0;

  static ThemeData theme = ThemeData(
    primarySwatch: primarySwatch,
    primaryColor: colors.primary,
    primaryColorDark: colors.primaryDark,
    backgroundColor: colors.white,
    fontFamily: 'Cabin',
  );

  static TextStyle appBarTextStyle = TextStyle(
    color: colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );
  static TextStyle titleTextStyle = const TextStyle(
    color: Colors.black87,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
  );

  static Widget spacer = SizedBox(width: basePadding, height: basePadding);

  static EdgeInsetsGeometry screenPadding = EdgeInsets.symmetric(
      horizontal: basePadding * 3, vertical: basePadding * 2);
  static EdgeInsetsGeometry elementPadding = EdgeInsets.symmetric(
    horizontal: basePadding * 2,
    vertical: basePadding * 1.5,
  );

  static TextStyle buttonTextStyle(
      [bool secondary = false, Color? color, bool small = false]) {
    return TextStyle(
      color: secondary ? color ?? primarySwatch.shade500 : colors.white,
      fontSize: small ? 12 : 16,
      fontWeight: small ? FontWeight.w500 : FontWeight.w800,
    );
  }

  static ButtonStyle buttonStyle(
      {bool rounded = false,
      bool secondary = false,
      bool small = false,
      Color? color}) {
    return ButtonStyle(
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: rounded
              ? BorderRadius.circular(28.0)
              : BorderRadius.circular(4.0),
          side: secondary
              ? BorderSide(color: color ?? primarySwatch.shade700)
              : BorderSide.none,
        ),
      ),
      visualDensity: VisualDensity.compact,
      padding: MaterialStateProperty.resolveWith<EdgeInsetsGeometry>(
          (Set<MaterialState> states) {
        return const EdgeInsets.all(0);
      }),
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (secondary) return colors.white;
          if (states.contains(MaterialState.pressed)) {
            return color ?? primarySwatch.shade800;
          }
          return color ?? primarySwatch.shade700;
        },
      ),
      textStyle: MaterialStateProperty.all<TextStyle>(
        buttonTextStyle(secondary, color),
      ),
    );
  }
}
