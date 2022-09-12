import 'package:hooks_riverpod/hooks_riverpod.dart';

class Pagination {
  final int page;
  final Duration duration;

  const Pagination({
    this.page = 0,
    this.duration = const Duration(days: 1),
  });
}

final dateProvider =
    StateProvider<DateTime>((ref) => DateTime.parse('2022-09-03'));
// final dateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final dateFromProvider = Provider<DateTime>((ref) {
  DateTime date = ref.watch(dateProvider);
  return DateTime(date.year, date.month, date.day);
});
final dateToProvider = Provider<DateTime>((ref) {
  DateTime date = ref.watch(dateProvider);
  return DateTime(date.year, date.month, date.day, 23, 59, 59);
});
