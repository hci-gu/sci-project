import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';

class JournalListItem extends ConsumerWidget {
  final JournalEntry entry;

  const JournalListItem({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(entry.id),
      background: Container(color: AppTheme.colors.error),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete(context, ref);
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => onTap(context),
        child: Container(
          decoration: BoxDecoration(
              border: Border.symmetric(
            horizontal: BorderSide(
              color: Colors.grey.shade300,
            ),
          )),
          child: ListTile(
            title: Text(entry.title(context)),
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

  onTap(BuildContext context) {
    GoRouter.of(context).goNamed(
      'update-journal',
      pathParameters: {
        'id': entry.id.toString(),
      },
      extra: {
        'entry': entry,
      },
    );
  }

  onDelete(BuildContext context, WidgetRef ref) async {
    bool? confirmed = await confirmDialog(
      context,
      title: AppLocalizations.of(context)!.remove,
      message: AppLocalizations.of(context)!.removeConfirmation,
    );
    if (confirmed == true) {
      ref.read(updateJournalProvider.notifier).deleteJournalEntry(entry.id);
    }
  }

  String get subtitle =>
      '${entry.time.hour.toString()}:${entry.time.minute.toString().padLeft(2, '0')}';
}

class JournalList extends ConsumerWidget {
  const JournalList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime date = ref.watch(journalSelectedDateProvider);

    return ref.watch(journalForDayProvider(date)).when(
          data: (data) {
            if (data.isEmpty && !isToday(date)) {
              return Container(
                padding: AppTheme.elementPadding,
                child: Center(
                  child: Text(AppLocalizations.of(context)!.journalNoData),
                ),
              );
            }

            return Column(
              children: [
                for (JournalEntry entry in data) JournalListItem(entry: entry),
              ],
            );
          },
          error: (_, __) => Container(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
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
