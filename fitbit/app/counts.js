// Filter initial response
const zi = [
  -0.07532883864659122, -0.0753546620840857, 0.22603070565973946,
  0.22598432569253424, -0.22599275859607648, -0.22600915159543014,
  0.07533559105142006, 0.07533478851866574, 0,
]
const zi_zeros = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

const runsum = (data, length, threshold) => {
  const N = data.length
  const cnt = Math.ceil(N / length)

  // create rs with cnt zeroes, oneliner
  const rs = new Float32Array(cnt)
  for (var i = 0; i < cnt; i++) {
    rs[i] = 0
  }

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
  const result = new Float32Array(x.length + 2 * n)
  const left = x.subarray(0, n)
  for (let i = 0; i < n; i++) {
    result[i] = 2 * x[0] - left[n - i - 1]
  }
  const right = x.subarray(x.length - n)
  for (let i = 0; i < n; i++) {
    result[result.length - n + i] = 2 * x[x.length - 1] - right[n - i - 1]
  }
  result.set(x, n)
  return result
}

const filterAB2 = (x, z = zi) => {
  const y = x
  z = z.map((d) => d * x[0])
  const x0 = new Float32Array(9)
  for (let i = 0; i < x0.length; i++) {
    x0[i] = x[i]
  }
  for (var i = 0; i < 9; i++) {
    if (i >= 8)
      z[7] =
        0.0753349039750657 * x0[i - 8] - 0.019035473586069288 * y[i - 8] + z[8]
    if (i >= 7) z[6] = -(-0.1323148049950936) * y[i - 7] + z[7]
    if (i >= 6)
      z[5] =
        -0.3013396159002628 * x0[i - 6] - 0.8452545660100996 * y[i - 6] + z[6]
    if (i >= 5) z[4] = -(-2.7027389238066353) * y[i - 5] + z[5]
    if (i >= 4)
      z[3] = 0.4520094238503942 * x0[i - 4] - 5.33187310787808 * y[i - 4] + z[4]
    if (i >= 3) z[2] = -(-7.64673626503976) * y[i - 3] + z[3]
    if (i >= 2)
      z[1] =
        -0.3013396159002628 * x0[i - 2] - 7.543176557521139 * y[i - 2] + z[2]
    if (i >= 1) z[0] = -(-4.2575497111306) * y[i - 1] + z[1]

    y[i] = x[i] = 0.0753349039750657 * x[i] + z[0]
  }
  let yi8 = y[0],
    yi7 = y[1],
    yi6 = y[2],
    yi5 = y[3],
    yi4 = y[4],
    yi3 = y[5],
    yi2 = y[6],
    yi1 = y[7]
  let xi8 = x0[0],
    xi7 = x0[1],
    xi6 = x0[2],
    xi5 = x0[3],
    xi4 = x0[4],
    xi3 = x0[5],
    xi2 = x0[6],
    xi1 = x0[7]
  for (var i = 9; i < x.length; i++) {
    let za = z[8]
    za = 0.0753349039750657 * xi8 - 0.019035473586069288 * yi8 + za
    za = -(-0.1323148049950936) * yi7 + za
    za = -0.3013396159002628 * xi6 - 0.8452545660100996 * yi6 + za
    za = -(-2.7027389238066353) * yi5 + za
    za = 0.4520094238503942 * xi4 - 5.33187310787808 * yi4 + za
    za = -(-7.64673626503976) * yi3 + za
    za = -0.3013396159002628 * xi2 - 7.543176557521139 * yi2 + za
    za = -(-4.2575497111306) * yi1 + za
    yi8 = yi7
    yi7 = yi6
    yi6 = yi5
    yi5 = yi4
    yi4 = yi3
    yi3 = yi2
    yi2 = yi1
    yi1 = 0.0753349039750657 * x[i] + za
    xi8 = xi7
    xi7 = xi6
    xi6 = xi5
    xi5 = xi4
    xi4 = xi3
    xi3 = xi2
    xi2 = xi1
    xi1 = x[i]
    y[i] = x[i] = yi1
  }
  return y
}

