import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StatHeader extends ConsumerWidget {
  final Unit unit;
  final bool isAverage;
  final FutureProvider<num> provider;

  const StatHeader({
    Key? key,
    required this.unit,
    required this.provider,
    this.isAverage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime date = ref.watch(dateProvider);
    String dateText = ref.watch(dateDisplayProvider(context));
    String dateSubTitle = ref.watch(subtitleDateDisplayProvider(context));
    Pagination page = ref.watch(paginationProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAverage
              ? AppLocalizations.of(context)!.average
              : AppLocalizations.of(context)!.total,
          style: AppTheme.labelLarge.copyWith(color: AppTheme.colors.gray),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            ref.watch(provider).when(
                  data: (data) => AnimatedDigitWidget(
                    value: data.toInt(),
                    duration: const Duration(milliseconds: 250),
                    textStyle: AppTheme.headLine1.copyWith(letterSpacing: 3),
                  ),
                  error: (_, __) => const Text('-'),
                  loading: () => const CircularProgressIndicator(),
                ),
            Text(
              ' ${unit.displayString()}',
              style: AppTheme.paragraphMedium.copyWith(
                color: AppTheme.colors.gray,
              ),
            )
          ],
        ),
        Text(
          page.mode == ChartMode.day
              ? '$dateText - $dateSubTitle'
              : _displayDateRange(page, date),
          style: AppTheme.labelLarge.copyWith(color: AppTheme.colors.gray),
        ),
      ],
    );
  }

  String _displayDateRange(Pagination page, DateTime date) {
    DateTime from = page.from(date);
    DateTime to = page.to(date);

    return '${DateFormat('MMMd').format(from)} - ${DateFormat('MMMd').format(to)}';
    // return '${} - ${timeago.format(to)}';
  }
}
