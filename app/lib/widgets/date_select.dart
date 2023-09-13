import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';

class SelectedDateText extends ConsumerWidget {
  final bool centerAlign;

  const SelectedDateText({
    super.key,
    this.centerAlign = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String dateText = ref.watch(dateDisplayProvider(context));
    String dateSubtitle = ref.watch(subtitleDateDisplayProvider(context));

    return Column(
      crossAxisAlignment:
          centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(dateText, style: AppTheme.headLine2),
        Text(
          dateSubtitle,
          style: AppTheme.paragraphMedium,
        ),
      ],
    );
  }

  DateTime get _now => DateTime.now();
  DateTime get _today => DateTime(_now.year, _now.month, _now.day);
  bool canGoForward(date) => date.isBefore(_today);
}

class DateSelectButton extends ConsumerWidget {
  const DateSelectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      width: 44,
      onPressed: () async {
        DateTime date = ref.read(dateProvider);
        DateTime? selectedDate = await _selectDate(context, date);
        if (selectedDate != null) {
          ref.read(dateProvider.notifier).state = selectedDate;
        }
      },
      icon: Icons.calendar_month,
    );
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime date) {
    return showDatePicker(
      context: context,
      initialDate: date,
      firstDate: date.subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
    );
  }
}
