import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class GoalWidget extends StatelessWidget {
  final Goal goal;
  final JournalType type;

  const GoalWidget({required this.goal, required this.type, super.key});

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
                    width: 30 * MediaQuery.of(context).textScaleFactor,
                    height: 30 * MediaQuery.of(context).textScaleFactor,
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
                  border: Border.all(
                    color: AppTheme.colors.black.withOpacity(0.1),
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                width: 200,
                height: 8,
                child: LinearProgressIndicator(
                  value: goal.progress / goal.value,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
          Expanded(
            child: Button(
              width: 100,
              title: AppLocalizations.of(context)!.editGoal,
              size: ButtonSize.small,
              onPressed: () {
                String path = GoRouter.of(context).location;

                context.go('$path/goal', extra: {
                  'goal': goal,
                  'type': type,
                });
              },
            ),
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
    String description = type == JournalType.pressureRelease
        ? amountLeft == 1
            ? AppLocalizations.of(context)!.pressureRelease
            : AppLocalizations.of(context)!.pressureReleases
        : amountLeft == 1
            ? AppLocalizations.of(context)!.bladderEmptying
            : AppLocalizations.of(context)!.bladderEmptyings;

    return '$amountLeft $description ${AppLocalizations.of(context)!.leftToReachGoalMessage}';
  }
}
