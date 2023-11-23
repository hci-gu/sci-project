import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_listview/infinite_listview.dart';

import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/screens/journal/widgets/timeline/movement_chart.dart';
import 'package:scimovement/screens/journal/widgets/timeline/pain_chart.dart';
import 'package:scimovement/screens/journal/widgets/timeline/month_header.dart';
import 'package:scimovement/screens/journal/widgets/timeline/sidebar.dart';
import 'package:scimovement/screens/journal/widgets/timeline/utils.dart';
import 'package:scimovement/theme/theme.dart';

class TimeLineEventsData {
  final List<JournalEntry> events;
  final JournalGoal? goal;

  TimeLineEventsData({required this.events, required this.goal});
}

final timeLineEventsProvider =
    FutureProvider.family<TimeLineEventsData, TimelinePage>((ref, page) async {
  List<JournalEntry> events =
      await ref.watch(timelineEventsProvider(page).future);
  JournalGoal? goal;
  if (page.type == TimelineType.pressureRelease) {
    goal = await ref.watch(pressureReleaseGoalProvider(page.pagination).future);
  } else if (page.type == TimelineType.bladderEmptying) {
    goal = await ref.watch(bladderEmptyingGoalProvider(page.pagination).future);
  }

  return TimeLineEventsData(events: events, goal: goal);
});

class TimelineEvents extends ConsumerWidget {
  final TimelinePage page;

  const TimelineEvents({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(timeLineEventsProvider(page)).when(
          data: (data) => _body(context, ref, data.events, data.goal),
          error: (_, __) => Container(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _body(BuildContext context, WidgetRef ref, List<JournalEntry> events,
      JournalGoal? goal) {
    double width = pageWidth(context);
    double dayWidth = width / page.pagination.duration.inDays;

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

            return entries.isNotEmpty
                ? _dot(dayWidth, entries, goal)
                : SizedBox(width: dayWidth);
          },
        ),
      ),
    );
  }

  Widget _dot(double width, List<JournalEntry> entries, JournalGoal? goal) {
    double borderWidth = 5;
    if (goal != null) {
      borderWidth *= math.min(entries.length / goal.value, 1);
    }

    return SizedBox(
      width: width,
      height: eventHeight,
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: AppTheme.colors.primary,
              width: borderWidth,
            ),
          ),
        ),
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
        width: math.max(period.duration.inDays * dayLength, 0),
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

class Month extends HookConsumerWidget {
  final Pagination page;

  const Month({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double sectionWidth = pageWidth(context) / 4;
    ValueNotifier<List<TimelineType>> cachedResponse = useState([]);
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
                clipBehavior: Clip.none,
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

  Widget _list(List<TimelineType> data) {
    return Column(
      children: [
        ...data
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _contentForType(e),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _contentForType(TimelineType type) {
    switch (timelineDisplayType(type)) {
      case TimelineDisplayType.lineChart:
        return TimelinePainChart(
          page: TimelinePage(
            pagination: page,
            type: type,
          ),
        );
      case TimelineDisplayType.barChart:
        return TimelineMovementChart(page: page);
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
            clipBehavior: Clip.none,
            children: [
              // ListView(
              //   scrollDirection: Axis.horizontal,
              //   children: const [
              //     SizedBox(
              //       width: 400,
              //       height: 10,
              //     ),
              //     // Opacity(
              //     //   opacity: 1,
              //     //   child: Month(
              //     //     page: Pagination(mode: ChartMode.month, page: 3),
              //     //   ),
              //     // ),
              //     Opacity(
              //       opacity: 0.5,
              //       child: Month(
              //         page: Pagination(mode: ChartMode.month, page: 1),
              //       ),
              //     ),
              //     Month(
              //       page: Pagination(mode: ChartMode.month, page: 0),
              //     ),
              //     SizedBox(
              //       width: 400,
              //       height: 10,
              //     ),
              //   ],
              // ),
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
                child: const TimelineSidebar(),
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
