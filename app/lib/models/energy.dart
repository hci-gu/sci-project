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
    this.condition = Condition.tetraplegic,
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
  final duration = const Duration(minutes: 1);

  EnergyParams _params = EnergyParams();

  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  EnergyModel() {
    DateTime now = DateTime.now();

    _from = DateTime(now.year, now.month, now.day);
    _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  EnergyParams get params => _params;

  DateTime get from => _from;
  DateTime get to => _to;

  double get total => _energy.fold(0, (a, b) => a + b.value);

  bool _loading = false;
  bool get loading => _loading;

  Future getEnergy() async {
    _loading = true;
    notifyListeners();

    _energy = await Api().getEnergy(_from, _to, _params);
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
    DateTime now = DateTime.now();
    DateTime date =
        DateTime(now.year, now.month, now.day, time.hour, time.minute, 0);
    if (key == 'from') {
      _from = date;
    } else {
      _to = date;
    }
    notifyListeners();

    await getEnergy();
  }

  updateParams(String key, dynamic value) async {
    switch (key) {
      case 'activity':
        _params.activity = value;
        break;
      case 'weight':
        _params.weight = value;
        break;
      case 'injuryLevel':
        _params.injuryLevel = value;
        break;
      case 'gender':
        _params.gender = value;
        break;
      case 'watt':
        _params.watt = value;
        break;
      default:
    }
    notifyListeners();

    await getEnergy();
  }
}
