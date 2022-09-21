import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/energy.dart';

final averageMovementMinutesProvider =
    FutureProvider.family<double, Pagination>((ref, pagination) async {
  List<Energy> energy = (await ref.watch(energyProvider(pagination).future))
      .where((element) => element.movementLevel != MovementLevel.sedentary)
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
      .where((element) => element.movementLevel != MovementLevel.sedentary)
      .fold<int>(0, (a, b) => a + b.minutes);
});
