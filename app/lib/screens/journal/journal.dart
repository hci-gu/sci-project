import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/journal_calendar.dart';
import 'package:scimovement/screens/journal/widgets/journal_list.dart';
import 'package:scimovement/screens/journal/widgets/journal_shortcut_grid.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/button.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTheme.appBar(AppLocalizations.of(context)!.logbook),
      body: const Column(
        children: [
          Expanded(child: JournalCalendar()),
          Expanded(child: ListBottomSheet()),
        ],
      ),
      floatingActionButton: isToday(ref.watch(journalSelectedDateProvider))
          ? null
          : FloatingActionButton(
              onPressed: () => GoRouter.of(context).goNamed(
                'select-journal-type',
                extra: {
                  'date': ref.watch(journalSelectedDateProvider),
                },
              ),
              child: const Icon(Icons.add),
            ),
    );
  }

  bool isToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }
}

class ListBottomSheet extends HookConsumerWidget {
  const ListBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime date = ref.watch(journalSelectedDateProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.colors.lightGray,
            width: 1,
          ),
        ),
      ),
      child: ListView(
        padding: AppTheme.elementPadding,
        children: [
          _dateHeader(ref, date),
          AppTheme.spacer2x,
          if (isToday(date)) _createEntry(context),
          const JournalList()
        ],
      ),
    );
  }

  Widget _createEntry(BuildContext context) {
    return Column(
      children: [
        const JournalShortcutGrid(),
        AppTheme.spacer2x,
        _addItem(context),
        AppTheme.spacer2x,
      ],
    );
  }

  Widget _dateHeader(WidgetRef ref, DateTime date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            ref.read(journalSelectedDateProvider.notifier).state =
                date.subtract(const Duration(days: 1));
          },
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          DateFormat.MMMMd('sv').format(date),
          textAlign: TextAlign.center,
          style: AppTheme.headLine3,
        ),
        IconButton(
          onPressed: () {
            ref.read(journalSelectedDateProvider.notifier).state =
                date.add(const Duration(days: 1));
          },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  bool isToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }

  Widget _addItem(BuildContext context) {
    return Center(
      child: Button(
        width: 200,
        icon: Icons.add,
        title: AppLocalizations.of(context)!.newEntry,
        onPressed: () => GoRouter.of(context).goNamed('select-journal-type'),
      ),
    );
  }
}
