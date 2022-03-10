import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:scimovement/api.dart';
import 'package:scimovement/models/activity.dart';

class HomeScreen extends HookWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ActivityModel activityModel = Provider.of<ActivityModel>(context);
    useEffect(() {
      activityModel.getHeartRates();
      return () => {};
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCI-Movement'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => activityModel.goBack(),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  activityModel.from.toString().substring(0, 10),
                ),
                IconButton(
                  onPressed: () => activityModel.goForward(),
                  icon: const Icon(Icons.arrow_forward),
                )
              ],
            ),
            HeartRateChart(
              heartRates: activityModel.heartRates,
              from: activityModel.from,
              to: activityModel.to,
            ),
          ],
        ),
      ),
    );
  }
}

class HeartRateChart extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final List<HeartRate> heartRates;

  const HeartRateChart({
    Key? key,
    required this.heartRates,
    required this.from,
    required this.to,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xff232d37),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 30,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                // horizontalInterval: 1,
                // verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: const Color(0xff37434d),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: const Color(0xff37434d),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: SideTitles(showTitles: false),
                topTitles: SideTitles(showTitles: false),
                bottomTitles: SideTitles(
                  showTitles: true,
                  interval: 60 * 1000 * 300,
                  getTextStyles: (context, value) => const TextStyle(
                    color: Color(0xff68737d),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  getTitles: (value) {
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return date.toString().substring(10, 16);
                  },
                ),
                leftTitles: SideTitles(
                  reservedSize: 30,
                  showTitles: true,
                  getTextStyles: (context, value) => const TextStyle(
                    color: Color(0xff67727d),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              minX: from.millisecondsSinceEpoch.toDouble(),
              maxX: to.millisecondsSinceEpoch.toDouble(),
              minY: 0,
              maxY: 200,
              lineBarsData: [
                LineChartBarData(
                  spots: heartRates
                      .map(
                        (e) => FlSpot(
                          e.time.millisecondsSinceEpoch.toDouble(),
                          e.value,
                        ),
                      )
                      .toList(),
                  // isCurved: true,
                  // colors: gradientColors,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: false,
                  ),
                  belowBarData: BarAreaData(show: true),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
