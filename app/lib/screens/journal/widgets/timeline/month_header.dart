import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/screens/journal/widgets/timeline/utils.dart';
import 'package:scimovement/theme/theme.dart';

class Day extends StatelessWidget {
  final double width;
  final DateTime date;
  final bool selected;
  final bool small;

  const Day({
    super.key,
    required this.width,
    required this.date,
    this.selected = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    bool isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return AnimatedContainer(
      width: date.day <= 1 ? width : null,
      duration: const Duration(milliseconds: 150),
      child: AnimatedScale(
        scale: selected
            ? 1.5
            : small
                ? 0.5
                : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Center(
          child: Text(
            date.day.toString(),
            style: AppTheme.paragraphSmall.copyWith(
              color: isToday ? AppTheme.colors.primary : AppTheme.colors.black,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class MonthHeader extends ConsumerWidget {
  final DateTime date;

  const MonthHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double width = pageWidth(context);
    int daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    String month = DateFormat.MMMM('sv').format(date);
    String monthCapitalized = month[0].toUpperCase() + month.substring(1);
    String year = DateFormat.y('sv').format(date);
    DateTime? touchedDate = ref.watch(timelineTouchedDateProvider);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    monthCapitalized,
                    style: AppTheme.labelLarge,
                  ),
                ),
                if (date.month == 1)
                  Padding(
                    padding: EdgeInsets.only(left: AppTheme.halfPadding),
                    child: Text(
                      year,
                      style: AppTheme.labelLarge.copyWith(
                        color: AppTheme.colors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(
              width: width,
              height: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(
                  daysInMonth,
                  (index) {
                    DateTime dayDate =
                        DateTime(date.year, date.month, index + 1);
                    bool selected = _isSameDay(touchedDate, dayDate);
                    bool showDay =
                        (index % 4 == 0 || _isSameDay(touchedDate, dayDate));
                    double dayWidth = width / daysInMonth;

                    double leftOffset;
                    // if selected and last day of month move to the left
                    if (selected && index == daysInMonth - 1) {
                      leftOffset = -dayWidth / 2;
                    } else {
                      leftOffset = 0;
                    }

                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 150),
                      left: (dayWidth * index) + leftOffset,
                      top: showDay
                          ? selected
                              ? -4
                              : 0
                          : 8,
                      child: showDay
                          ? Day(
                              width: dayWidth,
                              date: dayDate,
                              selected: selected,
                              small: isCloseTo(touchedDate, dayDate),
                            )
                          : Icon(
                              Icons.circle,
                              size: 2,
                              color: AppTheme.colors.lightGray,
                            ),
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

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isCloseTo(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.difference(b).inDays.abs() <= 1;
  }
}
