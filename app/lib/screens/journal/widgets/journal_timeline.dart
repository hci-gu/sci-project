import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/screens/journal/widgets/timeline/chart.dart';
import 'package:scimovement/theme/theme.dart';

double headerHeight = 48;
double eventHeight = 44;
double chartEventHeight = 120;

enum TimelineMode {
  day,
  week,
  month,
}

TimelineMode activeMode = TimelineMode.month;

double heightForType(TimelineDisplayType type) {
  if (type == TimelineDisplayType.chart) {
    return chartEventHeight;
  }
  return eventHeight;
}

double offsetForEvents(List<JournalType> types, int index) {
  double offset = 48 + 8;

  for (int i = 0; i < index; i++) {
    offset += heightForType(timelineDisplayTypeForJournalType(types[i]));
    offset += 8;
  }

  return offset;
}

double pageWidth(BuildContext context) {
  return MediaQuery.of(context).size.width / 2;
}

class Day extends StatelessWidget {
  final DateTime date;

  const Day({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    bool isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Center(
      child: Text(
        date.day.toString(),
        style: AppTheme.paragraphSmall.copyWith(
          color: isToday ? AppTheme.colors.primary : AppTheme.colors.black,
        ),
      ),
    );
  }
}

class MonthHeader extends StatelessWidget {
  final DateTime date;

  const MonthHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    String month = DateFormat.MMMM('sv').format(date);
    String monthCapitalized = month[0].toUpperCase() + month.substring(1);

