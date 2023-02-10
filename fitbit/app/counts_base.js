const A = [
  1, -4.1637, 7.5712, -7.9805, 5.385, -2.4636, 0.89238, 0.06361, -1.3481,
  2.4734, -2.9257, 2.9298, -2.7816, 2.4777, -1.6847, 0.46483, 0.46565, -0.67312,
  0.4162, -0.13832, 0.019852,
]
const B = [
  0.049109, -0.12284, 0.14356, -0.11269, 0.053804, -0.02023, 0.0063778,
  0.018513, -0.038154, 0.048727, -0.052577, 0.047847, -0.046015, 0.036283,
  -0.012977, -0.0046262, 0.012835, -0.0093762, 0.0034485, -0.00080972,
  -0.00019623,
]

const B2 = [
  0.0753349039750657, 0.0, -0.3013396159002628, 0.0, 0.4520094238503942, 0.0,
  -0.3013396159002628, 0.0, 0.0753349039750657,
]
const A2 = [
  1.0, -4.2575497111306, 7.543176557521139, -7.64673626503976, 5.33187310787808,
  -2.7027389238066353, 0.8452545660100996, -0.1323148049950936,
  0.019035473586069288,
]

// Filter initial response
const zi = [
  -0.07532883864659122, -0.0753546620840857, 0.22603070565973946,
  0.22598432569253424, -0.22599275859607648, -0.22600915159543014,
  0.07533559105142006, 0.07533478851866574, 0,
]

const runsum = (data, length, threshold) => {
  const N = data.length
  const cnt = Math.ceil(N / length)

  // create rs with cnt zeroes, oneliner
  const rs = Array(cnt).fill(0)

  for (let n = 0; n < cnt; n++) {
    for (let p = length * n; p < length * (n + 1); p++) {
      if (p < N && data[p] >= threshold) {
        rs[n] += data[p] - threshold
      }
    }
  }

  return rs
}

const odd_ext = (x, n) => {
  const left = x
    .slice(0, n)
    .reverse()
    .map((d) => 2 * x[0] - d)
  const right = x
    .slice(-n)
    .reverse()
    .map((d) => 2 * x[x.length - 1] - d)
  return left.concat(x, right)
}

const filter = (b, a, x, z = zi) => {
  const y = []
  z = z.map((d) => d * x[0])
  const nfilt = Math.max(b.length, a.length)
  for (var i = 0; i < x.length; i++) {
    let order = nfilt - 1
    while (order > 0) {
      if (i >= order) {
        z[order - 1] =
          b[order] * x[i - order] - a[order] * y[i - order] + z[order]
      }
      order--
    }
    y[i] = b[0] * x[i] + z[0]
  }
  return y
}

const filtfilt = (b, a, x) => {
  const edge = 27
  const data = odd_ext(x, edge)
  const y = filter(b, a, data)
  const y2 = filter(b, a, y.reverse())
  return y2.reverse().slice(edge, -edge)
}

const lfilter = (b, a, x) => {
  const zi = Array(b.length).fill(0)
  return filter(b, a, x, zi)
}

const getCounts = (values) => {
  const deadband = 0.068
  const peakThreshold = 2.13
  const adcResolution = 0.0164
  const integN = 10
  const gain = 0.965

  const filtered = filtfilt(B2, A2, values)

  const fx8up = lfilter(
    B.map((x) => x * gain),
    A,
    filtered
  )

  const fx8 = fx8up
    .filter((_, i) => i % 3 === 0)
    .map((d) =>
      d < -peakThreshold
        ? -peakThreshold
        : d > peakThreshold
        ? peakThreshold
        : d
    )

  const truncated = fx8.map((d) =>
    Math.abs(d) < deadband ? 0 : Math.floor(Math.abs(d) / adcResolution)
  )

  return runsum(truncated, integN, 0)
}

export default (acc) => {
  const [xs, ys, zs] = [
    getCounts(acc.filter((_, i) => i % 3 === 0).map((d) => d / 9.82)),
    getCounts(acc.filter((_, i) => i % 3 === 1).map((d) => d / 9.82)),
    getCounts(acc.filter((_, i) => i % 3 === 2).map((d) => d / 9.82)),
  ]
  const x = xs.reduce((a, b) => a + b)
  const y = ys.reduce((a, b) => a + b)
  const z = zs.reduce((a, b) => a + b)
  const accVM = Math.sqrt(x * x + y * y + z * z)

  return accVM
}
