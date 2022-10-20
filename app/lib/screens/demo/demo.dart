import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/screens/home/widgets/energy_widget.dart';
import 'package:scimovement/screens/home/widgets/sedentary_widget.dart';
import 'package:scimovement/widgets/activity_wheel/activity_wheel.dart';
import 'package:scimovement/widgets/charts/energy_line_chart.dart';

final _random = Random();
double randVal() => _random.nextDouble() * 2.5;
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

List<Energy> mockEnergyFromBouts(List<Bout> bouts) {
  List<Energy> energy = [];

  for (Bout bout in bouts) {
    energy.addAll(mockEnergyFrom(bout.time, bout.minutes, bout.activity));
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
  if (pagination.mode == ChartMode.day) {
    DateTime day = pagination.from(DateTime.now());
    List<Activity> activities = [
      Activity.moving,
      Activity.sedentary,
      Activity.moving,
      Activity.sedentary,
      Activity.moving,
      Activity.sedentary,
      _random.nextBool() ? Activity.active : Activity.moving,
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
          ),
        )),
        energyProvider.overrideWithProvider(
          (argument) => FutureProvider<List<Energy>>(
            (ref) async {
              List<Bout> bouts = mockBoutsForPagination(argument);
              return mockEnergyFromBouts(bouts);
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
        energyChartProvider,
        dailyEnergyChartProvider,
        totalMovementMinutesProvider,
        averageMovementMinutesProvider,
      ],
      child: Scaffold(
        body: child,
      ),
    );
  }
}
