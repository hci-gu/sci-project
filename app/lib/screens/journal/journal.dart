import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/screens/journal/widgets/journal_calendar.dart';
import 'package:scimovement/screens/journal/widgets/journal_list.dart';
import 'package:scimovement/screens/journal/widgets/journal_shortcut_grid.dart';
import 'package:scimovement/screens/journal/widgets/journal_timeline.dart';
import 'package:scimovement/screens/journal/widgets/timeline/filter_modal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/button.dart';

class JournalScreen extends HookConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool showTimeline = ref.watch(showTimelineProvider);

    return Scaffold(
      appBar: showTimeline
          ? null
          : AppTheme.appBar(
              AppLocalizations.of(context)!.logbook,
              [
                IconButton(
                  onPressed: () {
                    ref.read(journalSelectedDateProvider.notifier).state =
                        DateTime.now();
                  },
                  icon: const Icon(Icons.today_outlined),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(showTimelineProvider.notifier).toggle();
                  },
                  icon: const Icon(Icons.timeline_outlined),
                ),
              ],
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return JournalScroller(
            height: constraints.maxHeight - 18,
          );
        },
      ),
      floatingActionButton: showTimeline
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    // ref.read(showTimelineProvider.notifier).state = false;
                    showTimelineFilterModal(context);
                  },
                  child: const Icon(Icons.filter_alt),
                ),
                AppTheme.spacer,
                FloatingActionButton(
                  onPressed: () {
                    ref.read(showTimelineProvider.notifier).toggle();
                  },
                  child: const Icon(Icons.undo),
                ),
              ],
            )
          : isToday(ref.watch(journalSelectedDateProvider))
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    DateTime selectedDate =
                        ref.watch(journalSelectedDateProvider);
                    GoRouter.of(context).goNamed(
                      'select-journal-type',
                      extra: {
                        'date': DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          12,
                        ),
                      },
                    );
                  },
                  child: const Icon(Icons.add),
                ),
    );
  }

  bool isToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }
}

class JournalScroller extends HookConsumerWidget {
  final double height;

  const JournalScroller({
    super.key,
    required this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime selectedDate = ref.watch(journalSelectedDateProvider);
    ValueNotifier<int> currentPage = useState(0);
    InfiniteScrollController scrollController =
        useMemoized(() => InfiniteScrollController());

    useEffect(() {
      scrollController.addListener(() {
        int newPage = scrollController.offset ~/ height;
        if (newPage != currentPage.value) {
          currentPage.value = newPage;
        }
      });

      return () {
        scrollController.dispose();
      };
    }, []);

    useEffect(() {
      if (!scrollController.hasClients) return () => {};
      DateTime now = DateTime.now();
      if (selectedDate.day == now.day &&
          selectedDate.month == now.month &&
          selectedDate.year == now.year) {
        scrollController.jumpTo(0);
      }

      return () => {};
    }, [selectedDate]);

    double listHeight =
        height - JournalCalendar.heightForPage(context, currentPage.value);

    if (ref.watch(showTimelineProvider)) {
      return JournalTimeline(initialPage: currentPage.value - 2);
    }

    return Column(
      children: [
        const WeekdayRow(),
        Expanded(
          child: Stack(
            children: [
              JournalCalendar(
                controller: scrollController,
                height: height,
              ),
              Positioned(
                top: JournalCalendar.heightForPage(context, currentPage.value),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: math.max(0, listHeight),
                    child: ListBottomSheet(
                      onPageChanged: (Direction dir) {
                        currentPage.value += dir == Direction.up ? -1 : 1;
                        scrollController.jumpTo(
                          scrollController.offset +
                              (dir == Direction.up ? -height : height),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum Direction { up, down }

class ListBottomSheet extends HookConsumerWidget {
  final Function onPageChanged;

  const ListBottomSheet({super.key, required this.onPageChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime date = ref.watch(journalSelectedDateProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.colors.lightGray,
            width: 1,
          ),
        ),
        color: AppTheme.colors.background,
      ),
      child: ListView(
        children: [
          _dateHeader(context, ref, date),
          AppTheme.spacer,
          if (isToday(date)) _createEntry(context),
          const JournalList(),
        ],
      ),
    );
  }

  Widget _createEntry(BuildContext context) {
    return Column(
      children: [
        const JournalShortcutGrid(),
        AppTheme.spacer2x,
        _addItem(context),
        AppTheme.spacer2x,
      ],
    );
  }

  Widget _dateHeader(BuildContext context, WidgetRef ref, DateTime date) {
    bool isTodayOrFuture = isToday(date) || date.isAfter(DateTime.now());

    return Padding(
      padding: AppTheme.elementPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              DateTime newdate = date.subtract(const Duration(days: 1));
              ref.read(journalSelectedDateProvider.notifier).state = newdate;
              if (newdate.month < date.month || newdate.year < date.year) {
                onPageChanged(Direction.up);
              }
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat.MMMMd('sv').format(date),
            textAlign: TextAlign.center,
            style: AppTheme.headLine3,
          ),
          Opacity(
            opacity: isTodayOrFuture ? 0.33 : 1,
            child: IconButton(
              onPressed: () {
                if (isTodayOrFuture) return;
                DateTime newdate = date.add(const Duration(days: 1));
                ref.read(journalSelectedDateProvider.notifier).state = newdate;
                if (newdate.month > date.month || newdate.year > date.year) {
                  onPageChanged(Direction.down);
                }
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }

  bool isToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }

  Widget _addItem(BuildContext context) {
    return Center(
      child: Button(
        width: 200,
        icon: Icons.add,
        title: AppLocalizations.of(context)!.newEntry,
        onPressed: () => GoRouter.of(context).goNamed('select-journal-type'),
      ),
    );
  }
}

class WeekdayRow extends StatelessWidget {
  const WeekdayRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        children: [
          _weekday(AppLocalizations.of(context)!.monday),
          _weekday(AppLocalizations.of(context)!.tuesday),
          _weekday(AppLocalizations.of(context)!.wednesday),
          _weekday(AppLocalizations.of(context)!.thursday),
          _weekday(AppLocalizations.of(context)!.friday),
          _weekday(AppLocalizations.of(context)!.saturday),
          _weekday(AppLocalizations.of(context)!.sunday),
        ],
      ),
    );
  }

  Widget _weekday(String day) {
    return Expanded(
      child: Text(
        day.substring(0, 1).toUpperCase(),
        textAlign: TextAlign.center,
        style: AppTheme.labelTiny,
      ),
    );
  }
}
