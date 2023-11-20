import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';

final showTimelineProvider = StateProvider<bool>((ref) {
  ref.listenSelf((previous, next) {
    // force orientation
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
});

final timelineFiltersProvider = StateProvider<Map<JournalType, bool>>((ref) {
  return {
    JournalType.pain: true,
    JournalType.pressureUlcer: true,
    JournalType.pressureRelease: true,
    JournalType.urinaryTractInfection: true,
    JournalType.bladderEmptying: true,
    JournalType.leakage: true,
    JournalType.movement: true,
  };
});

enum TimelineDisplayType {
  events,
  periods,
  chart,
}

TimelineDisplayType timelineDisplayTypeForJournalType(JournalType type) {
  switch (type) {
    case JournalType.pain:
      return TimelineDisplayType.chart;
    case JournalType.pressureUlcer:
    case JournalType.urinaryTractInfection:
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

int timelineSortForType(JournalType type) {
  switch (type) {
    case JournalType.pain:
      return 0;
    case JournalType.pressureUlcer:
      return 10;
    case JournalType.pressureRelease:
      return 11;
    case JournalType.urinaryTractInfection:
      return 20;
    case JournalType.bladderEmptying:
      return 21;
    case JournalType.leakage:
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
  final JournalType type;

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
  Map<JournalType, bool> filters = ref.watch(timelineFiltersProvider);
  int yearsToFetch = ref.watch(timelineYearsProvider);
  List<JournalEntry> journal = [];
  for (int i = yearsToFetch - 1; i >= 0; i--) {
    Pagination yearPage = Pagination(mode: ChartMode.year, page: i);
    List<JournalEntry> entries = await ref.watch(
      journalProvider(yearPage).future,
    );

    journal.addAll(entries);
  }

  return journal.where((e) => filters[e.type] == true).toList();
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
          timelineDisplayTypeForJournalType(e.type) ==
          TimelineDisplayType.events)
      .where((e) => e.type == page.type)
      .where((e) => e.time.isBefore(to) && e.time.isAfter(from))
      .toList();
});

final timelinePainChartProvider =
    FutureProviderFamily<List<PainLevelEntry>, TimelinePage>((ref, page) async {
  DateTime from = page.pagination.from;
  DateTime to = page.pagination.to;
  List<JournalEntry> journal = await ref.watch(timelineDataProvider.future);

  List<PainLevelEntry> entries = journal.whereType<PainLevelEntry>().toList();

  List<PainLevelEntry> entriesToShow = entries
      .where((e) => e.time.isBefore(to) && e.time.isAfter(from))
      .toList();

  List<BodyPart> bodyParts = entries.map((e) => e.bodyPart).toSet().toList();
  for (BodyPart bodyPart in bodyParts) {
    List<PainLevelEntry> entriesForBodyPart =
        entries.where((e) => e.bodyPart == bodyPart).toList();

    List<PainLevelEntry> entriesBefore =
        entriesForBodyPart.where((e) => e.time.isBefore(from)).toList();
    entriesBefore.sort((a, b) {
      int aDistance = a.time.difference(from).inMilliseconds.abs();
      int bDistance = b.time.difference(from).inMilliseconds.abs();
      return aDistance.compareTo(bDistance);
    });

    List<PainLevelEntry> entriesAfter =
        entriesForBodyPart.where((e) => e.time.isAfter(to)).toList();
    entriesAfter.sort((a, b) {
      int aDistance = a.time.difference(to).inMilliseconds.abs();
      int bDistance = b.time.difference(to).inMilliseconds.abs();
      return aDistance.compareTo(bDistance);
    });

    if (entriesBefore.isNotEmpty) {
      entriesToShow.add(entriesBefore.first);
    }
    if (entriesAfter.isNotEmpty) {
      entriesToShow.add(entriesAfter.first);
    }
  }

  entriesToShow.sort((a, b) => a.time.compareTo(b.time));
  return entriesToShow;
});

final timelineBodyPartsForVisibleRange =
    FutureProvider<List<BodyPart>>((ref) async {
  List<DateTime> visibleRange = ref.watch(timelineVisibleRangeProvider);
  List<JournalEntry> journal = await ref.watch(timelineDataProvider.future);

  List<BodyPart> bodyParts = journal
      .where((e) =>
          e.time.isAfter(visibleRange.first) &&
          e.time.isBefore(visibleRange.last))
      .whereType<PainLevelEntry>()
      .map((e) => e.bodyPart)
      .toSet()
      .toList();
  bodyParts.sort((a, b) => a.toString().compareTo(b.toString()));
  return bodyParts;
});

final timelineTypesProvider =
    FutureProvider.family<List<JournalType>, Pagination>(
        (ref, pagination) async {
  List<DateTime> visibleRange = ref.watch(timelineVisibleRangeProvider);
  List<JournalEntry> journal = await ref.watch(timelineDataProvider.future);

  List<JournalType> types = journal
      .where((e) =>
          e.time.isAfter(visibleRange.first) &&
          e.time.isBefore(visibleRange.last))
      .map((e) => e.type)
      .toSet()
      .toList();
  types
      .sort((a, b) => timelineSortForType(a).compareTo(timelineSortForType(b)));
  return [...types, JournalType.movement];
});

final timelinePeriodsProvider =
    FutureProvider.family<List<Period>, TimelinePage>((ref, page) async {
  DateTime from = page.pagination.from;
  DateTime to = page.pagination.to;
  List<JournalEntry> journal = await ref.watch(timelineDataProvider.future);

  List entries = journal
      .where((e) =>
          timelineDisplayTypeForJournalType(e.type) ==
          TimelineDisplayType.periods)
      .where((e) => e.type == page.type)
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
