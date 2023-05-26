import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';

final journalProvider = FutureProvider<List<JournalEntry>>((ref) async {
  ref.watch(updateJournalProvider);

  List<JournalEntry> journal = await Api().getJournal();
  return journal;
});

final filteredJournalProvider = FutureProvider<List<JournalEntry>>((ref) async {
  List<JournalEntry> journal = await ref.watch(journalProvider.future);
  BodyPart? bodyPart = ref.watch(bodyPartFilterProvider);

  if (bodyPart == null) {
    return journal;
  }

  return journal
      .whereType<PainLevelEntry>()
      .where((e) => e.bodyPart == bodyPart)
      .toList();
});
final bodyPartFilterProvider = StateProvider<BodyPart?>((ref) => null);

final uniqueEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  List<JournalEntry> journal = await ref.watch(journalProvider.future);

  List<JournalEntry> uniqueEntries = [];
  for (JournalEntry entry in journal.reversed) {
    if (!uniqueEntries.any((e) => e.identifier == entry.identifier)) {
      uniqueEntries.add(entry);
    }
  }

  return uniqueEntries;
});

class JournalState extends StateNotifier<DateTime> {
  JournalState() : super(DateTime.now());

  Future createJournalEntry(
      JournalType type, Map<String, dynamic> values) async {
    Map<String, dynamic> info = {};

    String comment = values['comment'] as String;

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
      default:
    }

    await Api().createJournalEntry({
      'type': type.name,
      'comment': comment,
      'info': info,
    });
    state = DateTime.now();
  }

  Future updateJournalEntry(
      JournalEntry entry, Map<String, dynamic> values) async {
    String comment = values['comment'] as String;
    int painLevel = values['painLevel'] as int;
    BodyPart bodyPart = BodyPart(
        values['bodyPartType'] as BodyPartType, values['side'] as Side?);

    await Api().updateJournalEntry(
      PainLevelEntry(
        type: entry.type,
        id: entry.id,
        comment: comment,
        time: entry.time,
        painLevel: painLevel,
        bodyPart: bodyPart,
      ),
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
