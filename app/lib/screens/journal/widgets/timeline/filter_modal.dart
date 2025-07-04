import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/theme/theme.dart';

Future showTimelineFilterModal(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const TimelineFilters(),
  );
}

class TimelineFilters extends ConsumerWidget {
  const TimelineFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<TimelineType, bool> filters = ref.watch(timelineFiltersProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: 400,
          decoration: AppTheme.cardDecoration,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.basePadding * 2,
              vertical: AppTheme.basePadding,
            ),
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter',
                    style: AppTheme.headLine3,
                  ),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
              AppTheme.separator,
              ...filters.entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: AppTheme.basePadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        e.key.displayString(context),
                        style: AppTheme.paragraphMedium,
                      ),
                      CupertinoSwitch(
                        thumbColor: AppTheme.colors.white,
                        activeTrackColor: AppTheme.colors.primary,
                        value: filters[e.key] ?? false,
                        onChanged: (add) async {
                          ref.read(timelineFiltersProvider.notifier).state = {
                            ...filters,
                            e.key: add,
                          };
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
