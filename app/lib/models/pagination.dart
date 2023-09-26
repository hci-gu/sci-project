import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum ChartMode {
  day,
  week,
  month,
  quarter,
  year,
}

extension ChartModeDisplayName on ChartMode {
  String displayName(BuildContext context) {
    switch (this) {
      case ChartMode.day:
        return AppLocalizations.of(context)!.day;
      case ChartMode.week:
        return AppLocalizations.of(context)!.week;
      case ChartMode.month:
        return AppLocalizations.of(context)!.month;
      case ChartMode.quarter:
        return AppLocalizations.of(context)!.quarter;
      case ChartMode.year:
        return AppLocalizations.of(context)!.year;
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
      case ChartMode.quarter:
        return const Duration(days: 90);
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

String displayDate(BuildContext context, DateTime date) {
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime yesterday = today.subtract(const Duration(days: 1));

  if (!date.isBefore(today)) {
    return AppLocalizations.of(context)!.today;
  } else if (!date.isBefore(yesterday)) {
    return AppLocalizations.of(context)!.yesterday;
  }

  String weekday = DateFormat(DateFormat.WEEKDAY).format(date);
  // capitalize
  return weekday[0].toUpperCase() + weekday.substring(1);
}

String displayDateSubtitle(BuildContext context, DateTime date, Locale locale) {
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime yesterday = today.subtract(const Duration(days: 1));

  if (!date.isBefore(today) || !date.isBefore(yesterday)) {
    // weekday, dd M
    String weekday =
        DateFormat(DateFormat.WEEKDAY, locale.languageCode).format(date);
    weekday = weekday[0].toUpperCase() + weekday.substring(1);

    return '$weekday, ${DateFormat(DateFormat.MONTH_DAY, locale.languageCode).format(date)}';
  }

  return DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY, locale.languageCode)
      .format(date);
}

final dateDisplayProvider =
    Provider.family<String, BuildContext>((ref, context) {
  Pagination pagination = ref.watch(paginationProvider);
  DateTime date =
      ref.watch(dateProvider).subtract(pagination.duration * pagination.page);
  return displayDate(context, date);
});
final subtitleDateDisplayProvider =
    Provider.family<String, BuildContext>((ref, context) {
  Locale locale = Localizations.localeOf(context);
  Pagination pagination = ref.watch(paginationProvider);
  DateTime date =
      ref.watch(dateProvider).subtract(pagination.duration * pagination.page);
  return displayDateSubtitle(context, date, locale);
});

final previousDateDisplayProvider =
    Provider.family<String, BuildContext>((ref, context) {
  Pagination pagination = ref.watch(paginationProvider);
  DateTime date = ref
      .watch(dateProvider)
      .subtract(pagination.duration * (pagination.page + 1));
  return displayDate(context, date);
});

final isTodayProvider = Provider<bool>((ref) {
  DateTime date = ref.watch(dateProvider);
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  return date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;
});
