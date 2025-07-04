import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';

class ChartModeSelect extends ConsumerWidget {
  const ChartModeSelect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.colors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.0),
        child: DropdownButton<ChartMode>(
          isDense: true,
          items:
              [ChartMode.day, ChartMode.week, ChartMode.month, ChartMode.year]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.displayName(context)),
                    ),
                  )
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
          style: AppTheme.labelLarge.copyWith(color: AppTheme.colors.white),
          icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.colors.white),
          dropdownColor: AppTheme.colors.primary,
          borderRadius: BorderRadius.circular(16),
          underline: Container(),
          value: ref.watch(paginationProvider).mode,
        ),
      ),
    );
  }
}
