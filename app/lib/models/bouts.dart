import 'package:scimovement/api.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/config.dart';

final boutsProvider =
    FutureProvider.family<List<Bout>, Pagination>((ref, pagination) async {
  DateTime date = ref.watch(dateProvider);

  List<Bout> bouts = await Api().getBouts(
    pagination.from(date),
    pagination.to(date),
    pagination.mode,
  );
  return bouts;
});

final averageSedentaryBout =
    FutureProvider.family<double, Pagination>((ref, pagination) async {
  List<Bout> bouts = (await ref.watch(boutsProvider(pagination).future))
      .where((e) => e.activity == Activity.sedentary)
      .toList();

  if (bouts.isEmpty) {
    return 0;
  }

  return bouts.fold<int>(0, (a, b) => a + b.minutes) / bouts.length;
});

final totalSedentaryBout =
    FutureProvider.family<int, Pagination>((ref, pagination) async {
  List<Bout> bouts = (await ref.watch(boutsProvider(pagination).future))
      .where((e) => e.activity == Activity.sedentary)
      .toList();

  return bouts.fold<int>(0, (a, b) => a + b.minutes);
});
