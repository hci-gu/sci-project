import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';

final journalProvider = FutureProvider<List<JournalEntry>>((ref) async {
  ref.watch(updateJournalProvider);

  List<JournalEntry> journal = await Api().getJournal();
  return journal;
});

class JournalState extends StateNotifier<DateTime> {
  JournalState() : super(DateTime.now());

  Future createJournalEntry(String comment, int painLevel) async {
    await Api().createJournalEntry(comment, painLevel);
    state = DateTime.now();
  }

  Future deleteJournalEntry(int id) async {
    await Api().deleteJournalEntry(id);
    state = DateTime.now();
  }
}

final updateJournalProvider =
    StateNotifierProvider<JournalState, DateTime>((ref) => JournalState());
