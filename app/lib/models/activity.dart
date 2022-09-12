import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/config.dart';

final heartRateProvider = FutureProvider<List<HeartRate>>((ref) async {
  DateTime from = ref.watch(dateFromProvider);
  DateTime to = ref.watch(dateToProvider);

  return Api().getHeartRate(from, to);
});

final energyProvider =
    FutureProvider.family<List<Energy>, Pagination>((ref, pagination) async {
  Duration durationToSubtract = pagination.duration * pagination.page;

  DateTime from = ref.watch(dateFromProvider).subtract(durationToSubtract);
  DateTime to = ref.watch(dateToProvider).subtract(durationToSubtract);

  return Api().getEnergy(from, to);
});

final totalEnergyProvider =
    FutureProvider.family<int, Pagination>((ref, pagination) async {
  List<Energy> energy = await ref.watch(energyProvider(pagination).future);
  return energy.fold<double>(0, (a, b) => a + b.value).toInt();
});

final averageEnergyProvider =
    FutureProvider.family<List<Energy>, Pagination>((ref, pagination) async {
  List<Energy> energy = await ref.watch(energyProvider(pagination).future);
  int divisor = 20;

  var averageEnergy = <Energy>[];
  double total = 0.0;
  for (var i = 0; i < energy.length; i++) {
    total += energy[i].value;
    if (i % divisor == 0) {
      averageEnergy.add(Energy(
        energy[i].time,
        total / divisor,
      ));
      total = 0.0;
    }
  }
  return averageEnergy;
});