const filterAB2Reverse = (x, z = zi) => {
  const y = x
  z = z.map((d) => d * x[x.length - 1])
  const x0 = new Float32Array(9)
  for (let i = 0; i < x0.length; i++) {
    x0[i] = x[x.length - 9 + i]
  }
  for (var i = 0; i < 9; i++) {
    if (i >= 8)
      z[7] =
        0.0753349039750657 * x0[x0.length - 1 - i + 8] -
        0.019035473586069288 * y[x.length - 1 - i + 8] +
        z[8]
    if (i >= 7) z[6] = -(-0.1323148049950936) * y[x.length - 1 - i + 7] + z[7]
    if (i >= 6)
      z[5] =
        -0.3013396159002628 * x0[x0.length - 1 - i + 6] -
        0.8452545660100996 * y[x.length - 1 - i + 6] +
        z[6]
    if (i >= 5) z[4] = -(-2.7027389238066353) * y[x.length - 1 - i + 5] + z[5]
    if (i >= 4)
      z[3] =
        0.4520094238503942 * x0[x0.length - 1 - i + 4] -
        5.33187310787808 * y[x.length - 1 - i + 4] +
        z[4]
    if (i >= 3) z[2] = -(-7.64673626503976) * y[x.length - 1 - i + 3] + z[3]
    if (i >= 2)
      z[1] =
        -0.3013396159002628 * x0[x0.length - 1 - i + 2] -
        7.543176557521139 * y[x.length - 1 - i + 2] +
        z[2]
    if (i >= 1) z[0] = -(-4.2575497111306) * y[x.length - 1 - i + 1] + z[1]

    y[x.length - 1 - i] = x[x.length - 1 - i] =
      0.0753349039750657 * x0[x0.length - 1 - i] + z[0]
  }

  let yi8 = y[y.length - 1],
    yi7 = y[y.length - 2],
    yi6 = y[y.length - 3],
    yi5 = y[y.length - 4],
    yi4 = y[y.length - 5],
    yi3 = y[y.length - 6],
    yi2 = y[y.length - 7],
    yi1 = y[y.length - 8]
  let xi8 = x0[x0.length - 1],
    xi7 = x0[x0.length - 2],
    xi6 = x0[x0.length - 3],
    xi5 = x0[x0.length - 4],
    xi4 = x0[x0.length - 5],
    xi3 = x0[x0.length - 6],
    xi2 = x0[x0.length - 7],
    xi1 = x0[x0.length - 8]
  for (var i = 9; i < x.length; i++) {
    let za = z[8]
    za = 0.0753349039750657 * xi8 - 0.019035473586069288 * yi8 + za
    za = -(-0.1323148049950936) * yi7 + za
    za = -0.3013396159002628 * xi6 - 0.8452545660100996 * yi6 + za
    za = -(-2.7027389238066353) * yi5 + za
    za = 0.4520094238503942 * xi4 - 5.33187310787808 * yi4 + za
    za = -(-7.64673626503976) * yi3 + za
    za = -0.3013396159002628 * xi2 - 7.543176557521139 * yi2 + za
    za = -(-4.2575497111306) * yi1 + za
    yi8 = yi7
    yi7 = yi6
    yi6 = yi5
    yi5 = yi4
    yi4 = yi3
    yi3 = yi2
    yi2 = yi1
    yi1 = 0.0753349039750657 * x[x.length - 1 - i] + za
    xi8 = xi7
    xi7 = xi6
    xi6 = xi5
    xi5 = xi4
    xi4 = xi3
    xi3 = xi2
    xi2 = xi1
    xi1 = x[x.length - 1 - i]
    y[x.length - 1 - i] = x[x.length - 1 - i] = yi1
  }
  return y
}

