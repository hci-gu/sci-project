import 'dart:math' as math;
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/pagination.dart';
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

  double get maxValue => data.map((e) => e.value).reduce(math.max);
  double get maxY => mode == ChartMode.day ? 60 : maxValue * 1.25;

  DateTime get day => DateTime(
        data.first.time.year,
        data.first.time.month,
        data.first.time.day,
      );

  double get minX => DateTime(day.year, day.month, day.day, 5)
      .millisecondsSinceEpoch
      .toDouble();
  double get maxX => DateTime(day.year, day.month, day.day, 23, 59)
      .millisecondsSinceEpoch
      .toDouble();
  int get minDate => data.last.time.millisecondsSinceEpoch;
  int get maxDate => data.first.time.millisecondsSinceEpoch;
  int get days => (minDate - maxDate) ~/ (1000 * 60 * 60 * 24);

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
          for (int i = 0; i < 7; i++)
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
      case ChartMode.quarter:
        return {
          for (int i = 0; i < 90; i++)
            DateTime(
              base.subtract(Duration(days: i)).year,
              base.subtract(Duration(days: i)).month,
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
