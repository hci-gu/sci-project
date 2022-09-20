import 'package:hooks_riverpod/hooks_riverpod.dart';

enum ChartMode {
  day,
  week,
  month,
  year,
}

class Pagination {
  final int page;
  final ChartMode mode;

  const Pagination({
    this.page = 0,
    this.mode = ChartMode.day,
  });

  Duration get duration {
    switch (mode) {
      case ChartMode.day:
        return const Duration(days: 1);
      case ChartMode.week:
        return const Duration(days: 6);
      case ChartMode.month:
        return const Duration(days: 30);
      case ChartMode.year:
        return const Duration(days: 365);
    }
  }

  DateTime from(DateTime date) {
    DateTime d =
        date.subtract(duration * (page + (mode == ChartMode.day ? 0 : 1)));
    return DateTime(d.year, d.month, d.day);
  }

  DateTime to(DateTime date) {
    DateTime d = date.subtract(duration * page);
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  @override
  bool operator ==(other) =>
      other is Pagination && page == other.page && mode == other.mode;
  @override
  int get hashCode => page.hashCode + mode.hashCode;
}

final dateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final paginationProvider =
    StateProvider<Pagination>((ref) => const Pagination());

final dateDisplayProvider = Provider<String>((ref) {
  DateTime date = ref.watch(dateProvider);
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime yesterday = today.subtract(const Duration(days: 1));

  if (!date.isBefore(today)) {
    return 'Today';
  } else if (!date.isBefore(yesterday)) {
    return 'Yesterday';
  }

  return date.toString().substring(0, 10);
});
