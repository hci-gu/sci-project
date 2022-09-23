import 'dart:math' as math;
import 'package:scimovement/api.dart';
import 'package:scimovement/models/config.dart';
import 'package:collection/collection.dart';

class ChartDataPoint {
  final DateTime time;
  final double value;
  final Activity activity;

  ChartDataPoint(this.time, this.value, this.activity);
}

class ChartData {
  final List<ChartDataPoint> data;
  final ChartMode mode;

  ChartData(this.data, this.mode);

  double get max => data.map((e) => e.value).reduce(math.max);
  double get maxValue => mode == ChartMode.day ? 60 : max + max * 0.2;

  Map<DateTime, List<ChartDataPoint>> get group => {
        ..._emptyMap(data.last.time),
        ...groupData(),
      };

  Map<DateTime, List<ChartDataPoint>> groupData() {
    switch (mode) {
      case ChartMode.day:
        return groupBy(
          data,
          (ChartDataPoint e) =>
              DateTime(e.time.year, e.time.month, e.time.day, e.time.hour),
        );
      case ChartMode.week:
      case ChartMode.month:
        return groupBy(
          data,
          (ChartDataPoint e) => DateTime(e.time.year, e.time.month, e.time.day),
        );
      case ChartMode.year:
        return groupBy(
          data,
          (ChartDataPoint e) => DateTime(e.time.year, e.time.month),
        );
      default:
    }
    return groupBy(data, (ChartDataPoint e) => e.time);
  }

  Map<DateTime, List<ChartDataPoint>> _emptyMap(DateTime base) {
    switch (mode) {
      case ChartMode.day:
        return {
          for (int i = 0; i < 24; i++)
            DateTime(base.year, base.month, base.day, i): [],
        };
      case ChartMode.week:
        return {
          for (int i = 0; i < 6; i++)
            DateTime(
              base.subtract(Duration(days: i)).year,
              base.subtract(Duration(days: i)).month,
              base.subtract(Duration(days: i)).day,
            ): [],
        };
      case ChartMode.month:
        return {
          for (int i = 0; i < 30; i++)
            DateTime(
              base.subtract(Duration(days: i)).year,
              base.subtract(Duration(days: i)).month,
              base.subtract(Duration(days: i)).day,
            ): [],
        };
      case ChartMode.year:
        return {
          for (int i = 0; i < 11; i++)
            DateTime(
              base.subtract(Duration(days: 31 * i)).year,
              base.subtract(Duration(days: 31 * i)).month,
            ): [],
        };
    }
  }
}
