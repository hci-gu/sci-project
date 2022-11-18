import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/screens/journal/widgets/journal_chart.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class JournalScreen extends ConsumerWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: AppTheme.screenPadding,
      children: [
        const JournalChart(),
        AppTheme.separator,
        Text('Spåra smärta', style: AppTheme.headLine3),
        Text(
          'Här kan du se de kroppsdelar du spårar samt lägga till nya',
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
        const JournalList(),
      ],
    );
  }
}

class JournalList extends ConsumerWidget {
  const JournalList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(uniqueEntriesProvider).when(
          data: (data) => _buildList(context, data, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text(e.toString()),
        );
  }

  Widget _buildList(
      BuildContext context, List<JournalEntry> data, WidgetRef ref) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: AppTheme.basePadding,
      mainAxisSpacing: AppTheme.basePadding,
      shrinkWrap: true,
      children: [
        ...data
            .map(
              (e) => GestureDetector(
                onTap: () => GoRouter.of(context).goNamed(
                  'create-journal',
                  extra: {
                    'bodyPart': e.bodyPart,
                    'arm': e.arm,
                  },
                ),
                child: _listItem(e),
              ),
            )
            .toList(),
        GestureDetector(
          onTap: () => GoRouter.of(context).goNamed('create-journal'),
          child: Container(
            decoration: AppTheme.widgetDecoration,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add),
                  Text('Lägg till', style: AppTheme.labelMedium),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _listItem(JournalEntry entry) {
    return Container(
      decoration: AppTheme.widgetDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BodyPartIcon(bodyPart: entry.bodyPart, arm: entry.arm, size: 32),
            Text(
              '${entry.arm != null ? '${entry.arm!.displayString()} ' : ''}${entry.bodyPart.displayString()}',
              style: AppTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            Text(timeago.format(entry.time, locale: 'sv'),
                style: AppTheme.paragraphSmall),
          ],
        ),
      ),
    );
  }
}
