import 'package:polar/polar.dart';
import 'dart:math';

/// Feed-forward/back coefficients (length 9)
const List<double> _zi = [
  -0.07532883864659122,
  -0.0753546620840857,
  0.22603070565973946,
  0.22598432569253424,
  -0.22599275859607648,
  -0.22600915159543014,
  0.07533559105142006,
  0.07533478851866574,
  0.0,
];

/// Zero initial state for the 21-tap filter
List<double> _ziZeros = List<double>.filled(21, 0.0);

/// Sums over sliding windows of [length], accumulating only values ≥ [threshold].
List<double> runSum(List<double> data, int length, double threshold) {
  final int N = data.length;
  final int cnt = (N / length).ceil();
  final List<double> rs = List<double>.filled(cnt, 0.0);
  for (var n = 0; n < cnt; n++) {
    for (var p = n * length; p < (n + 1) * length; p++) {
      if (p < N && data[p] >= threshold) {
        rs[n] += data[p] - threshold;
      }
    }
  }
  return rs;
}

/// “Odd” extension by mirroring around ends, lengthening by 2*n.
List<double> oddExt(List<double> x, int n) {
  final int L = x.length;
  final List<double> result = List<double>.filled(L + 2 * n, 0.0);
  // Left mirror
  for (var i = 0; i < n; i++) {
    result[i] = 2 * x[0] - x[n - i - 1];
  }
  // Center
  for (var i = 0; i < L; i++) {
    result[n + i] = x[i];
  }
  // Right mirror
  for (var i = 0; i < n; i++) {
    result[n + L + i] = 2 * x[L - 1] - x[L - n + i];
  }
  return result;
}

/// 9-tap IIR filter (forward pass).
List<double> filterAB2(List<double> input, [List<double>? zCoeffs]) {
  final List<double> x = List<double>.from(input);
  final List<double> y = List<double>.from(input);
  final List<double> z = (zCoeffs ?? _zi).map((c) => c * x[0]).toList();
  final List<double> x0 = x.sublist(0, 9);

  // Warm-up for first 9 samples
  for (var i = 0; i < 9; i++) {
    if (i >= 8) {
      z[7] =
          0.0753349039750657 * x0[i - 8] -
          0.019035473586069288 * y[i - 8] +
          z[8];
    }
    if (i >= 7) z[6] = 0.1323148049950936 * y[i - 7] + z[7];
    if (i >= 6) {
      z[5] =
          -0.3013396159002628 * x0[i - 6] -
          0.8452545660100996 * y[i - 6] +
          z[6];
    }
    if (i >= 5) z[4] = 2.7027389238066353 * y[i - 5] + z[5];
    if (i >= 4) {
      z[3] =
          0.4520094238503942 * x0[i - 4] - 5.33187310787808 * y[i - 4] + z[4];
    }
    if (i >= 3) z[2] = 7.64673626503976 * y[i - 3] + z[3];
    if (i >= 2) {
      z[1] =
          -0.3013396159002628 * x0[i - 2] - 7.543176557521139 * y[i - 2] + z[2];
    }
    if (i >= 1) z[0] = 4.2575497111306 * y[i - 1] + z[1];

    y[i] = x[i] = 0.0753349039750657 * x[i] + z[0];
  }

  // Shift registers
  double yi1 = y[8],
      yi2 = y[7],
      yi3 = y[6],
      yi4 = y[5],
      yi5 = y[4],
      yi6 = y[3],
      yi7 = y[2],
      yi8 = y[1];
  double xi1 = x0[8],
      xi2 = x0[7],
      xi3 = x0[6],
      xi4 = x0[5],
      xi5 = x0[4],
      xi6 = x0[3],
      xi7 = x0[2],
      xi8 = x0[1];

  // Main filter loop
  for (var i = 9; i < x.length; i++) {
    var za =
        z[8] +
        0.0753349039750657 * xi8 -
        0.019035473586069288 * yi8 -
        0.1323148049950936 * yi7 -
        0.3013396159002628 * xi6 -
        0.8452545660100996 * yi6 +
        2.7027389238066353 * yi5 +
        0.4520094238503942 * xi4 -
        5.33187310787808 * yi4 +
        7.64673626503976 * yi3 -
        0.3013396159002628 * xi2 -
        7.543176557521139 * yi2 +
        4.2575497111306 * yi1;

    yi8 = yi7;
    yi7 = yi6;
    yi6 = yi5;
    yi5 = yi4;
    yi4 = yi3;
    yi3 = yi2;
    yi2 = yi1;
    yi1 = 0.0753349039750657 * x[i] + za;

    xi8 = xi7;
    xi7 = xi6;
    xi6 = xi5;
    xi5 = xi4;
    xi4 = xi3;
    xi3 = xi2;
    xi2 = xi1;
    xi1 = x[i];

    y[i] = x[i] = yi1;
  }

  return y;
}

