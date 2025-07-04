import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/screens/journal/edit_entry.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:scimovement/widgets/tappable.dart';

class JournalListItem extends ConsumerWidget {
  final JournalEntry entry;

  const JournalListItem({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(entry.id),
      background: Container(
        color: AppTheme.colors.error,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              AppLocalizations.of(context)!.remove,
              style: AppTheme.labelLarge.copyWith(color: Colors.white),
            ),
            AppTheme.spacer,
            Padding(
              padding: EdgeInsets.only(right: AppTheme.basePadding * 2),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete(context, ref);
        }
        return false;
      },
      child: Tappable(
        onTap: () => onTap(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.basePadding * 2,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            child: ListTile(
              leading: SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppTheme.iconForJournalType(
                      entry.type,
                      entry is PainLevelEntry
                          ? (entry as PainLevelEntry).bodyPart
                          : null,
                      32,
                    )
                  ],
                ),
              ),
              horizontalTitleGap: AppTheme.basePadding * 2,
              title: Text(entry.title(context), style: AppTheme.labelLarge),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.edit),
            ),
          ),
        ),
      ),
    );
  }

  void onTap(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      context: context,
      builder: (context) => EditJournalEntryScreen(
        shouldCreateEntry: false,
        entry: entry,
      ),
    );
  }

  void onDelete(BuildContext context, WidgetRef ref) async {
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
      '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}';
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

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              child: Column(
                children: [
                  for (JournalEntry entry in data)
                    JournalListItem(entry: entry),
                  AppTheme.spacer4x,
                ],
              ),
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
