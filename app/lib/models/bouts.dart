import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/api.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/pagination.dart';

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

final excerciseBoutsProvider = FutureProvider<List<Bout>>((ref) async {
  DateTime date = ref.watch(dateProvider);

  DateTime startOfWeek = date.subtract(Duration(days: date.weekday - 1));

  Pagination pagination = const Pagination();
  List<Bout> bouts = await Api().getBouts(
    pagination.from(startOfWeek),
    pagination.to(date),
    pagination.mode,
  );

  return bouts.where((e) => e.activity.isExercise).toList().reversed.toList();
});

final averageSedentaryBout =
    FutureProvider.family<double, Pagination>((ref, pagination) async {
  List<Bout> bouts = (await ref.watch(boutsProvider(pagination).future))
      .where((e) => e.activity == Activity.sedentary)
      .toList();

  return bouts.isEmpty
      ? 0
      : bouts.fold<int>(0, (a, b) => a + b.minutes) / bouts.length;
});

final totalSedentaryBout =
    FutureProvider.family<int, Pagination>((ref, pagination) async {
  List<Bout> bouts = (await ref.watch(boutsProvider(pagination).future))
      .where((e) => e.activity == Activity.sedentary)
      .toList();

  return bouts.fold<int>(0, (a, b) => a + b.minutes);
});
