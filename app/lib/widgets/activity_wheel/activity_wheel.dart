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

  return Activity.values
      .map(
        (activity) => ActivityGroup(
          activity,
          energy.where((e) => e.activity == activity).toList(),
        ),
      )
      .toList();
});

class ActivityWheel extends ConsumerWidget {
  const ActivityWheel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        String path = GoRouter.of(context).location;
        context.go('$path${path.length > 1 ? '/' : ''}activity');
      },
      child: ref.watch(activityProvider).when(
            error: _error,
            loading: _loading,
            data: _body,
          ),
    );
  }

  Widget _body(List<ActivityGroup> activityGroups) {
    bool allEmpty = activityGroups.every((e) => e.energy.isEmpty);
    return _container(
      Column(
        children: [
          AnimatedWheel(
            activityGroups: allEmpty ? emptyActivityGroups() : activityGroups,
          ),
          AppTheme.spacer2x,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: activityGroups
                .map(
                  (e) => Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              AppTheme.colors.activityLevelToColor(e.activity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      AppTheme.spacer,
                      Text(
                        e.activity.displayString(),
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

  Widget _container(Widget child) {
    return Container(
      decoration: AppTheme.widgetDecoration,
      padding: const EdgeInsets.only(left: 8, right: 24, top: 24, bottom: 24),
      child: child,
    );
  }

  Widget _error(_, __) {
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

  const AnimatedWheel({Key? key, required this.activityGroups})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller =
        useAnimationController(duration: const Duration(milliseconds: 800));

    useEffect(() {
      controller.forward(from: 0);
      return () => controller.reset();
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
            children: activityGroups
                .map(
                  (e) => Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        e.value.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color:
                              AppTheme.colors.activityLevelToColor(e.activity),
                        ),
                      ),
                      Text(
                        'kcal',
                        style: AppTheme.labelMedium.copyWith(
                          color:
                              AppTheme.colors.activityLevelToColor(e.activity),
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
              size: const Size(200, 200),
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
        return const Interval(0.7, 1, curve: Curves.easeInOut);
    }
  }
}
