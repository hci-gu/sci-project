import 'package:flutter/material.dart';
import 'package:scimovement/api.dart';

class ActivityModel extends ChangeNotifier {
  List<HeartRate> _heartRates = [];
  List<HeartRate> get heartRates => _heartRates;

  final Duration _duration = const Duration(days: 1);
  late DateTime _from;
  late DateTime _to;

  ActivityModel() {
    var now = DateTime.now();

    _from = DateTime(now.year, now.month, now.day);
    _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  DateTime get from => _from;
  DateTime get to => _to;

  DateTime? get earliestDataDate =>
      _heartRates.isEmpty ? null : _heartRates.first.time;
  DateTime? get lastDataDate =>
      _heartRates.isEmpty ? null : _heartRates.last.time;

  Future getHeartRates() async {
    _heartRates = await Api().getHeartRate(from, to);
    notifyListeners();
  }

  void goBack() async {
    _from = _from.subtract(_duration);
    _to = _to.subtract(_duration);
    await getHeartRates();
    notifyListeners();
  }

  bool get canFoForward => _to.isBefore(DateTime.now());
  void goForward() async {
    if (!canFoForward) return;
    _from = _from.add(_duration);
    _to = _to.add(_duration);
    await getHeartRates();
    notifyListeners();
  }
}
