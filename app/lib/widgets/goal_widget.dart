import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GoalWidget extends StatelessWidget {
  final Goal goal;
  const GoalWidget({required this.goal, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      height: 80,
      padding: EdgeInsets.all(AppTheme.basePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: AppTheme.colors.primary,
                    ),
                    child: Center(
                      child: Text(
                        '${goal.progress}/${goal.value}',
                        style: AppTheme.labelTiny.copyWith(
                          color: AppTheme.colors.white,
                        ),
                      ),
                    ),
                  ),
                  AppTheme.spacer,
                  SizedBox(
                    width: 180,
                    child: AutoSizeText(
                      _goalText(context, goal),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border:
                      Border.all(color: AppTheme.colors.black.withOpacity(0.1)),
                ),
                clipBehavior: Clip.none,
                width: 200,
                height: 8,
                child: LinearProgressIndicator(
                  value: goal.progress / goal.value,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
          Button(
            width: 100,
            title: AppLocalizations.of(context)!.editGoal,
            size: ButtonSize.small,
            onPressed: () => context.goNamed('edit-goal', extra: {
              'goal': goal,
            }),
          )
        ],
      ),
    );
  }

  String _goalText(BuildContext context, Goal goal) {
    int amountLeft = goal.value - goal.progress;
    bool goalFinished = amountLeft <= 0;

    if (goalFinished) {
      return AppLocalizations.of(context)!.reachedGoalMessage;
    }
    String pressureRelease = amountLeft == 1
        ? AppLocalizations.of(context)!.pressureRelease
        : AppLocalizations.of(context)!.pressureReleases;

    return '$amountLeft $pressureRelease ${AppLocalizations.of(context)!.leftToReachGoalMessage}';
  }
}
