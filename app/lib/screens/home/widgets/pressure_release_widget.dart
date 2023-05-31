import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/home/widgets/pressure_ulcer_widget.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:go_router/go_router.dart';

class GoalProgress extends StatelessWidget {
  final Goal goal;

  const GoalProgress({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${goal.progress}/${goal.value}',
              style: AppTheme.labelLarge.copyWith(fontSize: 12),
            ),
            Text(
              ' Av dagens mål',
              style: AppTheme.paragraphSmall.copyWith(fontSize: 10),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppTheme.colors.black.withOpacity(0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          width: 100,
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: goal.progress / goal.value,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}

class PressureReleaseWidget extends ConsumerWidget {
  const PressureReleaseWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination pagination = ref.watch(paginationProvider);
    String asset = 'assets/svg/alarm.svg';
    return ref.watch(journalGoalProvider(pagination)).when(
          data: (goal) => _body(context, goal),
          error: (_, __) => StatWidget.error(asset),
          loading: () => StatWidget.loading(asset),
        );
  }

  Widget _emptyState(BuildContext context) {
    return StatWidget.container(
      Column(children: [
        SizedBox(
          width: 150,
          child: Text(
            'Skapa ett mål för tryckavlastning',
            style: AppTheme.labelLarge,
            textAlign: TextAlign.center,
          ),
        ),
        SvgPicture.asset('assets/svg/set_goal.svg', height: 56),
        AppTheme.spacer,
        Button(
          width: 140,
          onPressed: () {},
          size: ButtonSize.tiny,
          title: 'Sätt igång',
        ),
      ]),
      AppTheme.widgetDecoration.copyWith(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, JournalGoal? goal) {
    String asset = 'assets/svg/alarm.svg';
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            String path = GoRouter.of(context).location;
            context.go('$path${path.length > 1 ? '/' : ''}pressure-release');
          },
          child: goal != null
              ? StatWidget.container(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(asset, height: 18),
                          AppTheme.spacerHalf,
                          Text('Tryckavlastning', style: AppTheme.labelTiny),
                        ],
                      ),
                      TimeUntilGoal(goal: goal),
                      RebuildOnTimer(
                        duration: const Duration(seconds: 2),
                        child: GoalProgress(goal: goal),
                      )
                    ],
                  ),
                  AppTheme.widgetDecoration.copyWith(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ))
              : _emptyState(context),
        ),
        AppTheme.spacerHalf,
        const PressureUlcerWidget(),
      ],
    );
  }
}

class TimeUntilGoal extends StatelessWidget {
  final Goal goal;
  const TimeUntilGoal({
    super.key,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    Duration timeLeft = goal.reminder.difference(DateTime.now());
    timeLeft.isNegative ? timeLeft = Duration.zero : timeLeft = timeLeft;

    String timerText =
        '${timeLeft.inHours.toString().padLeft(2, '0')}:${timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    if (timeLeft.inHours == 0) {
      timerText =
          '${timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}:${timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }

    print(timerText);

    return Container(
      padding: EdgeInsets.all(AppTheme.basePadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppTheme.colors.black.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            timerText,
            style: AppTheme.labelLarge.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_none,
                size: 8,
              ),
              Text(
                DateFormat(DateFormat.HOUR24_MINUTE).format(goal.reminder),
                style: AppTheme.paragraphSmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RebuildOnTimer extends HookWidget {
  final Widget child;
  final Duration duration;

  const RebuildOnTimer({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 1),
  });

  @override
  Widget build(BuildContext context) {
    var state = useState(DateTime.now());

    useEffect(() {
      Timer timer = Timer.periodic(duration, (_) {
        state.value = DateTime.now();
      });
      return () => timer.cancel();
    }, []);

    return Container(key: UniqueKey(), child: child);
  }
}
