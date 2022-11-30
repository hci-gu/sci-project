import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class BodyPartGrid extends ConsumerWidget {
  const BodyPartGrid({Key? key}) : super(key: key);

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
        Text(
          'Lägg till en kroppsdel för att börja spåra din smärta.',
          style: AppTheme.paragraphMedium,
        ),
        AppTheme.spacer2x,
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.33,
          height: MediaQuery.of(context).size.width * 0.33,
          child: _addItem(context),
        ),
      ],
    );
  }

  Widget _buildList(
      BuildContext context, List<JournalEntry> data, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tryck på en kropssdel för att lägga till en ny smärtupplevelse.',
          style: AppTheme.paragraph,
        ),
        AppTheme.spacer,
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.basePadding * 2,
          mainAxisSpacing: AppTheme.basePadding * 2,
          shrinkWrap: true,
          children: [
            ...data
                .map(
                  (e) => GestureDetector(
                    onTap: () => GoRouter.of(context).goNamed(
                      'create-journal',
                      extra: {
                        'bodyPart': e.bodyPart,
                      },
                    ),
                    child: _listItem(e),
                  ),
                )
                .toList(),
            _addItem(context),
          ],
        )
      ],
    );
  }

  Widget _listItem(JournalEntry entry) {
    return Container(
      decoration: AppTheme.widgetDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BodyPartIcon(bodyPart: entry.bodyPart, size: 64),
            AppTheme.spacer,
            Text(
              entry.bodyPart.displayString(),
              style: AppTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            FittedBox(
              child: Text(
                timeago.format(entry.time, locale: 'sv'),
                style: AppTheme.paragraphSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addItem(BuildContext context) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).goNamed('create-journal'),
      child: Container(
        decoration: AppTheme.widgetDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 48),
              Text('Lägg till', style: AppTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
