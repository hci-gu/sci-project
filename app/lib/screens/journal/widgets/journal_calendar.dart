import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

    return GestureDetector(
      onTap: () {
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
                // fontSize: 11,
                color:
                    isToday ? AppTheme.colors.primary : AppTheme.colors.black,
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
        .watch(journalProvider(Pagination(page: page, mode: ChartMode.month)))
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
    int startIndex = date.weekday - 1;
    int endIndex = startIndex + daysInMonth;

    return Center(
      child: Column(
        children: [
          _header(context, startIndex),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            children: List.generate(
              35,
              (index) {
                if (index < startIndex || index >= endIndex) {
                  return const SizedBox();
                }

                DateTime dayDate = date.add(
                  Duration(days: index - startIndex),
                );

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
      ),
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
        top: 16.0,
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

class WeekdayRow extends StatelessWidget {
  const WeekdayRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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

class JournalCalendar extends StatelessWidget {
  const JournalCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    double itemExtent = (MediaQuery.of(context).size.height * 0.5) - 57;
    DateTime date = DateTime(DateTime.now().year, DateTime.now().month, 1);

    return Column(
      children: [
        const WeekdayRow(),
        Expanded(
          child: InfiniteListView.builder(
            itemExtent: itemExtent,
            physics: const PageScrollPhysics(),
            itemBuilder: (_, index) {
              return JournalCalendarMonth(
                date: DateTime(date.year, date.month + index, date.day),
                page: -index - 1,
              );
            },
          ),
        ),
      ],
    );
  }
}
