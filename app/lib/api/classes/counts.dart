import 'dart:convert';

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
  final int n = data.length;
  final int cnt = (n / length).ceil();
  final rs = List<int>.filled(cnt, 0);
  for (int block = 0; block < cnt; block++) {
    for (int p = block * length; p < (block + 1) * length; p++) {
      if (p < n && data[p] >= threshold) {
        rs[block] += data[p] - threshold;
      }
    }
  }
  return rs;
}

/// Mirror-padding with odd symmetry (clamped to input length)
List<double> oddExt(List<double> x, int n) {
  if (x.isEmpty) return const [];
  final int k = n.clamp(0, x.length);
  final left = x.sublist(0, k).reversed.map((d) => 2 * x.first - d).toList();
  final right =
      x.sublist(x.length - k).reversed.map((d) => 2 * x.last - d).toList();
  return [...left, ...x, ...right];
}

List<double> _filter(
  List<double> b,
  List<double> a,
  List<double> x, [
  List<double>? ziParam,
]) {
  if (x.isEmpty) return const [];
  final int nfilt = max(b.length, a.length);

  // If no zi provided, use the canonical _zi (meant for filtfilt with B2/A2)
  // Guard to avoid silent length mismatch.
  List<double> z;
  if (ziParam != null) {
    z = List<double>.from(ziParam);
    if (z.length != nfilt) {
      // Pad or trim to nfilt to be robust
      z = List<double>.from(z)..length = nfilt;
      for (int i = 0; i < nfilt; i++) {
        z[i] = i < ziParam.length ? ziParam[i] : 0.0;
      }
    }
  } else {
    if (_zi.length != nfilt) {
      throw StateError(
        'Missing zi for filter of order $nfilt. '
        'Provide ziParam (length $nfilt), or use B2/A2 with filtfilt which matches _zi.',
      );
    }
    z = List<double>.from(_zi);
  }

  // Scale initial state by first input (JS parity)
  for (int i = 0; i < z.length; i++) {
    z[i] *= x.first;
  }

  final y = List<double>.filled(x.length, 0.0);
  for (int i = 0; i < x.length; i++) {
    for (int order = nfilt - 1; order > 0; order--) {
      if (i >= order) {
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
  if (x.isEmpty) return const [];
  final data = oddExt(x, edge);
  final y = _filter(b, a, data);
  final y2 = _filter(b, a, y.reversed.toList()).reversed.toList();

  // Match JS's safe slicing (empty result if not enough length)
  if (y2.length < 2 * edge) return const [];
  return y2.sublist(edge, y2.length - edge);
}

/// Standard causal IIR filter (zero initial state)
List<double> lfilter(List<double> b, List<double> a, List<double> x) {
  final int nfilt = max(a.length, b.length);
  return _filter(b, a, x, List<double>.filled(nfilt, 0.0));
}

/// Implements the “getCounts” pipeline
List<int> getCounts(List<double> values) {
  const double deadband = 0.068;
  const double peakThreshold = 2.13;
  const double adcResolution = 0.0164;
  const int integN = 10;
  const double gain = 0.965;

  // 1) zero-phase band-pass / smoothing
  final filtered = filtfilt(B2, A2, values);

  // 2) causal IIR + gain
  final fx8up = lfilter(B.map((v) => v * gain).toList(), A, filtered);

  // 3) down-sample by 3 and clip to ±peakThreshold
  final fx8 = <double>[];
  for (int i = 0; i < fx8up.length; i += 3) {
    fx8.add(fx8up[i].clamp(-peakThreshold, peakThreshold));
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

/// Main entry: pass in already separated axis streams
double computeAccVM(List<double> xs, List<double> ys, List<double> zs) {
  final cx = getCounts(xs);
  final cy = getCounts(ys);
  final cz = getCounts(zs);

  final sx = cx.fold<int>(0, (a, b) => a + b);
  final sy = cy.fold<int>(0, (a, b) => a + b);
  final sz = cz.fold<int>(0, (a, b) => a + b);

  return sqrt(sx * sx + sy * sy + sz * sz);
}

class Counts {
  final DateTime t;
  final double hr;
  final double a;

  Counts({required this.t, required this.hr, required this.a});

  static Counts fromJson(Map<String, dynamic> json) {
    return CountsExtension.fromJson(json);
  }
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
  if (data.isEmpty) return const [];

  final double originalInterval = 1.0 / originalHz;
  final double targetInterval = 1.0 / targetHz;
  final double totalTime = (data.length - 1) * originalInterval;

  final int newLength = (totalTime / targetInterval).floor() + 1;
  final List<double> newTimestamps = List.generate(
    newLength,
    (i) => i * targetInterval,
  );

  final List<double> originalTimestamps = List.generate(
    data.length,
    (i) => i * originalInterval,
  );

  final List<double> resampled = [];
  int j = 0;
  for (final t in newTimestamps) {
    while (j < data.length - 2 && originalTimestamps[j + 1] < t) {
      j++;
    }
    final double t0 = originalTimestamps[j];
    final double t1 = originalTimestamps[j + 1];
    final double y0 = data[j];
    final double y1 = data[j + 1];

    final double slope = (y1 - y0) / (t1 - t0);
    final double interpolated = y0 + slope * (t - t0);
    resampled.add(interpolated);
  }

  return resampled;
}

List<Counts> countsFromPolarData(
  AccOfflineRecording accRecording,
  HrOfflineRecording hrRecording,
) {
  if (accRecording.data.samples.isEmpty || hrRecording.data.samples.isEmpty) {
    print("countsFromPolarData: empty recordings");
    return [];
  }

  // sort ACC samples by time
  accRecording.data.samples.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));

  final DateTime start = hrRecording.startTime;
  final int hrMinutes = (hrRecording.data.samples.length / 60).ceil();
  final int totalHr = hrRecording.data.samples.length;

  final List<Counts> counts = [];
  for (int i = 0; i <= hrMinutes; i++) {
    final DateTime t0 = start.add(Duration(minutes: i));
    final DateTime t1 = t0.add(const Duration(minutes: 1));

    // Include left boundary, exclude right: [t0, t1)
    final List<PolarAccSample> accSamplesInSameMinute =
        accRecording.data.samples.where((s) {
          final ts = s.timeStamp;
          return !ts.isBefore(t0) && ts.isBefore(t1);
        }).toList();

    if (accSamplesInSameMinute.length < 30) {
      continue;
    }

    final List<double> xs = resampleAccelerometerData(
      accSamplesInSameMinute.map((s) => (s.x / 1000).toDouble()).toList(),
      50,
      30,
    );
    final List<double> ys = resampleAccelerometerData(
      accSamplesInSameMinute.map((s) => (s.y / 1000).toDouble()).toList(),
      50,
      30,
    );
    final List<double> zs = resampleAccelerometerData(
      accSamplesInSameMinute.map((s) => (s.z / 1000).toDouble()).toList(),
      50,
      30,
    );

    final double accVM = computeAccVM(xs, ys, zs);

    final int hrIndexStart = i * 60;
    if (hrIndexStart >= totalHr) break;
    final int hrIndexEnd = min((i + 1) * 60, totalHr);
    final List<PolarHrSample> hrSamplesInSameMinute = hrRecording.data.samples
        .sublist(hrIndexStart, hrIndexEnd);

    if (hrSamplesInSameMinute.isEmpty) continue;

    final double avgHr =
        hrSamplesInSameMinute
            .map((s) => s.hr.toDouble())
            .reduce((a, b) => a + b) /
        hrSamplesInSameMinute.length;

    counts.add(Counts(t: t0, hr: avgHr, a: accVM));
  }
  print("done counts, length = ${counts.length}");

  return counts;
}
