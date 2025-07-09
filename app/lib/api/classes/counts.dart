import 'package:polar/polar.dart';
import 'dart:math';

/// IIR filter coefficients
const List<double> A = [
  1,
  -4.1637,
  7.5712,
  -7.9805,
  5.385,
  -2.4636,
  0.89238,
  0.06361,
  -1.3481,
  2.4734,
  -2.9257,
  2.9298,
  -2.7816,
  2.4777,
  -1.6847,
  0.46483,
  0.46565,
  -0.67312,
  0.4162,
  -0.13832,
  0.019852,
];

const List<double> B = [
  0.049109,
  -0.12284,
  0.14356,
  -0.11269,
  0.053804,
  -0.02023,
  0.0063778,
  0.018513,
  -0.038154,
  0.048727,
  -0.052577,
  0.047847,
  -0.046015,
  0.036283,
  -0.012977,
  -0.0046262,
  0.012835,
  -0.0093762,
  0.0034485,
  -0.00080972,
  -0.00019623,
];

const List<double> B2 = [
  0.0753349039750657,
  0.0,
  -0.3013396159002628,
  0.0,
  0.4520094238503942,
  0.0,
  -0.3013396159002628,
  0.0,
  0.0753349039750657,
];

const List<double> A2 = [
  1.0,
  -4.2575497111306,
  7.543176557521139,
  -7.64673626503976,
  5.33187310787808,
  -2.7027389238066353,
  0.8452545660100996,
  -0.1323148049950936,
  0.019035473586069288,
];

/// Initial filter state for filtfilt
const List<double> _zi = [
  -0.07532883864659122,
  -0.0753546620840857,
  0.22603070565973946,
  0.22598432569253424,
  -0.22599275859607648,
  -0.22600915159543014,
  0.07533559105142006,
  0.07533478851866574,
  0,
];

/// Cumulative sum over blocks of `length`, only counting (data-threshold)
List<int> runSum(List<int> data, int length, int threshold) {
  final int N = data.length;
  final int cnt = (N / length).ceil();
  final rs = List<int>.filled(cnt, 0);
  for (int n = 0; n < cnt; n++) {
    for (int p = n * length; p < (n + 1) * length; p++) {
      if (p < N && data[p] >= threshold) {
        rs[n] += data[p] - threshold;
      }
    }
  }
  return rs;
}

/// Mirror-padding with odd symmetry
List<double> oddExt(List<double> x, int n) {
  final left = x.sublist(0, n).reversed.map((d) => 2 * x.first - d).toList();
  final right =
      x.sublist(x.length - n).reversed.map((d) => 2 * x.last - d).toList();
  return [...left, ...x, ...right];
}

List<double> _filter(
  List<double> b,
  List<double> a,
  List<double> x, [
  List<double>? ziParam,
]) {
  final int nfilt = max(b.length, a.length);

  // ✏️ FIX: if no ziParam, use the static _zi (length == nfilt for filtfilt)
  List<double> z;
  if (ziParam != null) {
    z = List<double>.from(ziParam);
  } else {
    // ensure _zi.length == nfilt
    if (_zi.length != nfilt) {
      throw StateError('Initial zi length (${_zi.length}) != nfilt ($nfilt)');
    }
    z = List<double>.from(_zi);
  }

  // scale initial state by first input
  z = z.map((d) => d * x[0]).toList();

  final y = List<double>.filled(x.length, 0.0);
  for (int i = 0; i < x.length; i++) {
    for (int order = nfilt - 1; order > 0; order--) {
      if (i >= order) {
        y[i - order]; // just to show order ≥1
        z[order - 1] =
            b[order] * x[i - order] - a[order] * y[i - order] + z[order];
      }
    }
    y[i] = b[0] * x[i] + z[0];
  }
  return y;
}

/// Zero-phase filtering by forward/backward IIR
List<double> filtfilt(List<double> b, List<double> a, List<double> x) {
  const int edge = 27;
  final data = oddExt(x, edge);
  final y = _filter(b, a, data);
  final y2 = _filter(b, a, y.reversed.toList());
  // remove padding
  return y2.reversed.toList().sublist(edge, y2.length - edge);
}

