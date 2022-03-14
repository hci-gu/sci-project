import 'package:flutter/material.dart';
import 'package:scimovement/api.dart';

class EnergyModel extends ChangeNotifier {
  List<Energy> _energy = [];
  List<Energy> get energy => _energy;
  final duration = const Duration(minutes: 1);

  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  DateTime get from => _from;
  DateTime get to => _to;

  double get total => _energy.fold(0, (a, b) => a + b.value);

  bool _loading = false;
  bool get loading => _loading;

  Future calculateEnergy(DateTime until) async {
    _loading = true;
    notifyListeners();
    List<Energy> fetchedEnergy = await Api().getEnergy(from, to);
    _energy.addAll(fetchedEnergy);
    _loading = false;
    setFrom(from.add(duration));
    notifyListeners();

    if (to.isBefore(until)) {
      return calculateEnergy(until);
    }
  }

  Future getEnergy(DateTime from, DateTime to) async {
    _loading = true;
    _energy = [];
    notifyListeners();

    // start by fetching single minute just to make sure we dont ask the server to calculate whole day at once.
    DateTime testTo = to.add(duration);
    await Api().getEnergy(from, testTo);

    List<Energy> fetchedEnergy = await Api().getEnergy(from, to);
    _energy.addAll(fetchedEnergy);
    _loading = false;

    setFrom(_energy.last.time);
    notifyListeners();
  }

  setFrom(DateTime date) {
    _from = DateTime.utc(
        date.year, date.month, date.day, date.hour, date.minute, 0);
    _to = date.add(duration);
    notifyListeners();
  }
}
