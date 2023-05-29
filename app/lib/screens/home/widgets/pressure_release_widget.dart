import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/theme/theme.dart';
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
              style: AppTheme.labelLarge,
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
          clipBehavior: Clip.none,
          width: 100,
          height: 8,
          child: LinearProgressIndicator(
            value: goal.progress / goal.value,
            backgroundColor: Colors.transparent,
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
    String asset = 'assets/svg/alarm.svg';
    return ref.watch(journalGoalProvider(JournalType.pressureRelease)).when(
          data: (goal) => _body(context, goal),
          error: (_, __) => StatWidget.error(asset),
          loading: () => StatWidget.loading(asset),
        );
  }

  Widget _body(BuildContext context, JournalGoal? goal) {
    String asset = 'assets/svg/alarm.svg';
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            String path = GoRouter.of(context).location;
            context.go('$path${path.length > 1 ? '/' : ''}sedentary');
          },
          child: StatWidget.container(
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(asset, height: 24),
                      AppTheme.spacerHalf,
                      Text('Tryckavlastning', style: AppTheme.labelTiny),
                    ],
                  ),
                  Container(
                    height: 44,
                    width: 44,
                    color: Colors.amber,
                  ),
                  if (goal != null) GoalProgress(goal: goal)
                ],
              ),
              AppTheme.widgetDecoration.copyWith(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              )),
        ),
        AppTheme.spacerHalf,
        GestureDetector(
          onTap: () {
            context.goNamed('create-journal', extra: {
              'type': JournalType.pressureUlcer,
            });
          },
          child: AspectRatio(
            aspectRatio: 3,
            child: Container(
              decoration: AppTheme.widgetDecoration.copyWith(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            AppTheme.spacerHalf,
                            Text('Inget trycksår', style: AppTheme.labelLarge),
                          ],
                        ),
                        Text('Sedan 12 dagar tillbaka',
                            style: AppTheme.paragraphSmall),
                      ],
                    ),
                    Icon(Icons.edit_outlined)
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
