import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/models/journal/journal_form.dart';

export 'package:scimovement/models/journal/journal_form.dart';

final journalProvider = FutureProvider.family<List<JournalEntry>, Pagination>(
    (ref, pagination) async {
  ref.watch(updateJournalProvider);
  DateTime date = ref.watch(dateProvider);
  Pagination page = Pagination(
    page: pagination.page,
    mode: pagination.mode,
    overrideDate: date,
  );

  List<JournalEntry> journal = await Api().getJournal(
    page.from,
    page.to,
    page.mode,
  );
  return journal;
});

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

final journalMonthlyProvider =
    FutureProvider.family<List<JournalEntry>, Pagination>(
        (ref, pagination) async {
  ref.watch(updateJournalProvider);

  List<JournalEntry> journal = await Api().getJournal(
    pagination.from,
    pagination.to,
    pagination.mode,
  );
  return journal;
});

final journalPaginationProvider =
    StateProvider<Pagination>((ref) => const Pagination());

final journalForDayProvider =
    FutureProvider.family<List<JournalEntry>, DateTime>((ref, date) async {
  ref.watch(updateJournalProvider);
  Pagination pagination =
      Pagination(mode: ChartMode.day, page: 0, overrideDate: date);
  List<JournalEntry> journal = await Api().getJournal(
    pagination.from,
    pagination.to,
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

final journalSelectedDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

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

final neuroPathicPainAndSpasticityProvider =
    FutureProvider<List<JournalEntry>>((ref) async {
  ref.watch(updateJournalProvider);
  DateTime date = ref.watch(dateProvider);

  List<JournalEntry> entries = [
    ...await Api().getJournalForType(JournalType.neuropathicPain, date),
    ...await Api().getJournalForType(JournalType.spasticity, date),
  ];

  entries.sort((a, b) => b.time.compareTo(a.time));
  return entries;
});
