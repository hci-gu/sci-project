import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/pagination.dart';

final journalProvider = FutureProvider.family<List<JournalEntry>, Pagination>(
    (ref, pagination) async {
  ref.watch(updateJournalProvider);
  DateTime date = ref.watch(dateProvider);

  List<JournalEntry> journal = await Api().getJournal(
    pagination.from(date),
    pagination.to(date),
    pagination.mode,
  );
  return journal;
});

final filteredJournalProvider =
    FutureProvider.family<List<JournalEntry>, Pagination>(
        (ref, pagination) async {
  List<JournalEntry> journal =
      await ref.watch(journalProvider(pagination).future);
  JournalType? type = ref.watch(journalTypeFilterProvider);

  if (type == null) {
    return journal;
  }

  return journal.where((e) => e.type == type).toList();
});
final journalTypeFilterProvider = StateProvider<JournalType?>((ref) => null);
final bodyPartFilterProvider = StateProvider<BodyPart?>((ref) => null);

final pressureReleaseCountProvider =
    FutureProvider.family<num, Pagination>((ref, pagination) async {
  List<JournalEntry> journal =
      await ref.watch(journalProvider(pagination).future);

  return journal.whereType<PressureReleaseEntry>().length;
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
