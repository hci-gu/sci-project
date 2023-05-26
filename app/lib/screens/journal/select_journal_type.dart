import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/theme/theme.dart';

class SelectJournalTypeScreen extends StatelessWidget {
  // const SelectJournalTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.appBar('Ny loggning'),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.basePadding * 3,
          vertical: AppTheme.basePadding * 3,
        ),
        children: [
          Text(
            'Vad vill du registrera?',
            style: AppTheme.headLine3,
          ),
          Text(
            'Välj en utav de kategorier du ser nedanför',
            style: AppTheme.paragraphMedium,
          ),
          AppTheme.spacer2x,
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.basePadding * 4,
            mainAxisSpacing: AppTheme.basePadding * 4,
            shrinkWrap: true,
            children: [
              GestureDetector(
                onTap: () =>
                    GoRouter.of(context).goNamed('create-journal', extra: {
                  'type': JournalType.pain,
                }),
                child: Container(
                  decoration: AppTheme.widgetDecoration,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BodyPartIcon(
                          bodyPart: BodyPart(BodyPartType.scapula, null),
                          size: 48,
                        ),
                        AppTheme.spacer,
                        Text(
                          'Smärta i muskler och leder',
                          style: AppTheme.labelMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    GoRouter.of(context).goNamed('create-journal', extra: {
                  'type': JournalType.pressureRelease,
                }),
                child: Container(
                  decoration: AppTheme.widgetDecoration,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_alarm,
                          size: 48,
                        ),
                        AppTheme.spacer,
                        Text(
                          'Tryckavlastning',
                          style: AppTheme.labelMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
