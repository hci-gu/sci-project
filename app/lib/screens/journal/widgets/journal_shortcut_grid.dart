import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/journal/widgets/entry_shortcut.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class JournalShortcutGrid extends ConsumerWidget {
  const JournalShortcutGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(uniqueEntriesProvider(
            const Pagination(page: 0, mode: ChartMode.quarter)))
        .when(
          data: (data) => data.isEmpty
              ? _emptyState(context)
              : _buildList(context, data, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text(e.toString()),
        );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: AppTheme.screenPadding,
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.journalWelcome,
            style: AppTheme.labelLarge,
          ),
          AppTheme.spacer,
          Text(
            AppLocalizations.of(context)!.journalWelcomeDescription,
            style: AppTheme.paragraphMedium,
          )
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<JournalEntry> data, WidgetRef ref) {
    double size = AppTheme.isBigScreen(context) ? 148 : 120;
    return SizedBox(
      height: size,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          AppTheme.spacer2x,
          ...data.map(
            (e) => Padding(
              padding: EdgeInsets.only(right: AppTheme.basePadding * 2),
              child: SizedBox(
                width: size,
                child: JournalEntryShortcut(
                  onTap: () => context.goNamed(
                    'create-journal',
                    extra: {'entry': e},
                  ),
                  icon: AppTheme.iconForJournalType(
                      e.type,
                      e is PainLevelEntry ? e.bodyPart : null,
                      AppTheme.isBigScreen(context) ? 48 : 40),
                  title: e.shortcutTitle(context),
                  subtitle: timeago.format(e.time),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: AppTheme.basePadding * 2),
            child: SizedBox(
              width: size,
              child: JournalEntryShortcut(
                onTap: () => context.goNamed(
                  'select-journal-type',
                ),
                icon: const Icon(Icons.add),
                title: AppLocalizations.of(context)!.newEntry,
              ),
            ),
          )
        ],
      ),
    );
  }
}
