import 'package:hooks_riverpod/hooks_riverpod.dart';

enum ChartMode {
  day,
  week,
  month,
  year,
}

extension ChartModeDisplayName on ChartMode {
  String get displayName {
    switch (this) {
      case ChartMode.day:
        return 'Dag';
      case ChartMode.week:
        return 'Vecka';
      case ChartMode.month:
        return 'Månad';
      case ChartMode.year:
        return 'År';
    }
  }
}

class Pagination {
  final int page;
  final ChartMode mode;
  final Duration? overrideDuration;

  const Pagination({
    this.page = 0,
    this.mode = ChartMode.day,
    this.overrideDuration,
  });

  Duration get duration {
    if (overrideDuration != null) {
      return overrideDuration!;
    }
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

String displayDate(DateTime date) {
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime yesterday = today.subtract(const Duration(days: 1));

  if (!date.isBefore(today)) {
    return 'Idag';
  } else if (!date.isBefore(yesterday)) {
    return 'Igår';
  }

  return date.toString().substring(0, 10);
}

final dateDisplayProvider = Provider<String>((ref) {
  Pagination pagination = ref.watch(paginationProvider);
  DateTime date =
      ref.watch(dateProvider).subtract(pagination.duration * pagination.page);
  return displayDate(date);
});
final previousDateDisplayProvider = Provider<String>((ref) {
  Pagination pagination = ref.watch(paginationProvider);
  DateTime date = ref
      .watch(dateProvider)
      .subtract(pagination.duration * (pagination.page + 1));
  return displayDate(date);
});
