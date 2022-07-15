import 'package:flutter/material.dart';
import 'package:scimovement/api.dart';

enum Activity {
  none,
  weights,
  skiErgo,
  armErgo,
}

enum Gender { male, female }

enum Condition { paraplegic, tetraplegic }

class EnergyParams {
  Activity activity;
  Condition condition;
  Gender gender;
  int weight;
  int watt;
  int injuryLevel;

  EnergyParams({
    this.activity = Activity.none,
    this.condition = Condition.paraplegic,
    this.gender = Gender.female,
    this.weight = 60,
    this.watt = 10,
    this.injuryLevel = 5,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      'activity': _valueForActivity(),
      'condition': condition.name,
      'gender': gender.name,
      'injuryLevel': injuryLevel,
      'weight': weight,
      'watt': watt,
    };
  }

  _valueForActivity() {
    switch (activity) {
      case Activity.skiErgo:
        return 'ski-ergo';
      case Activity.armErgo:
        return 'arm-ergo';
      default:
        return activity.name;
    }
  }
}

class ActivityDay {
  final DateTime date;
  int minutes = 0;

  DateTime get from => DateTime(date.year, date.month, date.day);
  DateTime get to => DateTime(date.year, date.month, date.day, 23, 59, 59);
  ActivityDay(this.date);

  Future getActivity() async {
    minutes = await Api().getActivity(from, to);
  }
}

class EnergyDay {
  final DateTime date;
  List<Energy> energy = [];

  List<EnergyDay> get averageEnergy => [];

  DateTime get from => DateTime(date.year, date.month, date.day);
  DateTime get to => DateTime(date.year, date.month, date.day, 23, 59, 59);
  double get total => energy.fold(0, (a, b) => a + b.value);

  EnergyDay(this.date);

  Future getEnergy() async {
    energy = await Api().getEnergy(from, to);
  }

  List<Energy> getAverageEnergy([int divisor = 20]) {
    var averageEnergy = <Energy>[];
    var total = 0.0;
    for (var i = 0; i < energy.length; i++) {
      total += energy[i].value;
      if (i % divisor == 0) {
        averageEnergy.add(Energy(
          energy[i].time,
          total / divisor,
        ));
        total = 0.0;
      }
    }
    return averageEnergy;
  }
}

class EnergyModel extends ChangeNotifier {
  final duration = const Duration(minutes: 1);
  late EnergyDay _day;
  late ActivityDay _activityDay;
  late EnergyDay _previousDay;
  late ActivityDay _prevActivityDay;

  List<Energy> get energy => _day.energy;
  List<Energy> get averageEnergy => _day.getAverageEnergy();
  double get energyTotal => _day.total;
  List<Energy> get prevEnergy => _previousDay.energy;
  double get prevTotal => _previousDay.total;
  List<Energy> get prevAverage => _previousDay.getAverageEnergy();

  int get minutesInactive => _activityDay.minutes;
  int get prevMinutesInactive => _prevActivityDay.minutes;

  DateTime _date = DateTime.now();

  EnergyModel() {
    DateTime previousDayDate = _date.subtract(const Duration(days: 1));
    _day = EnergyDay(_date);
    _previousDay = EnergyDay(previousDayDate);
    _activityDay = ActivityDay(_date);
    _prevActivityDay = ActivityDay(previousDayDate);
  }

  bool _loading = false;
  bool get loading => _loading;

  Future getEnergy() async {
    _loading = true;
    notifyListeners();

    await Future.wait([
      _day.getEnergy(),
      _activityDay.getActivity(),
      _previousDay.getEnergy(),
      _prevActivityDay.getActivity(),
    ]);
    _loading = false;

    notifyListeners();
  }

  setDate(DateTime date) {
    _date = date;
    DateTime previousDayDate = _date.subtract(const Duration(days: 1));
    _day = EnergyDay(_date);
    _previousDay = EnergyDay(previousDayDate);
    _activityDay = ActivityDay(_date);
    _prevActivityDay = ActivityDay(previousDayDate);
    notifyListeners();
  }
}
