import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';

double headerHeight = 48;
double eventHeight = 40;

double offsetForEvents(List<JournalEvents> events, int index) {
  double offset = 48 + 8;

  for (int i = 0; i < index; i++) {
    offset += eventHeight;
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

class Month extends StatelessWidget {
  final DateTime date;

  const Month({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    String month = DateFormat.MMMM('sv').format(date);
    String monthCapitalized = month[0].toUpperCase() + month.substring(1);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
            ),
            color: Colors.white,
          ),
          height: headerHeight,
          padding: const EdgeInsets.only(top: 4.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthCapitalized,
                style: AppTheme.labelLarge,
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width / 2) - 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                    daysInMonth,
                    (index) {
                      if (index % 4 == 0) {
                        return Day(
                          date: date.add(
                            Duration(
                              days: index * 1,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

class TimelineEvent extends StatelessWidget {
  final JournalEvents events;
  final double heightOffset;
  final int index;
  final DateTime periodStart;
  final DateTime periodEnd;

  const TimelineEvent({
    super.key,
    required this.events,
    required this.index,
    required this.heightOffset,
    required this.periodStart,
    required this.periodEnd,
  });

  @override
  Widget build(BuildContext context) {
    // var offset = 0;
    if (events.end.isBefore(periodStart) || events.start.isAfter(periodEnd)) {
      return const SizedBox();
    }

    final daysInPeriod = periodEnd.difference(periodStart).inDays;
    final dayLength = pageWidth(context) / daysInPeriod;

    final offset = events.start.difference(periodStart).inDays;
    final width = events.duration.inDays + 1;

    return Positioned(
      top: heightOffset,
      left: dayLength * offset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(top: (headerHeight / 2) - 2),
            child: Container(
              width: dayLength * width,
              height: 1,
              color: AppTheme.colors.black.withOpacity(0.2),
            ),
          ),
          ..._body(context),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    switch (events.displayType) {
      case TimelineDisplayType.events:
        return _events(context);
      case TimelineDisplayType.periods:
        break;
      default:
    }
    return [const SizedBox.shrink()];
  }

  List<Widget> _events(BuildContext context) {
    return events.entries
        .map(
          (e) => _dot(context, e),
        )
        .toList();
  }

  Widget _dot(BuildContext context, JournalEntry entry) {
    if (entry.time.isBefore(periodStart) || entry.time.isAfter(periodEnd)) {
      return const SizedBox();
    }

    final daysInPeriod = periodEnd.difference(periodStart).inDays;
    final dayLength = (pageWidth(context) - 32) / daysInPeriod;
    final offset = entry.time.difference(events.start).inDays;

    return Positioned(
      top: (headerHeight / 2) - 5,
      left: offset * dayLength,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: AppTheme.colors.primary,
        ),
      ),
    );
  }
}

class TimelineEvents extends StatelessWidget {
  final DateTime date;
  final List<JournalEvents> events;

  const TimelineEvents({
    super.key,
    required this.date,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    DateTime startOfMonth = DateTime(date.year, date.month, 1);
    DateTime endOfMonth = DateTime(date.year, date.month + 1, 0);

    double width = pageWidth(context);

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: width / 4,
                color: AppTheme.colors.lightGray,
              ),
              _line(width),
              _line(width),
              _line(width),
            ],
          ),
          ...events
              .map(
                (e) => TimelineEvent(
                    events: e,
                    periodStart: startOfMonth,
                    periodEnd: endOfMonth,
                    index: events.indexOf(e),
                    heightOffset: offsetForEvents(events, events.indexOf(e))),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _line(double width) {
    return Container(
      width: width / 4,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: AppTheme.colors.lightGray,
            width: 1,
          ),
        ),
      ),
    );
  }
}

// final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

class EventHandleItem extends StatelessWidget {
  final JournalEvents? event;

  const EventHandleItem(this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        height: eventHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              event?.title(context) ?? '',
              style: AppTheme.labelMedium,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}

class EventHandles extends StatelessWidget {
  List<JournalEvents> events;
  // final DateTime currentDate;

  EventHandles({
    super.key,
    required this.events,
    // required this.currentDate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      // key: listKey,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: events.length,
      itemBuilder: (context, index, animation) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(0, 1),
              end: const Offset(0, 0),
            ),
          ),
          child: EventHandleItem(events[index]),
        );
      },
    );
  }
}

class JournalTimelineWithEvents extends HookWidget {
  final int initialPage;
  final List<JournalEvents> events;

  const JournalTimelineWithEvents({
    super.key,
    required this.initialPage,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    ValueNotifier<int> currentPage = useState(initialPage);
    ValueNotifier<int> visibleItems = useState(events.length);
    DateTime date = DateTime(DateTime.now().year, DateTime.now().month, 1);
    InfiniteScrollController controller = useMemoized(
      () => InfiniteScrollController(
          initialScrollOffset: initialPage * pageWidth(context)),
    );
    InfiniteScrollController followController = useMemoized(
      () => InfiniteScrollController(),
    );

    useEffect(() {
      controller.addListener(() {
        followController.jumpTo(controller.position.pixels);
        int newPage = controller.offset ~/ pageWidth(context);
        if (newPage != currentPage.value) {
          currentPage.value = newPage;
          DateTime displayDate = DateTime(
            date.year,
            date.month + newPage + 2,
            date.day,
          );
          List<JournalEvents> visibleEvents =
              events.where((e) => e.start.isBefore(displayDate)).toList();
          if (visibleEvents.length != visibleItems.value) {
            visibleItems.value = visibleEvents.length;
            // listKey.currentState?.removeAllItems(
            //   (context, animation) => const EventHandleItem(null),
            //   duration: const Duration(milliseconds: 250),
            // );
            // listKey.currentState?.insertAllItems(
            //   events.indexOf(visibleEvents.first),
            //   visibleEvents.length,
            //   duration: const Duration(milliseconds: 250),
            // );
          }
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
                controller: followController,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext ctx, int index) {
                  return TimelineEvents(
                    date: DateTime(
                      date.year,
                      date.month + index,
                      date.day,
                    ),
                    events: events,
                  );
                },
              ),
              InfiniteListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext ctx, int index) {
                  return Month(
                    date: DateTime(
                      date.year,
                      date.month + index,
                      date.day,
                    ),
                  );
                },
              ),
              Positioned(
                top: headerHeight,
                left: 8,
                width: 120,
                height: 600,
                child: EventHandles(
                  events: events,
                  // currentDate: DateTime(
                  //   date.year,
                  //   date.month + currentPage.value + 2,
                  //   date.day,
                  // ),
                ),
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
    return ref
        .watch(
          journalEventsProvider(const Pagination(mode: ChartMode.quarter)),
        )
        .when(
          data: (events) => JournalTimelineWithEvents(
            initialPage: initialPage,
            events: events,
          ),
          error: (_, __) => const Center(child: Text('error')),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }
}