const filterAB = (x, z) => {
  const y = x
  z = z.map((d) => d * x[0])
  const x0 = new Float32Array(21)
  for (let i = 0; i < x0.length; i++) {
    x0[i] = x[i]
  }
  for (var i = 0; i < 21; i++) {
    if (i >= 20)
      z[19] = -0.00018936195 * x0[i - 20] - 0.019852 * y[i - 20] + z[20]
    if (i >= 19)
      z[18] = -0.0007813798 * x0[i - 19] - -0.13832 * y[i - 19] + z[19]
    if (i >= 18) z[17] = 0.0033278025 * x0[i - 18] - 0.4162 * y[i - 18] + z[18]
    if (i >= 17)
      z[16] = -0.009048032999999999 * x0[i - 17] - -0.67312 * y[i - 17] + z[17]
    if (i >= 16)
      z[15] = 0.012385774999999998 * x0[i - 16] - 0.46565 * y[i - 16] + z[16]
    if (i >= 15)
      z[14] = -0.0044642829999999994 * x0[i - 15] - 0.46483 * y[i - 15] + z[15]
    if (i >= 14) z[13] = -0.012522805 * x0[i - 14] - -1.6847 * y[i - 14] + z[14]
    if (i >= 13) z[12] = 0.035013095 * x0[i - 13] - 2.4777 * y[i - 13] + z[13]
    if (i >= 12) z[11] = -0.044404475 * x0[i - 12] - -2.7816 * y[i - 12] + z[12]
    if (i >= 11) z[10] = 0.046172355 * x0[i - 11] - 2.9298 * y[i - 11] + z[11]
    if (i >= 10)
      z[9] = -0.050736804999999996 * x0[i - 10] - -2.9257 * y[i - 10] + z[10]
    if (i >= 9) z[8] = 0.047021555 * x0[i - 9] - 2.4734 * y[i - 9] + z[9]
    if (i >= 8) z[7] = -0.03681861 * x0[i - 8] - -1.3481 * y[i - 8] + z[8]
    if (i >= 7) z[6] = 0.017865045 * x0[i - 7] - 0.06361 * y[i - 7] + z[7]
    if (i >= 6)
      z[5] = 0.0061545770000000005 * x0[i - 6] - 0.89238 * y[i - 6] + z[6]
    if (i >= 5) z[4] = -0.01952195 * x0[i - 5] - -2.4636 * y[i - 5] + z[5]
    if (i >= 4) z[3] = 0.05192086 * x0[i - 4] - 5.385 * y[i - 4] + z[4]
    if (i >= 3)
      z[2] = -0.10874584999999999 * x0[i - 3] - -7.9805 * y[i - 3] + z[3]
    if (i >= 2)
      z[1] = 0.13853539999999998 * x0[i - 2] - 7.5712 * y[i - 2] + z[2]
    if (i >= 1) z[0] = -0.1185406 * x0[i - 1] - -4.1637 * y[i - 1] + z[1]

    y[i] = x[i] = 0.047390185 * x0[i] + z[0]
  }
  let yi20 = y[0],
    yi19 = y[1],
    yi18 = y[2],
    yi17 = y[3],
    yi16 = y[4],
    yi15 = y[5],
    yi14 = y[6],
    yi13 = y[7],
    yi12 = y[8],
    yi11 = y[9],
    yi10 = y[10],
    yi9 = y[11],
    yi8 = y[12],
    yi7 = y[13],
    yi6 = y[14],
    yi5 = y[15],
    yi4 = y[16],
    yi3 = y[17],
    yi2 = y[18],
    yi1 = y[19]

  let xi20 = x0[0],
    xi19 = x0[1],
    xi18 = x0[2],
    xi17 = x0[3],
    xi16 = x0[4],
    xi15 = x0[5],
    xi14 = x0[6],
    xi13 = x0[7],
    xi12 = x0[8],
    xi11 = x0[9],
    xi10 = x0[10],
    xi9 = x0[11],
    xi8 = x0[12],
    xi7 = x0[13],
    xi6 = x0[14],
    xi5 = x0[15],
    xi4 = x0[16],
    xi3 = x0[17],
    xi2 = x0[18],
    xi1 = x0[19]
  for (var i = 21; i < x.length; i++) {
    let za = z[20]

    za = -0.00018936195 * xi20 - 0.019852 * yi20 + za
    za = -0.0007813798 * xi19 - -0.13832 * yi19 + za
    za = 0.0033278025 * xi18 - 0.4162 * yi18 + za
    za = -0.009048032999999999 * xi17 - -0.67312 * yi17 + za
    za = 0.012385774999999998 * xi16 - 0.46565 * yi16 + za
    za = -0.0044642829999999994 * xi15 - 0.46483 * yi15 + za
    za = -0.012522805 * xi14 - -1.6847 * yi14 + za
    za = 0.035013095 * xi13 - 2.4777 * yi13 + za
    za = -0.044404475 * xi12 - -2.7816 * yi12 + za
    za = 0.046172355 * xi11 - 2.9298 * yi11 + za
    za = -0.050736804999999996 * xi10 - -2.9257 * yi10 + za
    za = 0.047021555 * xi9 - 2.4734 * yi9 + za
    za = -0.03681861 * xi8 - -1.3481 * yi8 + za
    za = 0.017865045 * xi7 - 0.06361 * yi7 + za
    za = 0.0061545770000000005 * xi6 - 0.89238 * yi6 + za
    za = -0.01952195 * xi5 - -2.4636 * yi5 + za
    za = 0.05192086 * xi4 - 5.385 * yi4 + za
    za = -0.10874584999999999 * xi3 - -7.9805 * yi3 + za
    za = 0.13853539999999998 * xi2 - 7.5712 * yi2 + za
    za = -0.1185406 * xi1 - -4.1637 * yi1 + za

    yi20 = yi19
    yi19 = yi18
    yi18 = yi17
    yi17 = yi16
    yi16 = yi15
    yi15 = yi14
    yi14 = yi13
    yi13 = yi12
    yi12 = yi11
    yi11 = yi10
    yi10 = yi9
    yi9 = yi8
    yi8 = yi7
    yi7 = yi6
    yi6 = yi5
    yi5 = yi4
    yi4 = yi3
    yi3 = yi2
    yi2 = yi1
    yi1 = 0.047390185 * x[i] + za
    xi20 = xi19
    xi19 = xi18
    xi18 = xi17
    xi17 = xi16
    xi16 = xi15
    xi15 = xi14
    xi14 = xi13
    xi13 = xi12
    xi12 = xi11
    xi11 = xi10
    xi10 = xi9
    xi9 = xi8
    xi8 = xi7
    xi7 = xi6
    xi6 = xi5
    xi5 = xi4
    xi4 = xi3
    xi3 = xi2
    xi2 = xi1
    xi1 = x[i]
    y[i] = x[i] = yi1
  }
  return y
}

