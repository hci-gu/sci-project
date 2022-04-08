import 'package:flutter/material.dart';

enum ChartMode { fullDay, fit }
enum EnergyChartMode { minute, accumulative }

class SettingsModel extends ChangeNotifier {
  ChartMode _chartMode = ChartMode.fit;
  ChartMode get chartMode => _chartMode;

  EnergyChartMode _energyChartMode = EnergyChartMode.accumulative;
  EnergyChartMode get energyChartMode => _energyChartMode;

  double minTimeForChart(DateTime date) {
    if (chartMode == ChartMode.fullDay) {
      return DateTime(date.year, date.month, date.day)
          .millisecondsSinceEpoch
          .toDouble();
    } else {
      return date.millisecondsSinceEpoch.toDouble();
    }
  }

  double maxTimeForChart(DateTime date) {
    if (chartMode == ChartMode.fullDay) {
      return DateTime(date.year, date.month, date.day, 23, 59, 59)
          .millisecondsSinceEpoch
          .toDouble();
    } else {
      return date.millisecondsSinceEpoch.toDouble();
    }
  }

  void setChartMode(ChartMode mode) {
    _chartMode = mode;
    notifyListeners();
  }

  void setEnergyChartMode(EnergyChartMode mode) {
    _energyChartMode = mode;
    notifyListeners();
  }
}
