import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/theme/theme.dart';

class JournalChartValues {
  final Map<BodyPart, List<JournalEntry>> entries;

  const JournalChartValues(this.entries);

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
}

final journalChartProvider = FutureProvider<JournalChartValues>((ref) async {
  List<JournalEntry> journal = await ref.watch(journalProvider.future);

  // filter out all unique journal entries based on bodyPart
  List<BodyPart> bodyParts = [];
  for (JournalEntry entry in journal) {
    if (!bodyParts.any((e) => e == entry.bodyPart)) {
      bodyParts.add(entry.bodyPart);
    }
  }
  Map<BodyPart, List<JournalEntry>> entries = {};
  for (BodyPart bodyPart in bodyParts) {
    entries[bodyPart] = journal.where((e) => e.bodyPart == bodyPart).toList();
  }

  return JournalChartValues(entries);
});

class JournalChart extends ConsumerWidget {
  const JournalChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 300,
      child: ref.watch(journalChartProvider).when(
            data: (data) => _body(context, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text(e.toString()),
          ),
    );
  }

  Widget _body(BuildContext context, JournalChartValues data) {
    return Stack(children: [
      ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        reverse: true,
        padding: const EdgeInsets.only(right: 32),
        children: [_buildChart(data)],
      ),
      _legend(data),
      Positioned(
        right: 0,
        child: _yAxis(),
      ),
    ]);
  }

  Widget _legend(JournalChartValues data) {
    return Column(
      children: [
        for (BodyPart bodyPart in data.entries.keys)
          Padding(
            padding: EdgeInsets.only(bottom: AppTheme.basePadding / 2),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.colors.bodyPartToColor(bodyPart),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 4),
                Text(bodyPart.displayString(), style: AppTheme.paragraphSmall),
              ],
            ),
          ),
      ],
    );
  }

  Widget _yAxis() {
    return Container(
      height: 300,
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('10', style: AppTheme.paragraphMedium),
          Text('5', style: AppTheme.paragraphMedium),
          Text('1', style: AppTheme.paragraphMedium),
        ],
      ),
    );
  }

  Widget _buildChart(JournalChartValues data) {
    if (data.entries.isEmpty) {
      return Container();
    }

    double minX = data.minX;
    double maxX = data.maxX;

    return SizedBox(
      width: 2000,
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
          minY: 0,
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
                return spots.map((e) {
                  return LineTooltipItem(
                    '${e.y} / 10',
                    TextStyle(
                      color: AppTheme.colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: data.entries.entries
              .map((e) => LineChartBarData(
                    spots: e.value
                        .map(
                          (e) => FlSpot(
                            e.time.millisecondsSinceEpoch.toDouble(),
                            e.painLevel.toDouble(),
                          ),
                        )
                        .toList(),
                    // preventCurveOverShooting: true,
                    barWidth: 2,
                    isCurved: true,
                    color: AppTheme.colors.bodyPartToColor(e.key),
                    dotData: FlDotData(
                      // show: false,
                      checkToShowDot: (spot, barData) {
                        bool show = false;
                        e.value.forEach((element) {
                          if (element.time.millisecondsSinceEpoch ==
                              spot.x.toInt()) {
                            show = element.comment.isNotEmpty;
                          }
                        });
                        return show;
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
                  return SideTitleWidget(
                      child: Text(
                        time.weekday % 1 == 0
                            ? DateFormat('MMMd').format(time)
                            : '',
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
