import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/screens/journal/widgets/entry_shortcut.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class JournalShortcutGrid extends ConsumerWidget {
  const JournalShortcutGrid({Key? key}) : super(key: key);

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
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.journalWelcome,
          style: AppTheme.labelLarge,
        ),
        AppTheme.spacer,
        Text(
          '',
          style: AppTheme.paragraphMedium,
        )
      ],
    );
  }

  Widget _buildList(
      BuildContext context, List<JournalEntry> data, WidgetRef ref) {
    return SizedBox(
      height: 148,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: data
            .map(
              (e) => Padding(
                padding: EdgeInsets.only(right: AppTheme.basePadding * 2),
                child: SizedBox(
                  width: 148,
                  child: JournalEntryShortcut(
                    onTap: () => context.goNamed(
                      'create-journal',
                      extra: {'entry': e},
                    ),
                    icon: _iconForEntry(e),
                    title: e.shortcutTitle(context),
                    subtitle: timeago.format(e.time),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _iconForEntry(JournalEntry entry) {
    if (entry is PainLevelEntry) {
      return BodyPartIcon(
        bodyPart: entry.bodyPart,
        size: 48,
      );
    }
    if (entry is PressureReleaseEntry) {
      return const Icon(Icons.alarm, size: 48);
    }
    return const Icon(Icons.album_outlined);
  }
}
