import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/theme/utils.dart';
import 'package:scimovement/widgets/button.dart';

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

  final moving = HexColor('#748DD9');
  final active = HexColor('#40a740');
  final sedentary = HexColor('#C82D38');
  final exercise = HexColor('#F7B500');

  Color activityLevelToColor(Activity activity) {
    switch (activity) {
      case Activity.moving:
        return moving;
      case Activity.active:
      case Activity.weights:
        return active;
      case Activity.sedentary:
        return sedentary;
      default:
        return black;
    }
  }

  Color bodyPartToColor(BodyPart bodyPart) {
    bool right = bodyPart.side == Side.right;
    switch (bodyPart.type) {
      case BodyPartType.elbow:
        return right ? HexColor('#fd7f6f') : HexColor('#7eb0d5');
      case BodyPartType.hand:
        return right ? HexColor('#b2e061') : HexColor('#bd7ebe');
      case BodyPartType.scapula:
        return right ? HexColor('#ffb55a') : HexColor('#ffee65');
      case BodyPartType.shoulderJoint:
        return right ? HexColor('#beb9db') : HexColor('#fdcce5');
      case BodyPartType.neck:
        return HexColor('#8bd3c7');
      default:
        return Colors.black;
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
  static TextStyle paragraph = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
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

  static Widget spacerHalf =
      SizedBox(width: basePadding / 2, height: basePadding / 2);
  static Widget spacer = SizedBox(width: basePadding, height: basePadding);
  static Widget spacer2x =
      SizedBox(width: basePadding * 2, height: basePadding * 2);
  static Widget spacer4x =
      SizedBox(width: basePadding * 4, height: basePadding * 4);

  static EdgeInsetsGeometry screenPadding = EdgeInsets.symmetric(
    horizontal: basePadding * 2,
    vertical: basePadding * 3,
  );
  static EdgeInsetsGeometry elementPadding = EdgeInsets.symmetric(
    horizontal: basePadding * 2,
    vertical: basePadding * 1.5,
  );

  static TextStyle buttonTextStyle(
      [bool secondary = false,
      Color? color,
      ButtonSize size = ButtonSize.medium]) {
    return TextStyle(
      color: secondary ? color ?? primarySwatch.shade500 : colors.white,
      fontSize: size.fontSize,
      fontWeight: size.fontWeight,
    );
  }

  static ButtonStyle buttonStyle(
      {bool rounded = false,
      bool secondary = false,
      ButtonSize size = ButtonSize.medium,
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
            return colors.primaryDark;
          }
          return colors.primary;
        },
      ),
      textStyle: MaterialStateProperty.all<TextStyle>(
        buttonTextStyle(secondary, color),
      ),
    );
  }

  static AppBar appBar(String title, [List<Widget>? actions]) {
    return AppBar(
      title: Text(
        title,
        style: AppTheme.headLine3.copyWith(color: AppTheme.colors.white),
      ),
      actions: actions,
    );
  }

  static Widget get separator => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Container(
          height: 1,
          color: const Color.fromRGBO(0, 0, 0, 0.1),
        ),
      );
  static Widget get separatorSmall => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          height: 1,
          color: const Color.fromRGBO(0, 0, 0, 0.1),
        ),
      );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: colors.black.withOpacity(0.1),
    ),
  );
  static BoxDecoration widgetDecoration = BoxDecoration(
    border: Border.all(
      width: 1.0,
      color: const Color.fromRGBO(0, 0, 0, 0.1),
    ),
    color: AppTheme.colors.white,
    borderRadius: BorderRadius.circular(16),
  );
  static BorderRadius borderRadius = BorderRadius.circular(16);

  static Widget iconForJournalType(JournalType type,
      [BodyPart? bodyPart, double size = 48]) {
    switch (type) {
      case JournalType.pain:
        return BodyPartIcon(
          bodyPart: bodyPart ?? BodyPart(BodyPartType.scapula, null),
          size: size,
        );
      case JournalType.pressureRelease:
        return Icon(
          Icons.alarm,
          size: size,
          color: AppTheme.colors.black,
        );
      case JournalType.pressureUlcer:
        return Icon(
          Icons.album_outlined,
          size: size,
          color: AppTheme.colors.black,
        );
      case JournalType.bladderEmptying:
        return SvgPicture.asset('assets/svg/toilet.svg', height: size);
      case JournalType.urinaryTractInfection:
        return Icon(
          Icons.water,
          size: size,
          color: AppTheme.colors.black,
        );
      case JournalType.leakage:
        return Icon(
          Icons.water_drop_outlined,
          size: size,
          color: AppTheme.colors.black,
        );
      case JournalType.exercise:
        return Icon(
          Icons.offline_bolt_outlined,
          size: size,
          color: AppTheme.colors.black,
        );
      default:
        return Icon(
          Icons.album_outlined,
          size: size,
          color: AppTheme.colors.black,
        );
    }
  }
}
