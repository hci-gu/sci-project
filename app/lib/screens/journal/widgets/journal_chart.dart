import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/auth.dart';
import 'package:scimovement/models/chart.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/charts/movement_bar_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

double chartHeight = 280;

class JournalChartValue {
  final DateTime time;
  final double? value;
  final BodyPart? bodyPart;
  final String? comment;

  const JournalChartValue({
    required this.time,
    this.value,
    this.bodyPart,
    this.comment,
  });
}

class JournalChartValues {
  final Map<BodyPart, List<JournalChartValue>> entries;

  const JournalChartValues(this.entries);

  bool get isEmpty => entries.isEmpty;

  double get minX => entries.values
      .map((e) => e.map((e) => e.time).reduce(
          (value, element) => value.isBefore(element) ? value : element))
      .reduce((value, element) => value.isBefore(element) ? value : element)
      .millisecondsSinceEpoch
      .toDouble();
  double get maxX => entries.values
      .map((e) => e
          .map((e) => e.time)
          .reduce((value, element) => value.isAfter(element) ? value : element))
      .reduce((value, element) => value.isAfter(element) ? value : element)
      .millisecondsSinceEpoch
      .toDouble();

  int get days => (maxX - minX) ~/ (1000 * 60 * 60 * 24);
}

DateTime _getDay(DateTime time) {
  return DateTime(time.year, time.month, time.day);
}

final journalChartProvider = FutureProvider<JournalChartValues>((ref) async {
  List<JournalEntry> journal = await ref.watch(journalProvider.future);

  if (journal.isEmpty) {
    return const JournalChartValues({});
  }

  // filter out all unique journal entries based on bodyPart
  DateTime monthAgo =
      _getDay(DateTime.now().subtract(const Duration(days: 30)));
  DateTime minDate = _getDay(
      journal.last.time.isBefore(monthAgo) ? journal.last.time : monthAgo);
  DateTime maxDate = _getDay(DateTime.now());
  int days = maxDate.difference(minDate).inDays;

  List<BodyPart> bodyParts = [];
  for (JournalEntry entry in journal) {
    if (!bodyParts.any((e) => e == entry.bodyPart)) {
      bodyParts.add(entry.bodyPart);
    }
  }

  Map<BodyPart, List<JournalChartValue>> entries = {};
  for (BodyPart bodyPart in bodyParts) {
    entries[bodyPart] = List.generate(days, (index) {
      DateTime date = _getDay(maxDate.subtract(Duration(days: index)));

      List<JournalEntry> entries = journal
          .where((e) =>
              e.bodyPart == bodyPart && _getDay(e.time).isAtSameMomentAs(date))
          .toList();
      double? value = entries.isEmpty
          ? null
          : entries
                  .map((e) => e.painLevel)
                  .reduce((value, element) => value + element) /
              entries.length;
      String? comment =
          entries.isEmpty ? null : entries.map((e) => e.comment).join('\n');
      return JournalChartValue(
        time: date,
        value: value,
        bodyPart: bodyPart,
        comment: comment,
      );
    });
  }

  return JournalChartValues(entries);
});

