import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/onboarding.dart';
import 'package:scimovement/widgets/button.dart';

class DateSelect extends ConsumerWidget {
  const DateSelect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime date = ref.watch(dateProvider);
    String dateText = ref.watch(dateDisplayProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            ref.read(dateProvider.notifier).state = date.subtract(
              const Duration(days: 1),
            );
          },
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        Button(
          width: 120,
          title: dateText,
          subtitle:
              dateText.length != 10 ? date.toString().substring(0, 10) : null,
          onPressed: () async {
            DateTime? selectedDate = await _selectDate(context, date);

            if (selectedDate != null) {
              ref.read(dateProvider.notifier).state = selectedDate;
            }
          },
        ),
        if (canGoForward(date))
          IconButton(
            onPressed: () {
              ref.read(dateProvider.notifier).state = date.add(
                const Duration(days: 1),
              );
            },
            icon: const Icon(Icons.arrow_forward_ios),
          )
        else
          const SizedBox(width: 48),
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
