import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:polar/polar.dart';
import 'dart:math';

import 'package:scimovement/api/classes/counts.dart';

class AccSample {
  final DateTime timeStamp;
  final int x;
  final int y;
  final int z;

  AccSample({
    required this.timeStamp,
    required this.x,
    required this.y,
    required this.z,
  });

  factory AccSample.fromJson(Map<String, dynamic> json) {
    return AccSample(
      timeStamp: DateTime.parse(json['timeStamp']),
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
    );
  }
}

void main() {
  test('Run counts from mock data', () async {
    final file = File('polar_export.json');
    final json = jsonDecode(await file.readAsString());
    DateTime accStart = DateTime.parse(json['accStart']);

    DateTime minuteStart = DateTime.utc(
      accStart.year,
      accStart.month,
      accStart.day,
      accStart.hour,
      accStart.minute + 1,
    );
    DateTime minuteEnd = DateTime.utc(
      accStart.year,
      accStart.month,
      accStart.day,
      accStart.hour,
      accStart.minute + 2,
    );

    final accSamples =
        (json['accSamples'] as List).map((s) => AccSample.fromJson(s)).toList();

    List<AccSample> accSamplesInMinute = [];
    for (var sample in accSamples) {
      if ((sample.timeStamp.isAtSameMomentAs(minuteStart) ||
              sample.timeStamp.isAfter(minuteStart)) &&
          sample.timeStamp.isBefore(minuteEnd)) {
        accSamplesInMinute.add(sample);
      }
    }

    double magnitude = computeAccVM(
      resampleAccelerometerData(
        accSamplesInMinute.map((s) => (s.x / 9.82).toDouble()).toList(),
        49,
        30,
      ),
      resampleAccelerometerData(
        accSamplesInMinute.map((s) => (s.y / 9.82).toDouble()).toList(),
        49,
        30,
      ),
      resampleAccelerometerData(
        accSamplesInMinute.map((s) => (s.z / 9.82).toDouble()).toList(),
        49,
        30,
      ),
    );
    expect(magnitude, 219412);
  });
}