/// Standard causal IIR filter (zero initial state)
List<double> lfilter(List<double> b, List<double> a, List<double> x) {
  return _filter(b, a, x, List<double>.filled(b.length, 0.0));
}

/// Implements the “getCounts” pipeline
List<int> getCounts(List<double> values) {
  const double deadband = 0.068;
  const double peakThreshold = 2.13;
  const double adcResolution = 0.0164;
  const int integN = 10;
  const double gain = 0.965;

  // 1) band-pass / smoothing
  final filtered = filtfilt(B2, A2, values);

  // 2) causal IIR + gain
  final fx8up = lfilter(B.map((v) => v * gain).toList(), A, filtered);

  // 3) down-sample by 3 and clip to ±peakThreshold
  final fx8 = <double>[];
  for (int i = 0; i < fx8up.length; i += 3) {
    final d = fx8up[i];
    fx8.add(d.clamp(-peakThreshold, peakThreshold));
  }

  // 4) deadband and quantize
  final truncated =
      fx8.map((d) {
        final ad = d.abs();
        if (ad < deadband) return 0;
        return (ad / adcResolution).floor();
      }).toList();

  // 5) integrate counts
  return runSum(truncated, integN, 0);
}

/// Main entry: pass in a flat accelerometer stream [x0,y0,z0, x1,y1,z1, …]
double computeAccVM(List<double> xs, List<double> ys, List<double> zs) {
  // get per‐axis counts
  final cx = getCounts(xs);
  final cy = getCounts(ys);
  final cz = getCounts(zs);

  // sum each axis
  final sx = cx.fold<int>(0, (a, b) => a + b);
  final sy = cy.fold<int>(0, (a, b) => a + b);
  final sz = cz.fold<int>(0, (a, b) => a + b);

  // vector magnitude
  return sqrt(sx * sx + sy * sy + sz * sz);
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

List<double> resampleAccelerometerData(
  List<double> data,
  double originalHz,
  double targetHz,
) {
  if (originalHz <= 0 || targetHz <= 0) {
    throw ArgumentError('Sampling rates must be positive.');
  }

  // Calculate original time interval and total time
  double originalInterval = 1.0 / originalHz;
  double targetInterval = 1.0 / targetHz;
  double totalTime = (data.length - 1) * originalInterval;

  // Create timestamps for target data points
  int newLength = (totalTime / targetInterval).floor() + 1;
  List<double> newTimestamps = List.generate(
    newLength,
    (i) => i * targetInterval,
  );

  // Generate corresponding original timestamps
  List<double> originalTimestamps = List.generate(
    data.length,
    (i) => i * originalInterval,
  );

  // Perform linear interpolation
  List<double> resampled = [];
  int j = 0;
  for (double t in newTimestamps) {
    while (j < data.length - 2 && originalTimestamps[j + 1] < t) {
      j++;
    }

    double t0 = originalTimestamps[j];
    double t1 = originalTimestamps[j + 1];
    double y0 = data[j];
    double y1 = data[j + 1];

    double slope = (y1 - y0) / (t1 - t0);
    double interpolated = y0 + slope * (t - t0);
    resampled.add(interpolated);
  }

  return resampled;
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

    List<double> xs = resampleAccelerometerData(
      accSamplesInSameMinute
          .map((s) => (s.x / 1000 / 9.82).toDouble())
          .toList(),
      26,
      30,
    );
    List<double> ys = resampleAccelerometerData(
      accSamplesInSameMinute
          .map((s) => (s.y / 1000 / 9.82).toDouble())
          .toList(),
      26,
      30,
    );
    List<double> zs = resampleAccelerometerData(
      accSamplesInSameMinute
          .map((s) => (s.z / 1000 / 9.82).toDouble())
          .toList(),
      26,
      30,
    );
    double accVM = computeAccVM(xs, ys, zs);

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
