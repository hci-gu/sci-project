import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';

class DateSelect extends ConsumerWidget {
  const DateSelect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime date = ref.watch(dateProvider);
    String dateText = ref.watch(dateDisplayProvider(context));
    String dateSubtitle = ref.watch(subtitleDateDisplayProvider(context));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateText, style: AppTheme.headLine2),
            Text(
              dateSubtitle,
              style: AppTheme.paragraphMedium,
            ),
          ],
        ),
        Button(
          width: 44,
          onPressed: () async {
            DateTime? selectedDate = await _selectDate(context, date);
            if (selectedDate != null) {
              ref.read(dateProvider.notifier).state = selectedDate;
            }
          },
          icon: Icons.calendar_month,
        )
      ],
    );
  }

  DateTime get _now => DateTime.now();
  DateTime get _today => DateTime(_now.year, _now.month, _now.day);
  bool canGoForward(date) => date.isBefore(_today);

  Future<DateTime?> _selectDate(BuildContext context, DateTime date) {
    return showDatePicker(
      context: context,
      initialDate: date,
      firstDate: date.subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
    );
  }
}
