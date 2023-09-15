import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/theme/theme.dart';

class ActivityArc extends HookWidget {
  final List<Bout> bouts;
  final List<JournalEntry> journalEntries;
  final List<Activity> activities;

  const ActivityArc({
    required this.bouts,
    this.journalEntries = const [],
    this.activities = const [
      Activity.active,
      Activity.moving,
      Activity.sedentary
    ],
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final offsetAnimation = useAnimationController(
      duration: const Duration(milliseconds: 400),
      initialValue: _offsetForCurrentTime(width),
      lowerBound: 0,
      upperBound: width,
    );

    double offset = useAnimation(offsetAnimation);

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
          stops: [0.0, 0.02, 0.98, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: ArcPainter(
                deviceWidth: width,
                bouts: bouts,
                activities: activities,
                journalEntries: journalEntries,
                dragOffset: offset,
              ),
            ),
            CustomPaint(
              size: const Size(1, 0),
              painter: ClockPainter(offset),
            ),
            Positioned(
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  offsetAnimation.value = details.globalPosition.dx;
                },
                onHorizontalDragEnd: (_) {
                  offsetAnimation.animateTo(_offsetForCurrentTime(width));
                },
                child: Container(
                  color: Colors.transparent,
                  width: MediaQuery.of(context).size.width,
                  height: 44,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  double _offsetForCurrentTime(double width) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final minutesSinceMidnight = now.difference(midnight).inMinutes;

    return width * minutesSinceMidnight / 1440;
  }
}

class ArcPainter extends CustomPainter {
  final List<Bout> bouts;
  final List<Activity> activities;
  final List<JournalEntry> journalEntries;
  final double dragOffset;
  final double deviceWidth;

  ArcPainter({
    required this.bouts,
    required this.deviceWidth,
    this.journalEntries = const [],
    this.activities = Activity.values,
    this.dragOffset = 0.0,
  });

  final _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  @override
  void paint(Canvas canvas, Size size) {
    Rect drawRect = Rect.fromLTRB(
        -size.width / 4, 24, size.width * 1.25, size.width * 2 + 10);
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

    for (JournalEntry entry in journalEntries) {
      double minute = entry.time.hour * 60.0 + entry.time.minute;
      double start = minute * pi / 2 / 1440;

      Rect rect = drawRect.inflate(24);
      canvas.drawArc(
        rect,
        offset + start,
        6 * pi / 2 / 1440 + 0.006,
        false,
        Paint()
          ..color = AppTheme.colors.success
          ..strokeWidth = 16
          ..style = PaintingStyle.stroke,
      );
    }

    for (Bout bout in bouts) {
      double minute = bout.time.hour * 60.0 + bout.time.minute;
      double start = minute * pi / 2 / 1440;

      Rect rect = _rectForActivity(bout.activity, drawRect);

      if (bout.activity.isExercise) {
        canvas.drawArc(
          rect,
          offset + start - 0.003,
          (bout.minutes - 1) * pi / 2 / 1440 + 0.006,
          false,
          Paint()
            ..color = AppTheme.colors.black
            ..strokeWidth = 7
            ..style = PaintingStyle.stroke,
        );
        canvas.drawArc(
          rect,
          offset + start,
          (bout.minutes - 1) * pi / 2 / 1440,
          false,
          Paint()
            ..color = AppTheme.colors.exercise
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke,
        );
        continue;
      }

      canvas.drawArc(
        rect,
        offset + start - 0.003,
        (bout.minutes - 1) * pi / 2 / 1440 + 0.006,
        false,
        Paint()
          ..color = AppTheme.colors.black
          ..strokeWidth = 17
          ..style = PaintingStyle.stroke,
      );
      canvas.drawArc(
        rect,
        offset + start,
        (bout.minutes - 1) * pi / 2 / 1440,
        false,
        Paint()
          ..color = AppTheme.colors.activityLevelToColor(bout.activity)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke,
      );
    }
    _paintText(canvas, size, '04:00', _timeOffset(4 * 60, size.width));
    _paintText(canvas, size, '08:00', _timeOffset(8 * 60, size.width));
    _paintText(canvas, size, '12:00', _timeOffset(12 * 60, size.width));
    _paintText(canvas, size, '16:00', _timeOffset(16 * 60, size.width));
    _paintText(canvas, size, '20:00', _timeOffset(20 * 60, size.width));

    if (dragOffset != 0) {
      _painCenterText(canvas, size, _timeAtOffset(dragOffset));
    }
  }

  Rect _rectForActivity(Activity activity, Rect rect) {
    if (activities.length == 1) {
      return rect;
    }

    if (activity.isExercise) {
      return rect.inflate(20);
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

  String _timeAtOffset(double offset) {
    DateTime timestamp = DateTime(2021, 1, 1, 0, offset * 1440 ~/ deviceWidth);
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  _paintText(Canvas canvas, Size size, String text, double offset) {
    _textPainter.text = TextSpan(
      text: text,
      style: AppTheme.paragraphSmall,
    );
    _textPainter.layout(
      minWidth: 10,
      maxWidth: 100,
    );
    _textPainter.paint(canvas,
        Offset(offset - _textPainter.width, size.height - _textPainter.height));
  }

  _painCenterText(Canvas canvas, Size size, String text) {
    _textPainter.text = TextSpan(
      text: text,
      style: AppTheme.labelXLarge,
    );
    _textPainter.layout(
      minWidth: 1,
      maxWidth: 100,
    );
    _textPainter.paint(
        canvas,
        Offset(
          size.width / 2 - _textPainter.width / 2,
          size.height - _textPainter.height - 32,
        ));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ClockPainter extends CustomPainter {
  final double offset;

  ClockPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    Rect drawRect = Rect.fromLTRB(
        -size.width / 4, 54, size.width * 1.25, size.width * 2 + 10);
    double circleOffset = -pi + pi / 4;

    double start = _offsetToMinutes(offset, size.width) * pi / 2 / 1440;

    canvas.drawArc(
      drawRect,
      circleOffset + start,
      (pi * 3) / 1440,
      false,
      Paint()
        ..color = AppTheme.colors.black
        ..strokeWidth = 110
        ..style = PaintingStyle.stroke,
    );
  }

  double _offsetToMinutes(double offset, double width) {
    return (offset - 16) * 1440 / width;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
