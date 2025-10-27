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
      case Activity.skiErgo:
      case Activity.rollOutside:
      case Activity.armErgo:
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
      case BodyPartType.back:
        return HexColor('#f9b5c4');
      case BodyPartType.neuropathic:
        return HexColor('#6b6162');
      case BodyPartType.allodynia:
        return HexColor('#6B8982');
      case BodyPartType.intermittentNeuroPathic:
        return HexColor('#811D27');
      default:
        return Colors.black;
    }
  }
}

class AppTheme {
  static AppColors colors = AppColors();
  static MaterialColor primarySwatch = createMaterialColor(
    const Color.fromARGB(255, 213, 69, 79),
  );

  static double halfPadding = 4.0;
  static double basePadding = 8.0;

  static ThemeData theme = ThemeData(
    primaryColor: colors.primary,
    primaryColorDark: colors.primaryDark,
    fontFamily: 'Manrope',
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.primary,
      surface: colors.background,
    ),
    useMaterial3: true,

    appBarTheme: AppBarTheme(
      backgroundColor: colors.primary,
      surfaceTintColor: colors.white,
      foregroundColor: colors.white,
    ),
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
  static TextStyle labelSmall = TextStyle(
    fontSize: 12,
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

  static Widget spacerHalf = SizedBox(
    width: basePadding / 2,
    height: basePadding / 2,
  );
  static Widget spacer = SizedBox(width: basePadding, height: basePadding);
  static Widget spacer2x = SizedBox(
    width: basePadding * 2,
    height: basePadding * 2,
  );
  static Widget spacer4x = SizedBox(
    width: basePadding * 4,
    height: basePadding * 4,
  );

  static EdgeInsetsGeometry screenPadding = EdgeInsets.symmetric(
    horizontal: basePadding * 2,
    vertical: basePadding * 3,
  );
  static EdgeInsetsGeometry elementPadding = EdgeInsets.symmetric(
    horizontal: basePadding * 2,
    vertical: basePadding * 1.5,
  );
  static EdgeInsetsGeometry elementPaddingSmall = EdgeInsets.symmetric(
    horizontal: basePadding,
    vertical: basePadding,
  );

  static TextStyle buttonTextStyle([
    bool secondary = false,
    Color? color,
    ButtonSize size = ButtonSize.medium,
  ]) {
    return TextStyle(
      color: secondary ? color ?? primarySwatch.shade500 : colors.white,
      fontSize: size.fontSize,
      fontWeight: size.fontWeight,
    );
  }

  static ButtonStyle buttonStyle({
    bool rounded = false,
    bool secondary = false,
    ButtonSize size = ButtonSize.medium,
    Color? color,
  }) {
    return ButtonStyle(
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius:
              rounded
                  ? BorderRadius.circular(28.0)
                  : BorderRadius.circular(4.0),
          side:
              secondary
                  ? BorderSide(color: color ?? primarySwatch.shade700)
                  : BorderSide.none,
        ),
      ),
      visualDensity: VisualDensity.compact,
      padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>((
        Set<WidgetState> states,
      ) {
        return const EdgeInsets.all(0);
      }),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (secondary) return colors.white;
        if (states.contains(WidgetState.pressed)) {
          return color != null ? darkenColor(color) : colors.primaryDark;
        }
        return color ?? colors.primary;
      }),
      textStyle: WidgetStateProperty.all<TextStyle>(
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
    child: Container(height: 1, color: const Color.fromRGBO(0, 0, 0, 0.1)),
  );
  static Widget get separatorSmall => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Container(height: 1, color: const Color.fromRGBO(0, 0, 0, 0.1)),
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colors.black.withValues(alpha: 0.1)),
  );
  static BoxDecoration widgetDecoration = BoxDecoration(
    border: Border.all(width: 1.0, color: const Color.fromRGBO(0, 0, 0, 0.1)),
    color: AppTheme.colors.white,
    borderRadius: BorderRadius.circular(16),
  );
  static BorderRadius borderRadius = BorderRadius.circular(16);

  static Widget iconForJournalType(
    JournalType type, [
    BodyPart? bodyPart,
    double size = 48,
  ]) {
    switch (type) {
      case JournalType.musclePain:
        return BodyPartIcon(
          bodyPart: bodyPart ?? BodyPart(BodyPartType.scapula, null),
          size: size,
        );
      case JournalType.neuropathicPain:
        return BodyPartIcon(
          bodyPart: bodyPart ?? BodyPart(BodyPartType.neuropathic, null),
          size: size,
        );
      case JournalType.spasticity:
        return SvgPicture.asset('assets/svg/spasticity.svg', height: size);
      case JournalType.pressureRelease:
        return Icon(Icons.alarm, size: size, color: AppTheme.colors.black);
      case JournalType.pressureUlcer:
        return Icon(
          Icons.album_outlined,
          size: size,
          color: AppTheme.colors.black,
        );
      case JournalType.bladderEmptying:
        return SvgPicture.asset('assets/svg/toilet.svg', height: size);
      case JournalType.bowelEmptying:
        return SvgPicture.asset('assets/svg/bowel.svg', height: size);
      case JournalType.urinaryTractInfection:
        return Icon(Icons.water, size: size, color: AppTheme.colors.black);
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
      case JournalType.selfAssessedPhysicalActivity:
        return Icon(
          Icons.self_improvement,
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

  static bool isBigScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 668;
  }
}

const _shimmerGradient = LinearGradient(
  colors: [Color(0xFFEBEBF4), Color(0xFFF4F4F4), Color(0xFFEBEBF4)],
  stops: [0.1, 0.3, 0.4],
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  tileMode: TileMode.clamp,
);

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return _shimmerGradient.createShader(bounds);
      },
      child: widget.child,
    );
  }
}
