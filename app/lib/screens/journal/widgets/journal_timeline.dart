import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';

double headerHeight = 48;

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

class TimelineEvents extends StatelessWidget {
  final DateTime date;

  const TimelineEvents({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: headerHeight + 16),
      child: Container(
        width: (MediaQuery.of(context).size.width / 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
        ),
        child: Center(child: Text('helo')),
      ),
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
    DateTime date = DateTime(DateTime.now().year, DateTime.now().month, 1);
    InfiniteScrollController controller = useMemoized(
      () => InfiniteScrollController(initialScrollOffset: initialPage * 400),
    );
    InfiniteScrollController followController = useMemoized(
      () => InfiniteScrollController(),
    );

    useEffect(() {
      controller.addListener(() {
        followController.jumpTo(controller.position.pixels);
      });
      return () {};
    }, [controller]);

    return ListView(
      shrinkWrap: true,
      children: [
        SizedBox(
          height: 400,
          child: Stack(
            children: [
              ref
                  .watch(journalEventsProvider(
                      const Pagination(mode: ChartMode.quarter)))
                  .when(
                      data: (_) => InfiniteListView.builder(
                            controller: followController,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (BuildContext ctx, int index) {
                              return TimelineEvents(
                                date: DateTime(
                                    date.year, date.month + index, date.day),
                              );
                            },
                          ),
                      error: (_, __) => Center(
                            child: Text('error'),
                          ),
                      loading: () => Center(
                            child: CircularProgressIndicator(),
                          )),
              InfiniteListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext ctx, int index) {
                  return Month(
                    date: DateTime(date.year, date.month + index, date.day),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