/// 9-tap IIR filter (reverse pass).
List<double> filterAB2Reverse(List<double> input, [List<double>? zCoeffs]) {
  final List<double> x = List<double>.from(input);
  final List<double> y = List<double>.from(input);
  final int L = x.length;
  final List<double> z = (zCoeffs ?? _zi).map((c) => c * x[L - 1]).toList();
  final List<double> x0 = x.sublist(L - 9, L);

  // Warm-up reverse for last 9 samples
  for (var i = 0; i < 9; i++) {
    final int idx = L - 1 - i;
    if (i >= 8) {
      z[7] =
          0.0753349039750657 * x0[8 - (i - 8)] -
          0.019035473586069288 * y[idx + 8] +
          z[8];
    }
    if (i >= 7) z[6] = 0.1323148049950936 * y[idx + 7] + z[7];
    if (i >= 6) {
      z[5] =
          -0.3013396159002628 * x0[8 - (i - 6)] -
          0.8452545660100996 * y[idx + 6] +
          z[6];
    }
    if (i >= 5) z[4] = 2.7027389238066353 * y[idx + 5] + z[5];
    if (i >= 4) {
      z[3] =
          0.4520094238503942 * x0[8 - (i - 4)] -
          5.33187310787808 * y[idx + 4] +
          z[4];
    }
    if (i >= 3) z[2] = 7.64673626503976 * y[idx + 3] + z[3];
    if (i >= 2) {
      z[1] =
          -0.3013396159002628 * x0[8 - (i - 2)] -
          7.543176557521139 * y[idx + 2] +
          z[2];
    }
    if (i >= 1) z[0] = 4.2575497111306 * y[idx + 1] + z[1];

    y[idx] = x[idx] = 0.0753349039750657 * x0[8 - (i)] + z[0];
  }

  // Shift registers
  double yi1 = y[L - 9],
      yi2 = y[L - 8],
      yi3 = y[L - 7],
      yi4 = y[L - 6],
      yi5 = y[L - 5],
      yi6 = y[L - 4],
      yi7 = y[L - 3],
      yi8 = y[L - 2];
  double xi1 = x0[0],
      xi2 = x0[1],
      xi3 = x0[2],
      xi4 = x0[3],
      xi5 = x0[4],
      xi6 = x0[5],
      xi7 = x0[6],
      xi8 = x0[7];

  // Main reverse loop
  for (var i = 9; i < L; i++) {
    final int idx = L - 1 - i;
    var za =
        z[8] +
        0.0753349039750657 * xi8 -
        0.019035473586069288 * yi8 -
        0.1323148049950936 * yi7 -
        0.3013396159002628 * xi6 -
        0.8452545660100996 * yi6 +
        2.7027389238066353 * yi5 +
        0.4520094238503942 * xi4 -
        5.33187310787808 * yi4 +
        7.64673626503976 * yi3 -
        0.3013396159002628 * xi2 -
        7.543176557521139 * yi2 +
        4.2575497111306 * yi1;

    yi8 = yi7;
    yi7 = yi6;
    yi6 = yi5;
    yi5 = yi4;
    yi4 = yi3;
    yi3 = yi2;
    yi2 = yi1;
    yi1 = 0.0753349039750657 * x[idx] + za;

    xi8 = xi7;
    xi7 = xi6;
    xi6 = xi5;
    xi5 = xi4;
    xi4 = xi3;
    xi3 = xi2;
    xi2 = xi1;
    xi1 = x[idx];

    y[idx] = x[idx] = yi1;
  }

  return y;
}

