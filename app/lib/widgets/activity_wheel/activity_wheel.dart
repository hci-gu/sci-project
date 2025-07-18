import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/activity_wheel/circle_painter.dart';
import 'package:go_router/go_router.dart';

class ActivityGroup {
  Activity activity;
  List<Energy> energy;

  ActivityGroup(this.activity, this.energy);

  double get value => energy.fold<double>(0, (a, b) => a + b.value);
  int get minutes => energy.fold(0, (a, b) => a + b.minutes);
  int get count => energy.length;
}

List<ActivityGroup> emptyActivityGroups() {
  return [
    ActivityGroup(Activity.sedentary, [Energy(time: DateTime.now(), value: 0)]),
    ActivityGroup(Activity.moving, []),
    ActivityGroup(Activity.active, []),
  ];
}

final activityProvider = FutureProvider<List<ActivityGroup>>((ref) async {
  List<Energy> energy =
      await ref.watch(energyProvider(const Pagination()).future);

  return [Activity.active, Activity.moving, Activity.sedentary]
      .map(
        (activity) => ActivityGroup(
          activity,
          energy.where((e) => e.activity.group == activity.group).toList(),
        ),
      )
      .toList();
});

class ActivityWheel extends ConsumerWidget {
  const ActivityWheel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.goNamed('activity'),
      child: ref.watch(activityProvider).when(
            error: _error,
            loading: _loading,
            data: (data) => _body(context, data),
          ),
    );
  }

  Widget _body(BuildContext context, List<ActivityGroup> activityGroups) {
    bool allEmpty = activityGroups.every((e) => e.energy.isEmpty);
    return _container(
      Row(
        children: [
          AnimatedWheel(
            activityGroups: allEmpty ? emptyActivityGroups() : activityGroups,
          ),
          AppTheme.spacer2x,
          FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: activityGroups
                  .map(
                    (e) => Row(
                      children: [
                        AppTheme.spacer,
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.colors
                                .activityLevelToColor(e.activity),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        AppTheme.spacer,
                        Text(
                          e.activity.displayString(context),
                          style: AppTheme.labelLarge,
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _container(Widget child) {
    return Container(
      decoration: AppTheme.widgetDecoration,
      padding: const EdgeInsets.only(left: 8, right: 24, top: 24, bottom: 24),
      child: child,
    );
  }

  Widget _error(dynamic _, dynamic __) {
    return const Text('Error');
  }

  Widget _loading() {
    return _container(
      const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class AnimatedWheel extends HookWidget {
  final List<ActivityGroup> activityGroups;

  const AnimatedWheel({super.key, required this.activityGroups});

  @override
  Widget build(BuildContext context) {
    final controller =
        useAnimationController(duration: const Duration(milliseconds: 800));

    useEffect(() {
      controller.forward(from: 0);
      return () => controller.reset();
    }, []);

    return SizedBox(
      width: 160,
      height: 100,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: activityGroups
                  .map(
                    (e) => Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          e.value.toStringAsFixed(0),
                          style: TextStyle(
                            height: 0.85,
                            fontSize:
                                28 / MediaQuery.textScalerOf(context).scale(1),
                            fontWeight: FontWeight.w800,
                            color: AppTheme.colors
                                .activityLevelToColor(e.activity),
                          ),
                        ),
                        Text(
                          'kcal',
                          style: AppTheme.labelMedium.copyWith(
                            color: AppTheme.colors
                                .activityLevelToColor(e.activity),
                            fontSize:
                                14 / MediaQuery.textScalerOf(context).scale(1),
                          ),
                        )
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => CustomPaint(
              painter: CirclePainter(
                chartRadius: 60,
                items: activityGroups
                    .map(
                      (e) => CircleChartItem(
                        value: e.minutes.toDouble(),
                        color: AppTheme.colors.activityLevelToColor(e.activity),
                        animationValue: CurvedAnimation(
                                curve: _intervalForActivity(e.activity),
                                parent: controller)
                            .value,
                      ),
                    )
                    .toList(),
                animationValue:
                    CurveTween(curve: Curves.linear).evaluate(controller),
              ),
              size: const Size(120, 120),
            ),
          ),
        ],
      ),
    );
  }

  Interval _intervalForActivity(Activity activity) {
    switch (activity) {
      case Activity.sedentary:
        return const Interval(0, 0.3, curve: Curves.easeInOut);
      case Activity.moving:
        return const Interval(0.4, 0.6, curve: Curves.easeInOut);
      case Activity.active:
      case Activity.weights:
      case Activity.skiErgo:
      case Activity.armErgo:
      case Activity.rollOutside:
        return const Interval(0.7, 1, curve: Curves.easeInOut);
    }
  }
}