    return SizedBox(
      width: pageWidth(context),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.colors.lightGray),
            left: BorderSide(color: AppTheme.colors.lightGray),
            bottom: BorderSide(color: AppTheme.colors.lightGray),
          ),
          color: Colors.white,
        ),
        height: headerHeight,
        padding: const EdgeInsets.only(top: 4.0, left: 8.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthCapitalized,
              style: AppTheme.labelLarge,
            ),
            SizedBox(
              width: pageWidth(context) - 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(
                  daysInMonth,
                  (index) {
                    if (index % 4 == 0) {
                      return Day(
                        date: DateTime(date.year, date.month, index + 1),
                      );
                    }
                    return Icon(
                      Icons.circle,
                      size: 2,
                      color: AppTheme.colors.lightGray,
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TimelineEvents extends ConsumerWidget {
  final TimelinePage page;

  const TimelineEvents({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(timelineEventsProvider(page)).when(
          data: (data) => _body(data),
          error: (_, __) => Container(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _body(List<JournalEntry> events) {
    return SizedBox(
      height: eventHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          page.pagination.duration.inDays,
          (index) {
            List<JournalEntry> entries = events
                .where((e) =>
                    e.time.isAfter(
                        page.pagination.from.add(Duration(days: index))) &&
                    e.time.isBefore(
                        page.pagination.from.add(Duration(days: index + 1))))
                .toList();

            return entries.isNotEmpty ? _dot() : const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: AppTheme.colors.primary,
      ),
    );
  }
}

class TimelinePeriods extends ConsumerWidget {
  final TimelinePage page;

  const TimelinePeriods({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(timelinePeriodsProvider(page)).when(
          data: (data) => _body(context, data),
          error: (_, __) => Container(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _body(BuildContext context, List<Period> periods) {
    return SizedBox(
      height: eventHeight,
      child: Stack(
        children: [
          ...periods.map((e) => _period(context, e)).toList(),
        ],
      ),
    );
  }

  Widget _period(BuildContext context, Period period) {
    bool endsAfterPeriod = period.end.isAfter(page.pagination.to);
    Radius radius = const Radius.circular(4);
    final dayLength = pageWidth(context) / page.pagination.duration.inDays;
    final offset = period.start.difference(page.pagination.from).inDays;

    return Positioned(
      top: eventHeight / 2 - 4,
      left: offset * dayLength,
      child: Container(
        width: math.max(period.duration.inDays * dayLength, 8),
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: radius,
            bottomLeft: radius,
            topRight: endsAfterPeriod ? Radius.zero : radius,
            bottomRight: endsAfterPeriod ? Radius.zero : radius,
          ),
          color: period.color,
        ),
      ),
    );
  }
}

class TimelinePainChart extends ConsumerWidget {
  final TimelinePage page;

  const TimelinePainChart({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(timelinePainChartProvider(page)).when(
          data: (data) => _body(context, data),
          error: (_, __) => Container(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _body(BuildContext context, List<PainLevelEntry> entries) {
    if (entries.isEmpty) {
      return SizedBox(height: chartEventHeight);
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppTheme.basePadding),
      height: chartEventHeight,
      child: TimelineChart(
        start: page.pagination.from,
        end: page.pagination.to,
        entries: entries,
      ),
    );
  }
}

class Month extends HookConsumerWidget {
  final Pagination page;

  const Month({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double sectionWidth = pageWidth(context) / 4;
    ValueNotifier<List<JournalType>> cachedResponse = useState([]);
    final fetch = ref.watch(timelineTypesProvider(page));

    useEffect(() {
      cachedResponse.value = fetch.value ?? [];

      return () {};
    }, [fetch]);

    return ClipRRect(
      child: SizedBox(
        width: pageWidth(context),
        child: Column(
          children: [
            MonthHeader(
              date: page.from,
            ),
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: sectionWidth,
                        color: AppTheme.colors.lightGray.withOpacity(0.5),
                      ),
                      _line(sectionWidth),
                      _line(sectionWidth),
                      _line(sectionWidth),
                    ],
                  ),
                  fetch.when(
                    data: (data) => _list(data),
                    error: (_, __) => const SizedBox.shrink(),
                    loading: () => cachedResponse.value.isNotEmpty
                        ? _list(cachedResponse.value)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<JournalType> data) {
    return Column(
      children: data
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _contentForType(e),
            ),
          )
          .toList(),
    );
  }

  Widget _contentForType(JournalType type) {
    switch (timelineDisplayTypeForJournalType(type)) {
      case TimelineDisplayType.chart:
        return TimelinePainChart(
          page: TimelinePage(
            pagination: page,
            type: type,
          ),
        );
      case TimelineDisplayType.periods:
        return TimelinePeriods(
          page: TimelinePage(
            pagination: page,
            type: type,
          ),
        );
      case TimelineDisplayType.events:
      default:
        return TimelineEvents(
          page: TimelinePage(
            pagination: page,
            type: type,
          ),
        );
    }
  }

  Widget _line(double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppTheme.colors.lightGray,
            width: 1,
          ),
        ),
      ),
    );
  }
}

class EventHandleItem extends ConsumerWidget {
  final JournalType type;

  const EventHandleItem(this.type, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        width: 160,
        height: heightForType(timelineDisplayTypeForJournalType(type)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  height: 24,
                  child: AutoSizeText(
                    type.displayString(context),
                    maxLines: 2,
                    style: AppTheme.labelMedium,
                    minFontSize: 10,
                  ),
                ),
                AppTheme.spacer,
                _contentForType(context, ref),
              ],
            ),
            if (type == JournalType.pain)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.basePadding),
                child: Container(
                  padding: EdgeInsets.only(left: AppTheme.halfPadding),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppTheme.colors.lightGray),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [10, 7, 5, 3, 1]
                        .map((value) => Text(
                              value.toString(),
                              style: AppTheme.labelXTiny,
                            ))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _contentForType(BuildContext context, WidgetRef ref) {
    List<DateTime> visibleRange = ref.watch(timelineVisibleRangeProvider);

    switch (type) {
      case JournalType.pain:
        return ref
            .watch(
              timelinePainChartProvider(
                TimelinePage(
                  pagination: const Pagination(mode: ChartMode.year, page: 0),
                  type: type,
                ),
              ),
            )
            .when(
              data: (data) {
                final items = data
                    .where((e) =>
                        e.time.isAfter(visibleRange.first) &&
                        e.time.isBefore(visibleRange.last))
                    .map((e) => e.bodyPart)
                    .toSet()
                    .toList();

                return SizedBox(
                  height: 88,
                  width: 120,
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.colors.black,
                                width: 1,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                              color:
                                  AppTheme.colors.bodyPartToColor(items[index]),
                            ),
                          ),
                          AppTheme.spacerHalf,
                          BodyPartIcon(
                            bodyPart: items[index],
                            size: 18,
                          ),
                          AppTheme.spacer,
                          Expanded(
                            child: AutoSizeText(
                              items[index].displayString(context),
                              style: AppTheme.paragraphSmall,
                              maxLines: 1,
                              minFontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              error: (_, __) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            );
      default:
    }
    return const SizedBox.shrink();
  }
}

class EventHandles extends HookConsumerWidget {
  const EventHandles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Pagination page = ref.watch(timelinePaginationProvider);
    ValueNotifier<List<JournalType>> cachedResponse = useState([]);

    final fetch = ref.watch(timelineTypesProvider(page));

    useEffect(() {
      cachedResponse.value = fetch.value ?? [];

      return () {};
    }, [fetch]);

    return fetch.when(
      data: (data) => Column(
        children: data.map((e) => EventHandleItem(e)).toList(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      loading: () => cachedResponse.value.isNotEmpty
          ? Column(
              children:
                  cachedResponse.value.map((e) => EventHandleItem(e)).toList(),
            )
          : const SizedBox.shrink(),
    );
  }
}

GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

class JournalTimelineWithEvents extends HookConsumerWidget {
  final int initialPage;

  const JournalTimelineWithEvents({
    super.key,
    required this.initialPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<int> currentPage = useState(initialPage);
    InfiniteScrollController controller = useMemoized(
      () => InfiniteScrollController(),
    );

    useEffect(() {
      controller.addListener(() {
        int newPage = controller.offset ~/ pageWidth(context);
        if (newPage != currentPage.value) {
          currentPage.value = newPage;
          ref.read(timelinePaginationProvider.notifier).state = Pagination(
            mode: ChartMode.month,
            page: newPage,
          );
        }
      });
      return () {};
    }, [controller]);

    return ListView(
      shrinkWrap: true,
      children: [
        SizedBox(
          height: 600,
          child: Stack(
            children: [
              InfiniteListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemBuilder: (BuildContext ctx, int index) {
                  return Month(
                    page: Pagination(mode: ChartMode.month, page: index),
                  );
                },
              ),
              Positioned(
                top: headerHeight,
                left: AppTheme.basePadding +
                    MediaQuery.of(context).viewPadding.left,
                width: 160,
                height: 600,
                child: const EventHandles(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class JournalTimeline extends HookConsumerWidget {
  final int initialPage;

  const JournalTimeline({
    super.key,
    required this.initialPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return JournalTimelineWithEvents(
      initialPage: initialPage,
    );
  }
}