const filtfilt = (x) => {
  const edge = 27
  const data = odd_ext(x, edge)
  const y = filterAB2(data)
  const y2 = filterAB2Reverse(y)
  return y2.subarray(edge, -edge)
}

const getCounts = (values) => {
  const deadband = 0.068
  const peakThreshold = 2.13
  const adcResolution = 0.0164
  const integN = 10

  return runsum(
    filterAB(filtfilt(values), zi_zeros)
      .filter((_, i) => i % 3 === 0)
      .map((d) =>
        d < -peakThreshold
          ? -peakThreshold
          : d > peakThreshold
          ? peakThreshold
          : d
      )
      .map((d) =>
        Math.abs(d) < deadband ? 0 : Math.floor(Math.abs(d) / adcResolution)
      ),
    integN,
    0
  ).reduce((a, b) => a + b, 0)
  // const filtered = filtfilt(values)
  // const fx8up = filterAB(filtered, zi_zeros)
  // const fx8 = fx8up
  //   .filter((_, i) => i % 3 === 0)
  //   .map((d) =>
  //     d < -peakThreshold
  //       ? -peakThreshold
  //       : d > peakThreshold
  //       ? peakThreshold
  //       : d
  //   )
  // const truncated = fx8.map((d) =>
  //   Math.abs(d) < deadband ? 0 : Math.floor(Math.abs(d) / adcResolution)
  // )
  // return runsum(truncated, integN, 0).reduce((a, b) => a + b, 0)
}

export default (accX, accY, accZ) => {
  const [x, y, z] = [getCounts(accX), getCounts(accY), getCounts(accZ)]
  return Math.sqrt(x * x + y * y + z * z)

  // return new Promise((resolve) => {
  //   setTimeout(() => {
  //     const x = getCounts(accX)
  //     setTimeout(() => {
  //       const y = getCounts(accY)
  //       setTimeout(() => {
  //         const z = getCounts(accZ)
  //         const accVM = Math.sqrt(x * x + y * y + z * z)
  //         resolve(accVM)
  //       }, 1)
  //     }, 1)
  //   }, 1)
  // })
}