/// 21-tap IIR filter
List<double> filterAB(List<double> input, [List<double>? zCoeffs]) {
  final List<double> x = List<double>.from(input);
  final List<double> y = List<double>.from(input);
  final List<double> z = (zCoeffs ?? _ziZeros).map((c) => c * x[0]).toList();
  final List<double> x0 = x.sublist(0, 21);

  // Warm-up
  for (var i = 0; i < 21; i++) {
    if (i >= 20) {
      z[19] = -0.00018936195 * x0[i - 20] - 0.019852 * y[i - 20] + z[20];
    }
    if (i >= 19) {
      z[18] = -0.0007813798 * x0[i - 19] + 0.13832 * y[i - 19] + z[19];
    }
    if (i >= 18) {
      z[17] = 0.0033278025 * x0[i - 18] - 0.4162 * y[i - 18] + z[18];
    }
    if (i >= 17) {
      z[16] = -0.009048033 * x0[i - 17] + 0.67312 * y[i - 17] + z[17];
    }
    if (i >= 16) {
      z[15] = 0.012385775 * x0[i - 16] - 0.46565 * y[i - 16] + z[16];
    }
    if (i >= 15) {
      z[14] = -0.004464283 * x0[i - 15] - 0.46483 * y[i - 15] + z[15];
    }
    if (i >= 14) {
      z[13] = -0.012522805 * x0[i - 14] + 1.6847 * y[i - 14] + z[14];
    }
    if (i >= 13) {
      z[12] = 0.035013095 * x0[i - 13] - 2.4777 * y[i - 13] + z[13];
    }
    if (i >= 12) {
      z[11] = -0.044404475 * x0[i - 12] + 2.7816 * y[i - 12] + z[12];
    }
    if (i >= 11) {
      z[10] = 0.046172355 * x0[i - 11] - 2.9298 * y[i - 11] + z[11];
    }
    if (i >= 10) {
      z[9] = -0.050736805 * x0[i - 10] + 2.9257 * y[i - 10] + z[10];
    }
    if (i >= 9) {
      z[8] = 0.047021555 * x0[i - 9] - 2.4734 * y[i - 9] + z[9];
    }
    if (i >= 8) {
      z[7] = -0.03681861 * x0[i - 8] + 1.3481 * y[i - 8] + z[8];
    }
    if (i >= 7) {
      z[6] = 0.017865045 * x0[i - 7] - 0.06361 * y[i - 7] + z[7];
    }
    if (i >= 6) {
      z[5] = 0.006154577 * x0[i - 6] - 0.89238 * y[i - 6] + z[6];
    }
    if (i >= 5) {
      z[4] = -0.01952195 * x0[i - 5] + 2.4636 * y[i - 5] + z[5];
    }
    if (i >= 4) {
      z[3] = 0.05192086 * x0[i - 4] - 5.385 * y[i - 4] + z[4];
    }
    if (i >= 3) {
      z[2] = -0.10874585 * x0[i - 3] + 7.9805 * y[i - 3] + z[3];
    }
    if (i >= 2) {
      z[1] = 0.1385354 * x0[i - 2] - 7.5712 * y[i - 2] + z[2];
    }
    if (i >= 1) {
      z[0] = -0.1185406 * x0[i - 1] + 4.1637 * y[i - 1] + z[1];
    }

    y[i] = x[i] = 0.047390185 * x0[i] + z[0];
  }

  // Shift regs
  final regsY = List<double>.from(y.sublist(0, 20).reversed);
  final regsX = List<double>.from(x0.sublist(0, 20).reversed);

  for (var i = 21; i < x.length; i++) {
    var za =
        -0.00018936195 * regsX[0] -
        0.019852 * regsY[0] -
        0.0007813798 * regsX[1] +
        0.13832 * regsY[1] +
        0.0033278025 * regsX[2] -
        0.4162 * regsY[2] -
        0.009048033 * regsX[3] +
        0.67312 * regsY[3] +
        0.012385775 * regsX[4] -
        0.46565 * regsY[4] -
        0.004464283 * regsX[5] -
        0.46483 * regsY[5] -
        0.012522805 * regsX[6] +
        1.6847 * regsY[6] +
        0.035013095 * regsX[7] -
        2.4777 * regsY[7] -
        0.044404475 * regsX[8] +
        2.7816 * regsY[8] +
        0.046172355 * regsX[9] -
        2.9298 * regsY[9] -
        0.050736805 * regsX[10] +
        2.9257 * regsY[10] +
        0.047021555 * regsX[11] -
        2.4734 * regsY[11] -
        0.03681861 * regsX[12] +
        1.3481 * regsY[12] +
        0.017865045 * regsX[13] -
        0.06361 * regsY[13] +
        0.006154577 * regsX[14] -
        0.89238 * regsY[14] -
        0.01952195 * regsX[15] +
        2.4636 * regsY[15] +
        0.05192086 * regsX[16] -
        5.385 * regsY[16] -
        0.10874585 * regsX[17] +
        7.9805 * regsY[17] +
        0.1385354 * regsX[18] -
        7.5712 * regsY[18] -
        0.1185406 * regsX[19] +
        4.1637 * regsY[19];

    // shift
    regsY.insert(0, 0.047390185 * x[i] + za);
    regsY.removeLast();
    regsX.insert(0, x[i]);
    regsX.removeLast();

    y[i] = x[i] = regsY[0];
  }

  return y;
}

