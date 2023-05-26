import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class JournalShortcutGrid extends ConsumerWidget {
  const JournalShortcutGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(uniqueEntriesProvider).when(
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
        Text('Välkommen till loggboken!', style: AppTheme.labelLarge),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: AppTheme.basePadding * 2,
          mainAxisSpacing: AppTheme.basePadding * 2,
          shrinkWrap: true,
          children: [
            ...data
                .map(
                  (e) => GestureDetector(
                    onTap: () => GoRouter.of(context).goNamed(
                      'create-journal',
                      extra: {'entry': e},
                    ),
                    child: _listItem(context, e),
                  ),
                )
                .toList(),
          ],
        )
      ],
    );
  }

  Widget _listItem(BuildContext context, JournalEntry entry) {
    return Container(
      decoration: AppTheme.widgetDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BodyPartIcon(bodyPart: entry.bodyPart, size: 48),
            AppTheme.spacer,
            Text(
              entry.shortcutTitle(context),
              style: AppTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            FittedBox(
              child: Text(
                timeago.format(entry.time),
                style: AppTheme.paragraphSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
