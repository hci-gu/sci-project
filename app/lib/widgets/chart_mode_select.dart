import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/config.dart';

class ChartModeSelect extends ConsumerWidget {
  const ChartModeSelect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<ChartMode>(
      items: ChartMode.values
          .map((e) => DropdownMenuItem(child: Text(e.name), value: e))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          Pagination page = ref.read(paginationProvider);
          ref.read(paginationProvider.notifier).state = Pagination(
            page: page.page,
            mode: value,
          );
        }
      },
      value: ref.watch(paginationProvider).mode,
    );
  }
}
