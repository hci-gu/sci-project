import 'package:scimovement/api.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/widgets/charts/utils/chart_data.dart';

final energyBarChartProvider =
    FutureProvider.family<ChartData, Pagination>((ref, pagination) async {
  List<Energy> energy = await ref.watch(energyProvider(pagination).future);

  return ChartData(
    energy.map((e) => ChartDataPoint(e.time, e.value, e.activity)).toList(),
    ref.watch(paginationProvider).mode,
  );
});

final activityBarChartProvider =
    FutureProvider.family<ChartData, Pagination>((ref, pagination) async {
  List<Energy> energy = await ref.watch(energyProvider(pagination).future);

  return ChartData(
    energy
        .map((e) => ChartDataPoint(e.time, e.minutes.toDouble(), e.activity))
        .toList(),
    ref.watch(paginationProvider).mode,
  );
});

final sedentaryBarChartProvider =
    FutureProvider.family<ChartData, Pagination>((ref, pagination) async {
  List<Bout> bouts = await ref.watch(boutsProvider(pagination).future);

  return ChartData(
    bouts
        .where((e) => e.activity == Activity.sedentary)
        .map((e) => ChartDataPoint(e.time, e.minutes.toDouble(), e.activity))
        .toList(),
    ref.watch(paginationProvider).mode,
  );
});

double _valueForActivity(Activity activity) {
  switch (activity) {
    case Activity.sedentary:
      return 0;
    case Activity.moving:
      return 1;
    case Activity.active:
      return 2;
  }
}

final activityLineChartProvider =
    FutureProvider.family<ChartData, Pagination>((ref, pagination) async {
  List<Bout> bouts = await ref.watch(boutsProvider(pagination).future);

  List<ChartDataPoint> data = [];
  for (Bout bout in bouts) {
    DateTime time = bout.time;
    for (var i = 0; i < bout.minutes; i++) {
      data.add(ChartDataPoint(
        time.add(Duration(minutes: i)),
        _valueForActivity(bout.activity),
        bout.activity,
      ));
    }
  }

  return ChartData(data, ChartMode.day);
});