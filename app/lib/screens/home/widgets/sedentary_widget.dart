import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/bouts.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:go_router/go_router.dart';

final sedentaryWidgetProvider = FutureProvider<WidgetValues>((ref) async {
  double current =
      await ref.watch(averageSedentaryBout(const Pagination()).future);
  double previous =
      await ref.watch(averageSedentaryBout(const Pagination(page: 1)).future);
  return WidgetValues(current.round(), previous.round());
});

class SedentaryWidget extends ConsumerWidget {
  const SedentaryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String asset = 'assets/svg/wheelchair.svg';
    return GestureDetector(
      onTap: () => context.goNamed('sedentary'),
      child: ref.watch(sedentaryWidgetProvider).when(
            data: (WidgetValues values) => StatWidget(
              values: values,
              unit: Unit.time,
              asset: asset,
            ),
            error: (_, __) => StatWidget.error(asset),
            loading: () => StatWidget.loading(asset),
          ),
    );
  }
}
