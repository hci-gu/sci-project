import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';

class JournalEvents {
  final JournalType type;
  final List<JournalEntry> entries;

  JournalEvents({
    required this.type,
    required this.entries,
  });
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
  return journal.where((element) => element.time.day == date.day).toList();
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

final journalTypeFilterProvider = StateProvider<JournalType?>((ref) => null);
final bodyPartFilterProvider = StateProvider<BodyPart?>((ref) => null);

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

class JournalState extends StateNotifier<DateTime> {
  JournalState() : super(DateTime.now());

  Future createJournalEntry(
      JournalType type, Map<String, dynamic> values) async {
    Map<String, dynamic> info = {};

    String comment = values['comment'] as String;
    DateTime time = values['time'] as DateTime;

    switch (type) {
      case JournalType.pain:
        BodyPart bodyPart = BodyPart(
            values['bodyPartType'] as BodyPartType, values['side'] as Side?);
        info = {
          'painLevel': values['painLevel'] as int,
          'bodyPart': bodyPart.toString(),
        };
        break;
      case JournalType.pressureRelease:
        List<PressureReleaseExercise> exercises =
            values['exercises'] as List<PressureReleaseExercise>;
        info = {
          'exercises': exercises.map((e) => e.name.toString()).toList(),
        };
        break;
      case JournalType.pressureUlcer:
        PressureUlcerLocation location =
            values['location'] as PressureUlcerLocation;
        PressureUlcerType pressureUlcerType =
            values['pressureUlcerType'] as PressureUlcerType;
        info = {
          'pressureUlcerType': pressureUlcerType.name,
          'location': location.name,
        };
        break;
      case JournalType.bladderEmptying:
        UrineType type = values['urineType'] as UrineType;
        info = {
          'urineType': type.name,
          'smell': values['smell'] as bool,
        };
        break;
      case JournalType.urinaryTractInfection:
        UTIType type = values['utiType'] as UTIType;
        info = {
          'utiType': type.name,
        };
        break;
      default:
    }

    await Api().createJournalEntry({
      't': time.toIso8601String(),
      'type': type.name,
      'comment': comment,
      'info': info,
    });
    state = DateTime.now();
  }

  Future updateJournalEntry(
      JournalEntry entry, Map<String, dynamic> values) async {
    await Api().updateJournalEntry(
      entry.fromFormUpdate(values),
    );
    state = DateTime.now();
  }

  Future deleteJournalEntry(int id) async {
    await Api().deleteJournalEntry(id);
    state = DateTime.now();
  }
}

final updateJournalProvider =
    StateNotifierProvider<JournalState, DateTime>((ref) => JournalState());
