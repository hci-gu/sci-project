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

class EnergyModel extends ChangeNotifier {
  List<Energy> _energy = [];
  List<Energy> get energy => _energy;
  List<Accel> _accel = [];
  List<Accel> get accel => _accel;
  final duration = const Duration(minutes: 1);

  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  EnergyModel() {
    DateTime now = DateTime.now();

    _from = DateTime(now.year, now.month, now.day);
    _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  DateTime get from => _from;
  DateTime get to => _to;

  double get total => _energy.fold(0, (a, b) => a + b.value);

  bool _loading = false;
  bool get loading => _loading;

  Future getEnergy() async {
    _loading = true;
    notifyListeners();

    _energy = await Api().getEnergy(_from, _to);
    if (_to.difference(_from).inMinutes < 5) {
      _accel = await Api().getAccel(_from, _to);
    }
    _loading = false;

    notifyListeners();
  }

  setFrom(DateTime date) {
    _from =
        DateTime(date.year, date.month, date.day, date.hour, date.minute, 0);
    notifyListeners();
  }

  setTo(DateTime date) {
    _to = DateTime(date.year, date.month, date.day, date.hour, date.minute, 0);
    notifyListeners();
  }

  setTimeOfDay(String key, TimeOfDay time) async {
    if (key == 'from') {
      _from =
          DateTime(from.year, from.month, from.day, time.hour, time.minute, 0);
    } else {
      _to = DateTime(to.year, to.month, to.day, time.hour, time.minute, 0);
    }
    notifyListeners();

    await getEnergy();
  }
}
