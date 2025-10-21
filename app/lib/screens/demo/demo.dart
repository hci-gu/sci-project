import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/exercise_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/charts/energy_line_chart.dart';

final _random = Random();
double randVal() => _random.nextDouble() * 2;
List<Energy> mockEnergyFrom(DateTime time, int count, Activity activity) {
  return List.generate(
    count,
    (index) => Energy(
      time: time.add(Duration(minutes: index)),
      value: activity != Activity.sedentary ? randVal() : 0,
      activity: activity,
    ),
  );
}

List<Energy> mockEnergyFromBouts(Pagination pagination, List<Bout> bouts) {
  List<Energy> energy = [];

  for (Bout bout in bouts) {
    if (pagination.mode == ChartMode.day) {
      energy.addAll(mockEnergyFrom(bout.time, bout.minutes, bout.activity));
    } else {
      energy.add(
        Energy(
          time: bout.time,
          value:
              bout.activity != Activity.sedentary
                  ? randVal() * bout.minutes
                  : 0,
          minutes: bout.minutes,
          activity: bout.activity,
        ),
      );
    }
  }
  return energy;
}

int durationForActivity(Activity activity) {
  if (activity == Activity.sedentary) {
    return 10 + _random.nextInt(240);
  }
  return 10 + _random.nextInt(60);
}

Map<int, List<Bout>> boutCache = {};
List<Bout> mockBoutsForPagination(Pagination pagination) {
  List<Bout> bouts = [];
  switch (pagination.mode) {
    case ChartMode.day:
      DateTime day = pagination.from;
      List<Activity> activities = [
        Activity.moving,
        Activity.sedentary,
        Activity.moving,
        Activity.sedentary,
        Activity.moving,
        Activity.sedentary,
        Activity.active,
        Activity.sedentary,
        Activity.moving,
        Activity.sedentary,
      ];
      int start = 60 * 6 + 30;
      for (Activity activity in activities) {
        int minutes = durationForActivity(activity);
        bouts.add(
          Bout(
            id: -1,
            time: day.add(Duration(minutes: start)),
            minutes: minutes,
            activity: activity,
          ),
        );
        start += minutes;
      }
      break;
    case ChartMode.week:
    case ChartMode.month:
      DateTime from = pagination.from;
      DateTime to = pagination.to;
      int days = to.difference(from).inDays + 1;

      for (int i = 0; i < days; i++) {
        DateTime day = from.add(Duration(days: i));

        bouts.addAll([
          Bout(
            id: -1,
            activity: Activity.sedentary,
            time: day,
            minutes: 60 * (5 + _random.nextInt(5)),
          ),
          Bout(
            id: -1,
            activity: Activity.moving,
            time: day,
            minutes: 60 * (2 + _random.nextInt(3)),
          ),
          if (_random.nextBool())
            Bout(id: -1, activity: Activity.active, time: day, minutes: 45),
        ]);
      }
      break;
    case ChartMode.year:
      DateTime from = pagination.from;
      for (int i = 0; i < 12; i++) {
        DateTime day = from.add(Duration(days: i * 30));
        bouts.addAll([
          Bout(
            id: -1,
            activity: Activity.sedentary,
            time: day,
            minutes: 60 * (5 + _random.nextInt(5)) * 30,
          ),
          Bout(
            id: -1,
            activity: Activity.moving,
            time: day,
            minutes: 60 * (2 + _random.nextInt(3)) * 30,
          ),
          if (_random.nextBool())
            Bout(
              id: -1,
              activity: Activity.active,
              time: day,
              minutes: 45 * 30,
            ),
        ]);
      }
      break;
    default:
  }
  // boutCache[pagination.page] = bouts;

  return bouts;
}

class DemoWrapper extends ConsumerWidget {
  final Widget child;

  const DemoWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        userProvider.overrideWith(
          (ref) => UserState.fromMockUser(
            User(
              id: 'abc-123',
              email: 'demo@email.com',
              notificationSettings: NotificationSettings(),
            ),
          ),
        ),
        energyProvider.overrideWithProvider(
          (argument) => FutureProvider<List<Energy>>((ref) async {
            List<Bout> bouts = mockBoutsForPagination(argument);
            return mockEnergyFromBouts(argument, bouts);
          }),
        ),
        boutsProvider.overrideWithProvider(
          (argument) => FutureProvider<List<Bout>>((ref) async {
            return mockBoutsForPagination(argument);
          }),
        ),
        excerciseBoutsProvider.overrideWithProvider(
          (argument) => FutureProvider<List<Bout>>((ref) async {
            return [
              Bout(
                activity: Activity.weights,
                minutes: 30,
                time: DateTime.now(),
                id: 1,
              ),
            ];
          }),
        ),
        journalProvider.overrideWith(
          (ref, _) => [
            PressureUlcerEntry(
              id: 0,
              time: DateTime.now().subtract(Duration(days: 6)),
              type: JournalType.pressureUlcer,
              comment: '',
              pressureUlcerType: PressureUlcerType.category2,
              location: PressureUlcerLocation.ancle,
            ),
          ],
        ),
        journalMonthlyProvider.overrideWith((ref, _) => []),
        journalForDayProvider.overrideWith((ref, _) => []),
        pressureUlcerProvider.overrideWith(
          (ref) => [
            PressureUlcerEntry(
              id: 0,
              time: DateTime.now().subtract(Duration(days: 6)),
              type: JournalType.pressureUlcer,
              comment: '',
              pressureUlcerType: PressureUlcerType.category2,
              location: PressureUlcerLocation.ancle,
            ),
          ],
        ),
        neuroPathicPainAndSpasticityProvider.overrideWith(
          (ref) => [
            PainLevelEntry(
              id: 0,
              time: DateTime.now(),
              type: JournalType.neuropathicPain,
              painLevel: 4,
              comment: '',
              bodyPart: BodyPart(BodyPartType.neuropathic, null),
            ),
          ],
        ),
        utiProvider.overrideWith((ref) => null),
        pressureReleaseCountProvider.overrideWith((ref, arg) => 0),
        bladderEmptyingCountProvider.overrideWith((ref, arg) => 0),
        movementBarChartProvider,
        notificationsEnabledProvider.overrideWithValue(false),
        userHasDataProvider.overrideWithValue(true),
        goalsProvider.overrideWith(
          (ref) => [
            JournalGoal(
              id: 0,
              value: 8,
              progress: 2,
              reminder: DateTime.now().add(const Duration(hours: 1)),
              start: Duration.zero,
              recurrence: const Duration(hours: 1),
              type: JournalType.pressureRelease,
            ),
            JournalGoal(
              id: 1,
              value: 6,
              progress: 4,
              reminder: DateTime.now().add(const Duration(minutes: 30)),
              start: Duration.zero,
              recurrence: const Duration(hours: 1),
              type: JournalType.bladderEmptying,
            ),
          ],
        ),
        exerciseWidgetProvider,
        averageSedentaryBout,
        totalEnergyProvider,
        averageEnergyProvider,
        energyWidgetProvider,
        sedentaryWidgetProvider,
        activityProvider,
        energyBarChartProvider,
        activityBarChartProvider,
        sedentaryBarChartProvider,
        energyChartProvider,
        dailyEnergyChartProvider,
        totalMovementMinutesProvider,
        averageMovementMinutesProvider,
        uniqueEntriesProvider,
        updateJournalProvider,
        // connectedWatchProvider.overrideWith((ref) {

        // }),
      ],
      child: child,
    );
  }
}
