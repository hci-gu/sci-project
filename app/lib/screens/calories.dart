import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/models/energy.dart';
import 'package:scimovement/models/config.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/energy_bar_chart.dart';
import 'package:scimovement/widgets/energy_display.dart';
import 'package:scimovement/widgets/stat_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class CaloriesScreen extends HookConsumerWidget {
  final ScrollController controller = ScrollController();

  CaloriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      void scrollListener() {
        var nextPageTrigger = 0.8 * controller.position.maxScrollExtent;

        if (controller.position.pixels > nextPageTrigger) {}
      }

      controller.addListener(scrollListener);
      return () => controller.removeListener(scrollListener);
    });

    return Scaffold(
      appBar: AppTheme.appBar('Calories'),
      body: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const StatHeader(unit: Unit.calories),
                const ChartModeSelect()
              ],
            ),
            _separator(),
            _isDay(ref)
                ? const EnergyDisplay(isCard: false)
                : const EnergyBarChart(),
            // SizedBox(
            //   height: 200,
            //   child: ListView(
            //     controller: controller,
            //     scrollDirection: Axis.horizontal,
            //     reverse: true,
            //     children: [
            //       SizedBox(
            //         width: MediaQuery.of(context).size.width - 64,
            //         child: const EnergyDisplay(isCard: false),
            //       ),
            //       SizedBox(
            //         width: MediaQuery.of(context).size.width - 64,
            //         child: const EnergyDisplay(isCard: false),
            //       ),
            //     ],
            //   ),
            // ),
            _separator(),
          ],
        ),
      ),
    );
  }

  bool _isDay(WidgetRef ref) {
    return ref.watch(chartModeProvider) == ChartMode.day;
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        height: 1,
        color: const Color.fromRGBO(0, 0, 0, 0.1),
      ),
    );
  }
}

class ChartModeSelect extends ConsumerWidget {
  const ChartModeSelect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<ChartMode>(
      items: ChartMode.values
          .map((e) => DropdownMenuItem(child: Text(e.name), value: e))
          .toList(),
      onChanged: (value) {
        if (value != null) ref.read(chartModeProvider.notifier).state = value;
      },
      value: ref.watch(chartModeProvider),
    );
  }
}

class StatHeader extends ConsumerWidget {
  final Unit unit;

  const StatHeader({
    Key? key,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime date = ref.watch(dateProvider);
    String dateText = ref.watch(dateDisplayProvider);
    ChartMode mode = ref.watch(chartModeProvider);
    Pagination page = Pagination(page: 0, mode: mode);
    bool showAverage = mode == ChartMode.day ? false : true;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showAverage ? 'Average' : 'Total',
          style: AppTheme.labelLarge.copyWith(color: AppTheme.colors.gray),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            ref
                .watch(
                  showAverage
                      ? averageEnergyProvider(page)
                      : totalEnergyProvider(page),
                )
                .when(
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
          showAverage ? _displayDateRange(page, date) : dateText,
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
