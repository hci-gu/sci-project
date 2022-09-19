import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/sedentary.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:go_router/go_router.dart';

final sedentaryWidgetProvider = FutureProvider<WidgetValues>((ref) async {
  int current = await ref.watch(sedentaryProvider(const Pagination()).future);
  int previous =
      await ref.watch(sedentaryProvider(const Pagination(page: 1)).future);
  return WidgetValues(current, previous);
});

class SedentaryWidget extends ConsumerWidget {
  const SedentaryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(sedentaryWidgetProvider).when(
          data: (WidgetValues values) => GestureDetector(
            onTap: () => context.goNamed('sedentary'),
            child: StatWidget(
              values: values,
              unit: Unit.sedentary,
              asset: 'assets/svg/wheelchair.svg',
            ),
          ),
          error: (_, __) => Container(),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
  }
}
