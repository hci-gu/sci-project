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
import 'package:scimovement/widgets/stat_widget.dart';

final _random = new Random();

double randVal() => _random.nextDouble() * 3;
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

List<Bout> mockBoutsForPagination(Pagination pagination) {
  DateTime day = pagination.from(DateTime.now());

  return [
    Bout(
      activity: Activity.moving,
      time: day.add(const Duration(hours: 6, minutes: 30)),
      minutes: 15,
    ),
    Bout(
      activity: Activity.sedentary,
      time: day.add(const Duration(hours: 6, minutes: 45)),
      minutes: 20,
    ),
    Bout(
      activity: Activity.moving,
      time: day.add(const Duration(hours: 7, minutes: 5)),
      minutes: 45,
    ),
    Bout(
      activity: Activity.sedentary,
      time: day.add(const Duration(hours: 7, minutes: 50)),
      minutes: 120,
    ),
    Bout(
      activity: Activity.moving,
      time: day.add(const Duration(hours: 9, minutes: 50)),
      minutes: 10,
    ),
    Bout(
      activity: Activity.sedentary,
      time: day.add(const Duration(hours: 10, minutes: 0)),
      minutes: 120,
    ),
    Bout(
      activity: Activity.active,
      time: day.add(const Duration(hours: 12, minutes: 0)),
      minutes: 60,
    ),
    Bout(
      activity: Activity.sedentary,
      time: day.add(const Duration(hours: 13, minutes: 0)),
      minutes: 60 * 4,
    ),
  ];
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
