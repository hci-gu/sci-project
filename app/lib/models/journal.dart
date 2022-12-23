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

  return journal.where((e) => e.bodyPart == bodyPart).toList();
});
final bodyPartFilterProvider = StateProvider<BodyPart?>((ref) => null);

final uniqueEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  List<JournalEntry> journal = await ref.watch(journalProvider.future);

  // filter out all unique journal entries based on bodyPart
  List<JournalEntry> uniqueEntries = [];
  for (JournalEntry entry in journal.reversed) {
    if (!uniqueEntries.any((e) => e.bodyPart == entry.bodyPart)) {
      uniqueEntries.add(entry);
    }
  }

  return uniqueEntries;
});

class JournalState extends StateNotifier<DateTime> {
  JournalState() : super(DateTime.now());

  Future createJournalEntry(Map<String, dynamic> values) async {
    String comment = values['comment'] as String;
    int painLevel = values['painLevel'] as int;
    BodyPart bodyPart = BodyPart(
        values['bodyPartType'] as BodyPartType, values['side'] as Side?);

    await Api().createJournalEntry(comment, painLevel, bodyPart.toString());
    state = DateTime.now();
  }

  Future updateJournalEntry(
      JournalEntry entry, Map<String, dynamic> values) async {
    String comment = values['comment'] as String;
    int painLevel = values['painLevel'] as int;
    BodyPart bodyPart = BodyPart(
        values['bodyPartType'] as BodyPartType, values['side'] as Side?);

    await Api().updateJournalEntry(
      JournalEntry(
        type: entry.type,
        id: entry.id,
        comment: comment,
        painLevel: painLevel,
        bodyPart: bodyPart,
        time: entry.time,
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
