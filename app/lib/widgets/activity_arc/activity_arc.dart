import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/theme/theme.dart';

class ActivityArc extends ConsumerWidget {
  final List<Bout> bouts;
  final List<Activity> activities;

  const ActivityArc({
    required this.bouts,
    this.activities = Activity.values,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShaderMask(
      shaderCallback: (Rect rect) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.purple,
            Colors.transparent,
            Colors.transparent,
            Colors.purple
          ],
          stops: [0.0, 0.04, 0.96, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: Container(
        height: 80,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: ArcPainter(
                bouts: bouts,
                activities: activities,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final List<Bout> bouts;
  final List<Activity> activities;

  ArcPainter({required this.bouts, this.activities = Activity.values});

  final _textPainter = TextPainter(textDirection: TextDirection.ltr);

  @override
  void paint(Canvas canvas, Size size) {
    Rect drawRect = Rect.fromLTRB(
        -size.width / 4, 10, size.width * 1.25, size.width * 2 + 10);
    double offset = -pi + pi / 4;

    for (Activity activity in activities) {
      canvas.drawArc(
        _rectForActivity(activity, drawRect),
        offset,
        24 * 60 * pi / 2 / 1440,
        false,
        Paint()
          ..color = activities.length == 1
              ? AppTheme.colors.black.withOpacity(0.4)
              : AppTheme.colors.activityLevelToColor(activity).withOpacity(0.33)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    for (Bout bout in bouts) {
      double minute = bout.time.hour * 60.0 + bout.time.minute;
      double start = minute * pi / 2 / 1440;

      Rect rect = _rectForActivity(bout.activity, drawRect);

      canvas.drawArc(
        rect,
        offset + start - 0.003,
        bout.minutes * pi / 2 / 1440 + 0.006,
        false,
        Paint()
          ..color = AppTheme.colors.black
          ..strokeWidth = 17
          ..style = PaintingStyle.stroke,
      );
      canvas.drawArc(
        rect,
        offset + start,
        bout.minutes * pi / 2 / 1440,
        false,
        Paint()
          ..color = AppTheme.colors.activityLevelToColor(bout.activity)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke,
      );
    }
    _paintText(canvas, size, '06:00', _timeOffset(6 * 60, size.width));
    _paintText(canvas, size, '12:00', _timeOffset(12 * 60, size.width));
    _paintText(canvas, size, '18:00', _timeOffset(18 * 60, size.width));
  }

  Rect _rectForActivity(Activity activity, Rect rect) {
    if (activities.length == 1) {
      return rect;
    }

    switch (activity) {
      case Activity.sedentary:
        return rect.deflate(40);
      case Activity.moving:
        return rect.deflate(20);
      case Activity.active:
      default:
        return rect;
    }
  }

  double _timeOffset(double minutes, double width) {
    return 16 + minutes * width / 1440;
  }

  _paintText(Canvas canvas, Size size, String text, double offset) {
    _textPainter.text = TextSpan(text: text, style: AppTheme.paragraphSmall);
    _textPainter.layout(
      minWidth: 0,
      maxWidth: double.maxFinite,
    );
    _textPainter.paint(canvas,
        Offset(offset - _textPainter.width, size.height - _textPainter.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
