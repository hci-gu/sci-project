import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/journal_calendar.dart';
import 'package:scimovement/screens/journal/widgets/journal_shortcut_grid.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';

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
              onPressed: () =>
                  GoRouter.of(context).goNamed('select-journal-type'),
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
          if (isToday(date)) const JournalShortcutGrid(),
          if (isToday(date)) AppTheme.spacer2x,
          if (isToday(date)) _addItem(context),
          if (isToday(date)) AppTheme.spacer2x,
          ref.watch(journalForDayProvider(date)).when(
                data: (data) {
                  if (data.isEmpty && !isToday(date)) {
                    return Container(
                      padding: AppTheme.elementPadding,
                      child: Center(
                          child: Text(
                              AppLocalizations.of(context)!.journalNoData)),
                    );
                  }

                  return _list(context, ref, data);
                },
                error: (_, __) => Container(),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              )
        ],
      ),
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

  Widget _list(
      BuildContext context, WidgetRef ref, List<JournalEntry> journal) {
    return Column(
      children: [
        for (JournalEntry entry in journal) _listTile(context, ref, entry),
      ],
    );
  }

  Widget _listTile(BuildContext context, WidgetRef ref, JournalEntry entry) {
    String title = entry.title(context);
    String subtitle =
        '${entry.time.hour.toString()}:${entry.time.minute.toString().padLeft(2, '0')}';
    return Dismissible(
      key: ValueKey(entry.id),
      background: Container(color: AppTheme.colors.error),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          bool? confirmed = await confirmDialog(
            context,
            title: AppLocalizations.of(context)!.removeConfirmation,
            message: 'AppLocalizations.of(context)!.jou',
          );
          if (confirmed == true) {
            ref
                .read(updateJournalProvider.notifier)
                .deleteJournalEntry(entry.id);
          }
        }
        return false;
      },
      child: GestureDetector(
        onTap: () {
          GoRouter.of(context).goNamed(
            'update-journal',
            pathParameters: {
              'id': entry.id.toString(),
            },
            extra: {
              'entry': entry,
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
              border: Border.symmetric(
            horizontal: BorderSide(
              color: Colors.grey.shade300,
            ),
          )),
          child: ListTile(
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
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
