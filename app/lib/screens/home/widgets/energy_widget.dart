import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:go_router/go_router.dart';

final energyWidgetProvider = FutureProvider<WidgetValues>((ref) async {
  int current = await ref.watch(totalEnergyProvider(const Pagination()).future);
  int previous =
      await ref.watch(totalEnergyProvider(const Pagination(page: 1)).future);
  return WidgetValues(current, previous);
});

class EnergyWidget extends ConsumerWidget {
  const EnergyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String asset = 'assets/svg/flame.svg';

    return GestureDetector(
      onTap: () => context.go('${GoRouter.of(context).location}/calories'),
      child: ref.watch(energyWidgetProvider).when(
            data: (WidgetValues values) => StatWidget(
              values: values,
              unit: Unit.calories,
              asset: asset,
            ),
            error: (_, __) => StatWidget.error(asset),
            loading: () => StatWidget.loading(asset),
          ),
    );
  }
}
