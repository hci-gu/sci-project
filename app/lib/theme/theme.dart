import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/theme/utils.dart';

class AppColors {
  final primary = HexColor('#d5454f');
  final primaryDark = HexColor('#9d2235');
  final white = HexColor('#FFFFFF');
  final background = HexColor('#FDFCFC');
  final black = HexColor('#210809');
  final success = HexColor('#118A2E');
  final error = HexColor('#D62F3A');
  final gray = HexColor('#6B6162');
  final mediumGray = HexColor('#A59C9D');
  final lightGray = HexColor('#E9E2E2');
  final orange = HexColor('#E36A3D');
  final yellow = HexColor('#FFA845');

  final moving = HexColor('#87BCDE');
  final active = HexColor('#44BD7A');
  final sedentary = HexColor('#C82D38');

  Color activityLevelToColor(Activity activity) {
    switch (activity) {
      case Activity.moving:
        return moving;
      case Activity.active:
        return active;
      case Activity.sedentary:
        return sedentary;
      default:
        return black;
    }
  }
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
    backgroundColor: colors.background,
    fontFamily: 'Manrope',
  );

  static TextStyle headLine1 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: colors.black,
  );
  static TextStyle headLine2 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: colors.black,
  );
  static TextStyle headLine3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: colors.black,
  );
  static TextStyle headLine3Light = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w300,
    color: colors.black,
  );

  static TextStyle paragraphMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    color: colors.black,
  );
  static TextStyle paragraphSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: colors.black,
  );

  static TextStyle labelXLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: colors.black,
  );
  static TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: colors.black,
  );
  static TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: colors.black,
  );
  static TextStyle labelTiny = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: colors.gray,
  );
  static TextStyle labelXTiny = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w500,
    color: colors.gray,
  );

  static Widget spacer = SizedBox(width: basePadding, height: basePadding);
  static Widget spacer2x =
      SizedBox(width: basePadding * 2, height: basePadding * 2);

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

  static AppBar appBar(String title) {
    return AppBar(
      title: Text(
        title,
        style: AppTheme.headLine3.copyWith(color: AppTheme.colors.white),
      ),
    );
  }

  static Widget get separator => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Container(
          height: 1,
          color: const Color.fromRGBO(0, 0, 0, 0.1),
        ),
      );
}
