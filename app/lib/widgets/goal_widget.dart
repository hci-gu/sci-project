import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';

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
                  const Text(
                    '4 avlastningar kvar för att nå\n ditt dagliga mål.',
                    maxLines: 2,
                  )
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
            title: 'Ändra mål',
            size: ButtonSize.small,
            onPressed: () => context.goNamed('edit-goal', extra: {
              'goal': goal,
            }),
          )
        ],
      ),
    );
  }
}
