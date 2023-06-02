import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timelines/timelines.dart';

class JournalEvent {
  final DateTime date;
  final List<JournalEntry> entries;

  JournalEvent(this.date, this.entries);
}

class JournalTimeline {
  final List<JournalEntry> journal;

  JournalTimeline(this.journal);

  List<JournalEvent> get events {
    Map<DateTime, List<JournalEntry>> grouped = groupBy(
      journal,
      (entry) => DateTime(
        entry.time.year,
        entry.time.month,
        entry.time.day,
      ),
    );

    return grouped.entries
        .map((entry) => JournalEvent(entry.key, entry.value))
        .toList();
  }
}

class JournalListScreen extends HookConsumerWidget {
  final JournalType? type;

  const JournalListScreen({
    super.key,
    this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(journalTypeFilterProvider.notifier).state = type;
      });
      return () => {};
    }, [type]);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.logbook),
        actions: [
          _typeFilter(context, ref),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppTheme.basePadding),
        child: ref
            .watch(filteredJournalProvider(
                const Pagination(page: 0, mode: ChartMode.quarter)))
            .when(
              data: (data) => data.isEmpty
                  ? _emptyState(context)
                  : _buildList(
                      context,
                      JournalTimeline(data.reversed.toList()),
                      ref,
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text(e.toString()),
            ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.journalNoData,
      ),
    );
  }

  Widget _typeFilter(BuildContext context, WidgetRef ref) {
    JournalType? filter = ref.watch(journalTypeFilterProvider);

    return PopupMenuButton<JournalType>(
      icon: filter == null
          ? const Icon(Icons.filter_list)
          : Text(filter.displayString(context)),
      onSelected: (filter) {
        ref.read(journalTypeFilterProvider.notifier).state = filter;
      },
      onCanceled: () {
        ref.read(journalTypeFilterProvider.notifier).state = null;
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text(AppLocalizations.of(context)!.all),
        ),
        ...JournalType.values.map(
          (e) => PopupMenuItem(
            value: e,
            child: Text(e.displayString(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
      BuildContext context, JournalTimeline timeline, WidgetRef ref) {
    return Timeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        color: AppTheme.colors.black.withOpacity(0.4),
        indicatorTheme: const IndicatorThemeData(
          position: 0,
          size: 16.0,
        ),
        connectorTheme: const ConnectorThemeData(
          thickness: 2,
        ),
      ),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.before,
        // contentsAlign: ContentsAlign.reverse,
        itemCount: timeline.events.length,
        contentsBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: JournalGroupItem(event: timeline.events[index]),
        ),
        indicatorBuilder: (_, index) => const OutlinedDotIndicator(
          position: 0,
        ),
        connectorBuilder: (_, index, ___) => const SolidLineConnector(
          color: null,
        ),
      ),
    );
  }
}

class JournalGroupItem extends HookWidget {
  final JournalEvent event;

  const JournalGroupItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> opened = useState(true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        GestureDetector(
          onTap: () {
            opened.value = !opened.value;
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayDate(context, event.date),
                      style: AppTheme.labelLarge),
                  Text(displayDateSubtitle(context, event.date)),
                ],
              ),
              AnimatedRotation(
                turns: opened.value ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: opened.value
              ? _InnerTimeline(entries: event.entries, opened: opened.value)
              : _InnerTimeline(entries: [], opened: opened.value),
        ),
      ],
    );
  }
}

class _InnerTimeline extends StatelessWidget {
  final List<JournalEntry> entries;
  final bool opened;

  const _InnerTimeline({
    required this.entries,
    this.opened = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isEdgeIndex(int index) {
      return index == 0 || index == entries.length + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FixedTimeline.tileBuilder(
        theme: TimelineTheme.of(context).copyWith(
          nodePosition: 0,
          connectorTheme: TimelineTheme.of(context).connectorTheme.copyWith(
                thickness: 1.0,
              ),
          indicatorTheme: TimelineTheme.of(context).indicatorTheme.copyWith(
                size: 10.0,
                position: 0.1,
              ),
        ),
        builder: TimelineTileBuilder(
          indicatorBuilder: (_, index) =>
              !isEdgeIndex(index) ? Indicator.outlined(borderWidth: 1.0) : null,
          startConnectorBuilder: (_, index) => Connector.solidLine(),
          endConnectorBuilder: (_, index) => Connector.solidLine(),
          contentsBuilder: (_, index) {
            if (isEdgeIndex(index)) {
              return null;
            }

            return JournalTimelineRow(
              entry: entries[index - 1],
            );
          },
          // itemExtentBuilder: (_, index) => isEdgeIndex(index) ? 10.0 : 72.0,
          nodeItemOverlapBuilder: (_, index) =>
              isEdgeIndex(index) ? true : null,
          itemCount: entries.length + 1,
        ),
      ),
    );
  }
}

class JournalTimelineRow extends StatelessWidget {
  final JournalEntry entry;

  const JournalTimelineRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        behavior: HitTestBehavior.opaque,
        child: _body(context));
  }

  Widget _contentForType(BuildContext context) {
    switch (entry.type) {
      case JournalType.pressureUlcer:
        PressureUlcerEntry pressureUlcerEntry = entry as PressureUlcerEntry;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pressureUlcerEntry.title(context),
                      style: AppTheme.labelMedium,
                    ),
                    AppTheme.spacer,
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: pressureUlcerEntry.pressureUlcerType.color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.colors.black.withOpacity(0.1)),
                      ),
                    ),
                    AppTheme.spacer,
                    Text(
                      pressureUlcerEntry.pressureUlcerType
                          .displayString(context),
                      style: AppTheme.paragraphMedium,
                    ),
                  ],
                ),
                Text(DateFormat(DateFormat.HOUR24_MINUTE).format(entry.time)),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        );
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title(context),
                  style: AppTheme.labelMedium,
                ),
                Text(DateFormat(DateFormat.HOUR24_MINUTE).format(entry.time)),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        );
    }
  }

  Widget _body(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AppTheme.basePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _contentForType(context),
          if (entry.comment.isNotEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.basePadding),
                child: Text(entry.comment),
              ),
            ),
          AppTheme.separatorSmall,
        ],
      ),
    );
  }
}
