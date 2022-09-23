import 'package:scimovement/api.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  List<Energy> energy = await ref.watch(energyProvider(pagination).future);

  return ChartData(
    energy
        .where((e) => e.activity == Activity.sedentary)
        .map((e) => ChartDataPoint(e.time, e.minutes.toDouble(), e.activity))
        .toList(),
    ref.watch(paginationProvider).mode,
  );
});