class JournalChart extends HookConsumerWidget {
  const JournalChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: chartHeight,
      child: ref.watch(journalChartProvider).when(
            data: (data) => _body(context, data, ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text(e.toString()),
          ),
    );
  }

  Widget _body(BuildContext context, JournalChartValues data, WidgetRef ref) {
    ScrollController controlled = useScrollController();
    ScrollController follow = useScrollController();

    useEffect(() {
      listener() {
        follow.jumpTo(controlled.offset);
      }

      controlled.addListener(listener);
      return () => controlled.removeListener(listener);
    }, [controlled, follow]);

    return Stack(children: [
      if (!data.isEmpty) _legend(context, data, ref),
      ListView(
        controller: follow,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        reverse: true,
        padding: const EdgeInsets.only(right: 32, bottom: 12),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          MovementDisplay(),
        ],
      ),
      Scrollbar(
        controller: controlled,
        thumbVisibility: true,
        child: ListView(
          controller: controlled,
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          reverse: true,
          padding: const EdgeInsets.only(right: 32, bottom: 16),
          children: [_buildChart(context, data)],
        ),
      ),
      Positioned(
        right: AppTheme.basePadding,
        child: _yAxis(),
      ),
    ]);
  }

  Widget _legend(BuildContext context, JournalChartValues data, WidgetRef ref) {
    bool showMovement =
        ref.watch(userProvider.select((user) => user != null && user.hasData));

    return Column(
      children: [
        for (BodyPart bodyPart in data.entries.keys)
          _legendRow(
            bodyPart.displayString(context),
            AppTheme.colors.bodyPartToColor(bodyPart),
          ),
        if (showMovement || true)
          _legendRow(
            AppLocalizations.of(context)!.movement,
            AppTheme.colors.lightGray,
          ),
      ],
    );
  }

  Widget _legendRow(String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(
          left: AppTheme.basePadding, bottom: AppTheme.basePadding / 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 4),
          Text(text, style: AppTheme.paragraphSmall),
        ],
      ),
    );
  }

  Widget _yAxis() {
    return Container(
      height: chartHeight,
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('10', style: AppTheme.paragraphMedium),
          Text('7.5', style: AppTheme.paragraphSmall),
          Text('5', style: AppTheme.paragraphMedium),
          Text('2.5', style: AppTheme.paragraphSmall),
          Text('1', style: AppTheme.paragraphMedium),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, JournalChartValues data) {
    if (data.entries.isEmpty) {
      return Container();
    }

    double minX = data.minX;
    double maxX = data.maxX;

    return SizedBox(
      width: max(data.days, 32) * 16.0,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(
            show: false,
          ),
          gridData: FlGridData(
            show: false,
          ),
          minX: minX,
          maxX: maxX,
          minY: 1,
          maxY: 10,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppTheme.colors.white,
              tooltipBorder: BorderSide(
                color: AppTheme.colors.black,
                width: 1,
              ),
              fitInsideVertically: true,
              fitInsideHorizontally: true,
              getTooltipItems: (spots) {
                DateTime time =
                    DateTime.fromMillisecondsSinceEpoch(spots.first.x.toInt());
                List<JournalChartValue> entries = data.entries.values
                    .expand((e) => e)
                    .where(
                        (e) => e.time.isAtSameMomentAs(time) && e.value != null)
                    .toList();

                return entries.map((entry) {
                  int index = entries.indexOf(entry);
                  String displayString =
                      '${entry.bodyPart?.displayString(context)}: ${entry.value}';

                  if (entry.comment != null && entry.comment!.isNotEmpty) {
                    displayString += '\n ${entry.comment}';
                  }
                  if (index == 0) {
                    String date = DateFormat('dd/MM/yyyy').format(time);
                    displayString = '$date\n $displayString';
                  }
                  return LineTooltipItem(
                    displayString,
                    TextStyle(
                      color: AppTheme.colors.black,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            ...data.entries.entries
                .map((e) => LineChartBarData(
                      spots: e.value
                          .map(
                            (e) => e.value != null
                                ? FlSpot(
                                    e.time.millisecondsSinceEpoch.toDouble(),
                                    e.value!,
                                  )
                                : FlSpot.nullSpot,
                          )
                          .toList(),
                      barWidth: 2,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppTheme.colors.bodyPartToColor(e.key),
                      dotData: FlDotData(
                        checkToShowDot: (spot, barData) {
                          return e.value.any((element) =>
                              element.time.millisecondsSinceEpoch ==
                                  spot.x.toInt() &&
                              element.comment != null &&
                              element.comment!.isNotEmpty);
                        },
                        getDotPainter: (spot, barData, index, context) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.colors.bodyPartToColor(e.key),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ))
                .toList(),
          ],
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, _) {
                  DateTime time =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  if (time.weekday != 1 || value == maxX) {
                    return Container();
                  }
                  return SideTitleWidget(
                      child: Text(
                        DateFormat('MMMd').format(time),
                        style: AppTheme.labelTiny,
                      ),
                      axisSide: AxisSide.bottom);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MovementDisplay extends ConsumerWidget {
  const MovementDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(movementBarChartProvider(
          const Pagination(
            mode: ChartMode.month,
            overrideDuration: Duration(days: 90),
          ),
        ))
        .when(
          data: (values) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: MovementBarChart(
              chartData: values,
            ),
          ),
          error: (_, __) => Container(),
          loading: () => Container(),
        );
  }
}
