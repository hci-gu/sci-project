import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
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
          value: bout.activity != Activity.sedentary
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
      DateTime day = pagination.from(DateTime.now());
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
        bouts.add(Bout(
          time: day.add(Duration(minutes: start)),
          minutes: minutes,
          activity: activity,
        ));
        start += minutes;
      }
      break;
    case ChartMode.week:
    case ChartMode.month:
      DateTime from = pagination.from(DateTime.now());
      DateTime to = pagination.to(DateTime.now());
      int days = to.difference(from).inDays + 1;

      for (int i = 0; i < days; i++) {
        DateTime day = from.add(Duration(days: i));

        bouts.addAll([
          Bout(
              activity: Activity.sedentary,
              time: day,
              minutes: 60 * (5 + _random.nextInt(5))),
          Bout(
              activity: Activity.moving,
              time: day,
              minutes: 60 * (2 + _random.nextInt(3))),
          if (_random.nextBool())
            Bout(activity: Activity.active, time: day, minutes: 45),
        ]);
      }
      break;
    case ChartMode.year:
      DateTime from = pagination.from(DateTime.now());
      for (int i = 0; i < 12; i++) {
        DateTime day = from.add(Duration(days: i * 30));
        bouts.addAll([
          Bout(
            activity: Activity.sedentary,
            time: day,
            minutes: 60 * (5 + _random.nextInt(5)) * 30,
          ),
          Bout(
            activity: Activity.moving,
            time: day,
            minutes: 60 * (2 + _random.nextInt(3)) * 30,
          ),
          if (_random.nextBool())
            Bout(activity: Activity.active, time: day, minutes: 45 * 30),
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

  const DemoWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        userProvider.overrideWithValue(UserState.fromMockUser(
          User(
            id: 'abc-123',
            email: 'demo@email.com',
            notificationSettings: NotificationSettings(),
          ),
        )),
        energyProvider.overrideWithProvider(
          (argument) => FutureProvider<List<Energy>>(
            (ref) async {
              List<Bout> bouts = mockBoutsForPagination(argument);
              return mockEnergyFromBouts(argument, bouts);
            },
          ),
        ),
        boutsProvider.overrideWithProvider(
          (argument) => FutureProvider<List<Bout>>(
            (ref) async {
              return mockBoutsForPagination(argument);
            },
          ),
        ),
        notificationsEnabledProvider.overrideWithValue(false),
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
        userHasDataProvider.overrideWithValue(true),
      ],
      child: Scaffold(
        body: child,
      ),
    );
  }
}
