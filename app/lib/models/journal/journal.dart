import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/models/journal/journal-form.dart';

export 'package:scimovement/models/journal/journal-form.dart';

enum TimelineDisplayType { events, periods, chart }

class JournalEvents {
  final JournalType type;
  final List<JournalEntry> entries;

  JournalEvents({
    required this.type,
    required this.entries,
  }) {
    entries.sort((a, b) => a.time.compareTo(b.time));
  }

  String title(BuildContext context) {
    return type.displayString(context);
  }

  DateTime get start {
    return entries.first.time;
  }

  DateTime get end {
    switch (type) {
      case JournalType.pressureUlcer:
        if ((entries.last as PressureUlcerEntry).pressureUlcerType !=
            PressureUlcerType.none) {
          return DateTime.now();
        }
        break;
      case JournalType.urinaryTractInfection:
        if ((entries.last as UTIEntry).utiType != UTIType.none) {
          return DateTime.now();
        }
        break;
      default:
    }
    return entries.last.time;
  }

  Duration get duration {
    return end.difference(start);
  }

  TimelineDisplayType get displayType {
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
}

final journalProvider = FutureProvider.family<List<JournalEntry>, Pagination>(
    (ref, pagination) async {
  ref.watch(updateJournalProvider);
  DateTime date = DateTime.now();

  List<JournalEntry> journal = await Api().getJournal(
    pagination.from(date),
    pagination.to(date),
    pagination.mode,
  );
  return journal;
});

final journalEventsProvider =
    FutureProviderFamily<List<JournalEvents>, Pagination>(
        (ref, pagination) async {
  List<JournalEntry> journal =
      await ref.watch(journalProvider(pagination).future);

  List<JournalEvents> events = [];

  for (JournalEntry entry in journal) {
    if (!events.any((e) => e.type == entry.type)) {
      events.add(JournalEvents(type: entry.type, entries: []));
    }
    JournalEvents? event = events.firstWhereOrNull((e) => e.type == entry.type);
    if (event != null) {
      event.entries.add(entry);
    }
  }

  return events;
});

final journalMonthlyProvider =
    FutureProvider.family<List<JournalEntry>, Pagination>(
        (ref, pagination) async {
  ref.watch(updateJournalProvider);
  DateTime date = DateTime.now();
  date = DateTime(date.year, date.month, 1);

  List<JournalEntry> journal = await Api().getJournal(
    pagination.from(date),
    pagination.to(date),
    pagination.mode,
  );
  return journal;
});

final journalPaginationProvider =
    StateProvider<Pagination>((ref) => const Pagination());

final journalForDayProvider =
    FutureProvider.family<List<JournalEntry>, DateTime>((ref, date) async {
  ref.watch(updateJournalProvider);
  Pagination pagination = const Pagination(mode: ChartMode.day, page: 0);
  List<JournalEntry> journal = await Api().getJournal(
    pagination.from(date),
    pagination.to(date),
    pagination.mode,
  );
  return journal
      .where((element) => element.time.day == date.day)
      .toList()
      .reversed
      .toList();
});

final paginatedJournalProvider = FutureProvider((ref) async {
  Pagination pagination = ref.watch(journalPaginationProvider);

  List<JournalEntry> journal =
      await ref.watch(journalProvider(pagination).future);
  return journal;
});

final journalSelectedDateProvider = StateProvider<DateTime>((ref) {
  DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final pressureReleaseCountProvider =
    FutureProvider.family<num, Pagination>((ref, pagination) async {
  List<JournalEntry> journal =
      await ref.watch(journalProvider(pagination).future);

  return journal.whereType<PressureReleaseEntry>().length;
});

final bladderEmptyingCountProvider =
    FutureProvider.family<num, Pagination>((ref, pagination) async {
  List<JournalEntry> journal =
      await ref.watch(journalProvider(pagination).future);

  return journal.whereType<BladderEmptyingEntry>().length;
});

final uniqueEntriesProvider =
    FutureProvider.family<List<JournalEntry>, Pagination>(
        (ref, pagination) async {
  List<JournalEntry> journal =
      await ref.watch(journalProvider(pagination).future);

  List<JournalEntry> uniqueEntries = [];
  for (JournalEntry entry in journal.reversed) {
    if (!uniqueEntries.any((e) => e.identifier == entry.identifier)) {
      uniqueEntries.add(entry);
    }
  }

  return uniqueEntries;
});

final pressureUlcerProvider =
    FutureProvider<List<PressureUlcerEntry>>((ref) async {
  ref.watch(updateJournalProvider);
  DateTime date = ref.watch(dateProvider);

  List<JournalEntry> journal =
      await Api().getJournalForType(JournalType.pressureUlcer, date);

  List<PressureUlcerEntry> pressureUlcers =
      journal.whereType<PressureUlcerEntry>().toList();
  pressureUlcers.sort((a, b) => a.time.compareTo(b.time));
  return pressureUlcers;
});

final utiProvider = FutureProvider<UTIEntry?>((ref) async {
  ref.watch(updateJournalProvider);
  DateTime date = ref.watch(dateProvider);

  List<JournalEntry> journal =
      await Api().getJournalForType(JournalType.urinaryTractInfection, date);

  return journal.isEmpty ? null : journal.first as UTIEntry;
});
