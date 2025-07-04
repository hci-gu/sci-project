import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';

class ShowTimelineNotifier extends Notifier<bool> {
  @override
  bool build() {
    listenSelf((previous, next) {
      if (next) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });

    return false;
  }

  void toggle() {
    state = !state;
  }
}

final showTimelineProvider =
    NotifierProvider<ShowTimelineNotifier, bool>(ShowTimelineNotifier.new);

final timelineFiltersProvider = StateProvider<Map<TimelineType, bool>>((ref) {
  return {
    TimelineType.pain: true,
    TimelineType.pressureUlcer: true,
    TimelineType.pressureRelease: true,
    TimelineType.urinaryTractInfection: true,
    TimelineType.bladderEmptying: true,
    TimelineType.leakage: true,
    TimelineType.movement: true,
  };
});

enum TimelineDisplayType {
  events,
  periods,
  lineChart,
  barChart,
}

TimelineDisplayType timelineDisplayType(TimelineType type) {
  switch (type) {
    case TimelineType.pain:
    case TimelineType.spasticity:
      return TimelineDisplayType.lineChart;
    case TimelineType.movement:
      return TimelineDisplayType.barChart;
    case TimelineType.pressureUlcer:
    case TimelineType.urinaryTractInfection:
      return TimelineDisplayType.periods;
    default:
      return TimelineDisplayType.events;
  }
}

Color periodColorForEntry(JournalEntry entry) {
  Color color = Colors.transparent;
  if (entry is PressureUlcerEntry) {
    color = entry.pressureUlcerType.color;
  } else if (entry is UTIEntry) {
    color = entry.utiType.color();
  }
  return color;
}

int timelineSortForType(TimelineType type) {
  switch (type) {
    case TimelineType.pain:
      return 0;
    case TimelineType.pressureUlcer:
      return 10;
    case TimelineType.pressureRelease:
      return 11;
    case TimelineType.urinaryTractInfection:
      return 20;
    case TimelineType.bladderEmptying:
      return 21;
    case TimelineType.leakage:
      return 22;
    default:
      return 30;
  }
}

class Period {
  final DateTime start;
  final DateTime end;
  final Color color;

  Period({
    required this.start,
    required this.end,
    required this.color,
  });

  Duration get duration {
    return end.difference(start);
  }
}

class TimelinePage {
  final Pagination pagination;
  final TimelineType type;

  TimelinePage({required this.pagination, required this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelinePage &&
          runtimeType == other.runtimeType &&
          pagination == other.pagination &&
          type == other.type;
  @override
  int get hashCode => pagination.hashCode ^ type.hashCode;
}

final timelineDataProvider = FutureProvider<List<JournalEntry>>((ref) async {
  Map<TimelineType, bool> filters = ref.watch(timelineFiltersProvider);
  int yearsToFetch = ref.watch(timelineYearsProvider);
  List<JournalEntry> journal = [];
  for (int i = yearsToFetch - 1; i >= 0; i--) {
    Pagination yearPage = Pagination(mode: ChartMode.year, page: i);
    List<JournalEntry> entries = await ref.watch(
      journalProvider(yearPage).future,
    );

    journal.addAll(entries);
  }

  return journal.where((e) => filters[e.timelineType] == true).toList();
});

final timelinePaginationProvider = StateProvider<Pagination>((ref) {
  return const Pagination(
    mode: ChartMode.month,
    page: 0,
  );
});

final timelineTouchedDateProvider = StateProvider<DateTime?>((ref) => null);

final timelineYearsProvider = StateProvider<int>((ref) {
  Pagination page = ref.watch(timelinePaginationProvider);
  int currentYear = DateTime.now().year;
  Pagination nextPage = Pagination(
    mode: page.mode,
    page: page.page + 1,
  );

  return currentYear - nextPage.from.year + 1;
});

final timelineVisibleRangeProvider = StateProvider<List<DateTime>>((ref) {
  Pagination page = ref.watch(timelinePaginationProvider);

  DateTime from = DateTime(
    page.from.year,
    page.from.month - 3,
  );

  DateTime to = page.to;

  return [from, to];
});

final timelineEventsProvider =
    FutureProviderFamily<List<JournalEntry>, TimelinePage>((ref, page) async {
  DateTime from = page.pagination.from;
  DateTime to = page.pagination.to;
  List<JournalEntry> journal = await ref.watch(timelineDataProvider.future);

  return journal
      .where((e) =>
          timelineDisplayType(e.timelineType) == TimelineDisplayType.events)
      .where((e) => e.timelineType == page.type)
      .where((e) => e.time.isBefore(to) && e.time.isAfter(from))
      .toList();
});

final timelineTypesProvider =
    FutureProvider.family<List<TimelineType>, Pagination>(
        (ref, pagination) async {
  List<DateTime> visibleRange = ref.watch(timelineVisibleRangeProvider);
  List<JournalEntry> journal = await ref.watch(timelineDataProvider.future);

  List<TimelineType> types = journal
      .where((e) =>
          e.time.isAfter(visibleRange.first) &&
          e.time.isBefore(visibleRange.last))
      .map((e) => e.timelineType)
      .toSet()
      .toList();

  types
      .sort((a, b) => timelineSortForType(a).compareTo(timelineSortForType(b)));
  return [...types, TimelineType.movement];
});

final timelinePeriodsProvider =
    FutureProvider.family<List<Period>, TimelinePage>((ref, page) async {
  DateTime from = page.pagination.from;
  DateTime to = page.pagination.to;
  List<JournalEntry> journal = await ref.watch(timelineDataProvider.future);

  List entries = journal
      .where((e) =>
          timelineDisplayType(e.timelineType) == TimelineDisplayType.periods)
      .where((e) => e.timelineType == page.type)
      .toList();

  List<Period> periods = [];
  DateTime today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  if (entries.length == 1) {
    return [
      Period(
        start: entries.first.time,
        end: today,
        color: periodColorForEntry(entries.first),
      ),
    ];
  }

  for (JournalEntry entry in entries) {
    // skip first
    if (entry == entries.first) {
      continue;
    }
    JournalEntry previousEntry = entries[entries.indexOf(entry) - 1];

    // add entry and set start time as end time of previous entry
    periods.add(Period(
      start: DateTime(
        previousEntry.time.year,
        previousEntry.time.month,
        previousEntry.time.day,
      ),
      end: DateTime(
        entry.time.year,
        entry.time.month,
        entry.time.day,
      ),
      color: periodColorForEntry(previousEntry),
    ));
  }

  JournalEntry lastEntry = entries.last;
  if ((lastEntry is PressureUlcerEntry &&
          lastEntry.pressureUlcerType != PressureUlcerType.none ||
      lastEntry is UTIEntry && lastEntry.utiType != UTIType.none)) {
    periods.add(
      Period(
        start: DateTime(
          lastEntry.time.year,
          lastEntry.time.month,
          lastEntry.time.day,
        ),
        end: today,
        color: periodColorForEntry(lastEntry),
      ),
    );
  }

  // only return periods that overlap with the current page
  return periods
      .where((e) => e.start.isBefore(to) && e.end.isAfter(from))
      .toList();
});
