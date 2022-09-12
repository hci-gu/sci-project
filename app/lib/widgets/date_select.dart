import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/widgets/button.dart';

class DateSelect extends ConsumerWidget {
  const DateSelect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime date = ref.watch(dateProvider);

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
          title: date.toString().substring(0, 10),
          onPressed: () {},
        ),
        IconButton(
          onPressed: () {
            ref.read(dateProvider.notifier).state = date.add(
              const Duration(days: 1),
            );
          },
          icon: const Icon(Icons.arrow_forward),
        )
      ],
    );
  }

  bool canGoForward(date) => date.isBefore(DateTime.now());

  // String _textForButton(ActivityModel activityModel) {
  //   if (!activityModel.canFoForward) {
  //     return 'Today';
  //   }
  //   return activityModel.from.toString().substring(0, 10);
  // }
}
