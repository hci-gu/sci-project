import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_circle_chart/flutter_circle_chart.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/activity.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/circle_painter.dart';

class Activity {
  ActivityLevel level;
  List<Energy> energy;

  Activity(this.level, this.energy);

  double get value => energy.fold<double>(0, (a, b) => a + b.value);
  int get count => energy.length;
}

final activityProvider = FutureProvider<List<Activity>>((ref) async {
  List<Energy> energy =
      await ref.watch(energyProvider(const Pagination()).future);

  return ActivityLevel.values
      .map(
        (level) => Activity(
          level,
          energy.where((e) => e.activityLevel == level).toList(),
        ),
      )
      .toList();
});

class ActivityWheel extends ConsumerWidget {
  const ActivityWheel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(activityProvider).when(
          error: _error,
          loading: _loading,
          data: _body,
        );
  }

  Widget _body(List<Activity> levels) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color.fromRGBO(0, 0, 0, 0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.only(left: 8, right: 24, top: 24, bottom: 24),
      child: Column(
        children: [
          AnimatedWheel(levels: levels),
          AppTheme.spacer,
          AppTheme.spacer,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: levels
                .map(
                  (e) => Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.colors.activityLevelToColor(e.level),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      AppTheme.spacer,
                      Text(
                        e.level.name,
                        style: AppTheme.labelLarge,
                      ),
                    ],
                  ),
                )
                .toList(),
          )
        ],
      ),
    );
  }

  Widget _error(_, __) {
    return const Text('Error');
  }

  Widget _loading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class AnimatedWheel extends HookWidget {
  final List<Activity> levels;

  const AnimatedWheel({Key? key, required this.levels}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller =
        useAnimationController(duration: const Duration(milliseconds: 800));

    useEffect(() {
      controller.forward(from: 0.1);
      return () => {};
      // return () => controller.reset();
    }, []);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: levels
                .map(
                  (e) => Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        e.value.toStringAsFixed(0),
                        style: AppTheme.headLine2.copyWith(
                          color: AppTheme.colors.activityLevelToColor(e.level),
                        ),
                      ),
                      Text(
                        'kcal',
                        style: AppTheme.labelTiny.copyWith(
                          color: AppTheme.colors.activityLevelToColor(e.level),
                        ),
                      )
                    ],
                  ),
                )
                .toList(),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => CustomPaint(
              painter: CirclePainter(
                chartRadius: 100,
                items: levels
                    .map(
                      (e) => CircleChartItem(
                        value: e.count.toDouble(),
                        color: AppTheme.colors.activityLevelToColor(e.level),
                        animationValue: CurvedAnimation(
                                curve: _intervalForActivityLevel(e.level),
                                parent: controller)
                            .value,
                      ),
                    )
                    .toList(),
                animationValue:
                    CurveTween(curve: Curves.linear).evaluate(controller),
              ),
              size: const Size(200, 200),
            ),
          ),
        ],
      ),
    );
  }

  Interval _intervalForActivityLevel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return const Interval(0, 0.3, curve: Curves.easeInCubic);
      case ActivityLevel.movement:
        return const Interval(0.4, 0.6, curve: Curves.easeInCubic);
      case ActivityLevel.active:
        return const Interval(0.7, 1, curve: Curves.easeInCubic);
    }
  }
}