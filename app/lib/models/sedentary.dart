import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/energy.dart';

final totalSedentaryMinutesProvider =
    FutureProvider.family<int, Pagination>((ref, pagination) async {
  List<Energy> energy = await ref.watch(energyProvider(pagination).future);
  return energy
      .where((e) => e.movementLevel == MovementLevel.sedentary)
      .toList()
      .length;
});

final averageSedentaryMinutesProvider =
    FutureProvider.family<double, Pagination>((ref, pagination) async {
  List<Energy> energy = (await ref.watch(energyProvider(pagination).future))
      .where((e) => e.movementLevel == MovementLevel.sedentary)
      .toList();

  if (energy.isEmpty) {
    return 0;
  }

  return energy.fold<double>(0, (a, b) => a + b.minutes) / energy.length;
});

final sedentaryProvider =
    FutureProvider.family<int, Pagination>((ref, pagination) async {
  DateTime date = ref.watch(dateProvider);

  return Api().getActivity(pagination.from(date), pagination.to(date));
});