/// Zero-phase filtering by applying forward then reverse.
List<double> filtfilt(List<double> x) {
  const edge = 27;
  final data = oddExt(x, edge);
  final y1 = filterAB2(data);
  final y2 = filterAB2Reverse(y1);
  return y2.sublist(edge, y2.length - edge);
}

/// Integrate and count peaks per axis
double getCounts(List<double> values) {
  const deadband = 0.068;
  const peakThreshold = 2.13;
  const adcResolution = 0.0164;
  const integN = 10;

  final filtered = filtfilt(values);
  final axis =
      filterAB(
        filtered,
        _ziZeros,
      ).asMap().entries.where((e) => e.key % 3 == 0).map((e) {
        // clamp to ±peakThreshold
        var v = e.value.clamp(-peakThreshold, peakThreshold).abs();
        if (v < deadband) return 0.0;
        return (v / adcResolution).floorToDouble();
      }).toList();

  final summed = runSum(axis, integN, 0.0);
  return summed.fold(0.0, (a, b) => a + b);
}

/// Final magnitude across X, Y, Z
double getAccelerometerMagnitude(
  List<double> accX,
  List<double> accY,
  List<double> accZ,
) {
  final x = getCounts(accX);
  final y = getCounts(accY);
  final z = getCounts(accZ);
  return sqrt(x * x + y * y + z * z);
}

class Counts {
  final DateTime t;
  final double hr;
  final double a;

  Counts({required this.t, required this.hr, required this.a});
}

extension CountsExtension on Counts {
  Map<String, dynamic> toJson() {
    return {'t': t.toIso8601String(), 'hr': hr, 'a': a};
  }

  static Counts fromJson(Map<String, dynamic> json) {
    return Counts(
      t: DateTime.parse(json['t']),
      hr: (json['hr'] as num).toDouble(),
      a: (json['a'] as num).toDouble(),
    );
  }
}

List<Counts> countsFromPolarData(
  AccOfflineRecording accRecording,
  HrOfflineRecording hrRecording,
) {
  if (accRecording.data.samples.isEmpty || hrRecording.data.samples.isEmpty) {
    return [];
  }

  // get last record
  accRecording.data.samples.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));

  DateTime start = hrRecording.startTime;
  int hrMinutes = (hrRecording.data.samples.length / 60).ceil();

  List<Counts> counts = [];
  for (int i = 0; i <= hrMinutes; i++) {
    DateTime t = start.add(Duration(minutes: i));
    // accSamplesInSameMinute
    List<PolarAccSample> accSamplesInSameMinute =
        accRecording.data.samples.where((s) {
          return s.timeStamp.isAfter(t) &&
              s.timeStamp.isBefore(t.add(Duration(minutes: 1)));
        }).toList();
    if (accSamplesInSameMinute.length < 30) {
      continue;
    }

    List<double> xs =
        accSamplesInSameMinute.map((s) => (s.x / 9.82).toDouble()).toList();
    List<double> ys =
        accSamplesInSameMinute.map((s) => (s.y / 9.82).toDouble()).toList();
    List<double> zs =
        accSamplesInSameMinute.map((s) => (s.z / 9.82).toDouble()).toList();
    double accVM = getAccelerometerMagnitude(xs, ys, zs);

    int hrIndexStart = i * 60;
    int hrIndexEnd = (i + 1) * 60;
    List<PolarHrSample> hrSamplesInSameMinute = hrRecording.data.samples
        .sublist(
          hrIndexStart,
          min(hrIndexEnd, hrRecording.data.samples.length),
        );
    double avgHr =
        hrSamplesInSameMinute
            .map((s) => s.hr.toDouble())
            .reduce((a, b) => a + b) /
        hrSamplesInSameMinute.length;

    Counts count = Counts(t: t, hr: avgHr, a: accVM);
    counts.add(count);
  }

  return counts;
}
