import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';

class JournalCalendarDay extends ConsumerWidget {
  final DateTime date;
  final List<JournalEntry> journal;

  const JournalCalendarDay({
    super.key,
    required this.date,
    this.journal = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime selectedDate = ref.watch(journalSelectedDateProvider);
    bool isFuture = date.isAfter(DateTime.now());

    return GestureDetector(
      onTap: () {
        if (isFuture) return;
        ref.read(journalSelectedDateProvider.notifier).state = date;
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: borderColor(selectedDate),
            width: selectedDate == date ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                color: isToday
                    ? AppTheme.colors.primary
                    : isFuture
                        ? AppTheme.colors.lightGray
                        : AppTheme.colors.black,
                fontWeight: isToday || selectedDate == date
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            dots(),
          ],
        ),
      ),
    );
  }

  Color borderColor(DateTime selectedDate) {
    if (selectedDate == date) return AppTheme.colors.black;
    return isToday ? AppTheme.colors.primary : AppTheme.colors.lightGray;
  }

  bool get isToday {
    DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget dots() {
    return SizedBox(
      width: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: journal.take(3).map((e) => dot()).toList(),
      ),
    );
  }

  Widget dot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}

class JournalCalendarMonth extends ConsumerWidget {
  final DateTime date;
  final int page;

  const JournalCalendarMonth(
      {super.key, required this.date, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(journalMonthlyProvider(
            Pagination(page: page, mode: ChartMode.month)))
        .when(
          data: (data) => _body(context, data),
          error: (_, __) => Container(),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _body(BuildContext context, List<JournalEntry> journal) {
    int daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    int startIndex = DateTime(date.year, date.month, 1).weekday - 1;
    int endIndex = startIndex + daysInMonth;

    return Column(
      children: [
        _header(context, startIndex),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          children: List.generate(
            42,
            (index) {
              if (index < startIndex || index >= endIndex) {
                return const SizedBox();
              }

              DateTime dayDate = DateTime(
                  date.year, date.month, date.day + index - startIndex);

              return JournalCalendarDay(
                key: ValueKey(dayDate),
                date: dayDate,
                journal:
                    journal.where((e) => e.time.day == dayDate.day).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, int offset) {
    DateTime now = DateTime.now();
    bool isThisMonth = date.year == now.year && date.month == now.month;
    String month = offset >= 6
        ? DateFormat.MMM('sv').format(date)
        : DateFormat.MMMM('sv').format(date);
    String monthCapitalized = month[0].toUpperCase() + month.substring(1);

    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * offset / 7.2,
      ),
      child: Row(
        children: [
          Text(
            monthCapitalized,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: isThisMonth
                  ? const Color.fromRGBO(213, 69, 79, 1.0)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class JournalCalendar extends StatelessWidget {
  final InfiniteScrollController controller;
  final double height;

  const JournalCalendar(
      {super.key, required this.controller, required this.height});

  @override
  Widget build(BuildContext context) {
    DateTime date = DateTime(DateTime.now().year, DateTime.now().month, 1);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.basePadding),
      child: InfiniteListView.builder(
        controller: controller,
        itemExtent: height,
        physics: const PageScrollPhysics(),
        itemBuilder: (_, index) {
          return JournalCalendarMonth(
            date: DateTime(date.year, date.month + index, date.day),
            page: -index - 1,
          );
        },
      ),
    );
  }

  static double heightForPage(BuildContext context, int page) {
    double itemWidth = (MediaQuery.of(context).size.width - 16) / 7;
    DateTime date =
        DateTime(DateTime.now().year, DateTime.now().month + page, 1);
    int daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    int startIndex = date.weekday - 1;

    double headerAndPadding = 24 + 8;
    if (startIndex >= 6 || startIndex >= 5 && daysInMonth > 30) {
      return itemWidth * 6 + headerAndPadding;
    }
    return itemWidth * 5 + headerAndPadding;
  }
}
