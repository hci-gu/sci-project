import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/pagination.dart';

final energyProvider =
    FutureProvider.family<List<Energy>, Pagination>((ref, pagination) async {
  DateTime date = ref.watch(dateProvider);
  Pagination page = Pagination(
    page: pagination.page,
    mode: pagination.mode,
    overrideDate: date,
  );

  List<Energy> energy = await Api().getEnergy(
    page.from,
    page.to,
    page.mode,
  );
  return energy;
});

final totalEnergyProvider =
    FutureProvider.family<int, Pagination>((ref, pagination) async {
  List<Energy> energy = await ref.watch(energyProvider(pagination).future);
  return energy.fold<double>(0, (a, b) => a + b.value).toInt();
});

final averageEnergyProvider =
    FutureProvider.family<double, Pagination>((ref, pagination) async {
  List<Energy> energy = (await ref.watch(energyProvider(pagination).future))
      .where((e) => e.value > 0)
      .toList();

  if (energy.isEmpty) {
    return 0;
  }

  return energy.fold<double>(0, (a, b) => a + b.value) / energy.length;
});

final dailyEnergyChartProvider =
    FutureProvider.family<List<Energy>, Pagination>((ref, pagination) async {
  List<Energy> energy = await ref.watch(energyProvider(pagination).future);
  int divisor = energy.length > 480 ? 48 : 36;

  var averageEnergy = <Energy>[];
  double total = 0.0;
  for (var i = 0; i < energy.length; i++) {
    total += energy[i].value;
    if (i % divisor == 0) {
      averageEnergy.add(Energy(
        time: energy[i].time,
        value: total / divisor,
      ));
      total = 0.0;
    }
  }
  return averageEnergy;
});

final averageMovementMinutesProvider =
    FutureProvider.family<double, Pagination>((ref, pagination) async {
  List<Energy> energy = (await ref.watch(energyProvider(pagination).future))
      .where((e) => e.activity != Activity.sedentary)
      .toList();

  if (energy.isEmpty) {
    return 0;
  }

  return energy.fold<int>(0, (a, b) => a + b.minutes) / energy.length;
});

final totalMovementMinutesProvider =
    FutureProvider.family<int, Pagination>((ref, pagination) async {
  List<Energy> energy = await ref.watch(energyProvider(pagination).future);
  return energy
      .where((e) => e.activity != Activity.sedentary)
      .fold<int>(0, (a, b) => a + b.minutes);
});
