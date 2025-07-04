import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/home/widgets/pressure_release_widget.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/progress_indicator_around.dart';
import 'package:scimovement/widgets/shake.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class BladderEmptyingWidget extends ConsumerWidget {
  const BladderEmptyingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isToday = ref.watch(isTodayProvider);
    String asset = 'assets/svg/toilet.svg';
    return ref.watch(bladderEmptyingGoalProvider).when(
          data: (goal) => _body(context, goal, isToday),
          error: (_, __) => StatWidget.error(asset),
          loading: () => StatWidget.loading(asset),
        );
  }

  Widget _emptyState(BuildContext context) {
    return StatWidget.container(Column(children: [
      SizedBox(
        width: 150,
        child: Text(
          AppLocalizations.of(context)!.bladderEmptyingCreateGoal,
          style: AppTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
      ),
      SvgPicture.asset('assets/svg/set_goal.svg', height: 56),
      AppTheme.spacer,
      IgnorePointer(
        child: Button(
          width: 140,
          onPressed: () {},
          size: ButtonSize.tiny,
          title: AppLocalizations.of(context)!.getStarted,
        ),
      ),
    ]));
  }

  Widget _body(BuildContext context, JournalGoal? goal, bool isToday) {
    return GestureDetector(
      onTap: () {
        if (goal != null) {
          Duration timeLeft = goal.reminder.difference(DateTime.now());
          if (timeLeft.inMinutes <= 0) {
            context.pushNamed(
              'create-journal',
              extra: {
                'type': JournalType.bladderEmptying,
              },
            );
            return;
          }
        }
        context.goNamed('bladder-emptying');
      },
      child: goal != null
          ? _withGoal(context, goal, isToday)
          : _emptyState(context),
    );
  }

  Widget _oldProgress(BuildContext context, Goal goal) {
    String asset = 'assets/svg/toilet.svg';
    bool finishedGoal = goal.progress >= goal.value;
    return StatWidget.container(
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                SvgPicture.asset(asset, height: 18),
                AppTheme.spacerHalf,
                Text(
                  AppLocalizations.of(context)!.bladderEmptying,
                  style: AppTheme.labelTiny,
                ),
              ],
            ),
            AppTheme.spacer,
            SvgPicture.asset(
                finishedGoal
                    ? 'assets/svg/goal_done.svg'
                    : 'assets/svg/set_goal.svg',
                height: 36),
            AppTheme.spacer,
            GoalProgress(goal: goal)
          ],
        ),
        AppTheme.widgetDecoration.copyWith(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ));
  }

  Widget _withGoal(BuildContext context, Goal goal, bool isToday) {
    if (!isToday) {
      return _oldProgress(context, goal);
    }

    String asset = 'assets/svg/toilet.svg';
    Duration timeLeft = goal.reminder.difference(DateTime.now());

    if (timeLeft.inMinutes <= 0) {
      return StatWidget.container(Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              SvgPicture.asset(asset, height: 18),
              AppTheme.spacerHalf,
              Text(
                AppLocalizations.of(context)!.bladderEmptying,
                style: AppTheme.labelTiny,
              ),
            ],
          ),
          ProgressIndicatorAround(
            size: 50,
            value: 0,
            strokeWidth: 2.5,
            duration: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ShakeWidget(
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 16,
                  ),
                ),
                Text(
                  '00:00',
                  style: AppTheme.labelLarge.copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          AppTheme.spacer,
          SizedBox(
            width: MediaQuery.of(context).size.width / 4,
            child: AutoSizeText(
              AppLocalizations.of(context)!.bladderEmptyingTimeToDoIt,
              textAlign: TextAlign.center,
              style: AppTheme.labelMedium,
              maxLines: 2,
            ),
          ),
        ],
      ));
    }

    return StatWidget.container(Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1),
          ),
          child: Row(
            children: [
              SvgPicture.asset(asset, height: 16),
              AppTheme.spacerHalf,
              Text(
                AppLocalizations.of(context)!.bladderEmptying,
                style: AppTheme.labelTiny,
              ),
            ],
          ),
        ),
        RebuildOnTimer(
          child: TimeUntilGoal(goal: goal),
        ),
        GoalProgress(goal: goal)
      ],
    ));
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

    return ProgressIndicatorAround(
      size: 50,
      value: timeLeft.inMinutes / goal.recurrence.inMinutes,
      strokeWidth: 2.5,
      duration: 1,
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
