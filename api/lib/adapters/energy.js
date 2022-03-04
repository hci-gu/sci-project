const A_coeff =
  [1, -4.1637, 7.5712,-7.9805, 5.385, -2.4636, 0.89238, 0.06361, -1.3481, 2.4734, -2.9257, 2.9298, -2.7816, 2.4777,
   -1.6847, 0.46483, 0.46565, -0.67312, 0.4162, -0.13832, 0.019852]

const B_coeff =
  [0.049109, -0.12284, 0.14356, -0.11269, 0.053804, -0.02023, 0.0063778, 0.018513, -0.038154, 0.048727, -0.052577,
   0.047847, -0.046015, 0.036283, -0.012977, -0.0046262, 0.012835, -0.0093762, 0.0034485, -0.00080972, -0.00019623]

const pptrunc = ({ data, max_value }) => {
  //  Saturate a vector such that no element's absolute value exceeds max_abs_value.
  //  Current name: absolute_saturate().
  //    :param data: a vector of any dimension containing numerical data
  //    :param max_value: a float value of the absolute value to not exceed
  //    :return: the saturated vector

   return data.map(x => Math.min(max_value, Math.max(-max_value, x)))
}

const truct => ({ data, min_value }) => {
// def trunc(data, min_value):
 
//    '''
//    Truncate a vector such that any value lower than min_value is set to 0.
//    Current name zero_truncate().
//    :param data: a vector of any dimension containing numerical data
//    :param min_value: a float value the elements of data should not fall below
//    :return: the truncated vector
//    '''

//    return np.where(data < min_value, 0, data)
  return data.map(x => Math.max(min_value, x))
}

const runsum = ({ data, length, threshold }) => {
// def runsum(data, length, threshold):
//    '''
//    Compute the running sum of values in a vector exceeding some threshold within a range of indices.
//    Divides the data into len(data)/length chunks and sums the values in excess of the threshold for each chunk.
//    Current name run_sum().
//    :param data: a 1D numerical vector to calculate the sum of
//    :param len: the length of each chunk to compute a sum along, as a positive integer
//    :param threshold: a numerical value used to find values exceeding some threshold
//    :return: a vector of length len(data)/length containing the excess value sum for each chunk of data
//    '''
   
//    N = len(data)
//    cnt = int(math.ceil(N/length))

//    rs = np.zeros(cnt)

//    for n in range(cnt):
//        for p in range(length*n, length*(n+1)):
//            if p<N and data[p]>=threshold:
//                rs[n] = rs[n] + data[p] - threshold

//    return rs
  const N = data.length
  const cnt = Math.ceil(N/length)
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

const counts = ({ data, filesf, B = B_coeff, A = A_coeff }) => {
    // '''
    // Get activity counts for a set of accelerometer observations.
    // First resamples the data frequency to 30Hz, then applies a Butterworth filter to the signal, then filters by the
    // coefficient matrices, saturates and truncates the result, and applies a running sum to get the final counts.
    // Current name get_actigraph_counts()
    // :param data: the vertical axis of accelerometer readings, as a vector
    // :param filesf: the number of observations per second in the file
    // :param a: coefficient matrix for filtering the signal, as found by Jan Brond
    // :param b: coefficient matrix for filtering the signal, as found by Jan Brond
    // :return: a vector containing the final counts
    // '''
    
    const deadband = 0.068
    const sf = 30
    const peakThreshold = 2.13
    const adcResolution = 0.0164
    const integN = 10
    const gain = 0.965

    // if filesf>sf:
    //     data = resampy.resample(np.asarray(data), filesf, sf)

    if (filesf > sf) {
      data = resample(data, filesf, sf)
    }

    // B2, A2 = signal.butter(4, np.array([0.01, 7])/(sf/2), btype='bandpass')
    // dataf = signal.filtfilt(B2, A2, data)

    // B = B * gain

    // #NB: no need for a loop here as we only have one axis in array
    // fx8up = signal.lfilter(B, A, dataf)

    // fx8 = pptrunc(fx8up[::3], peakThreshold) #downsampling is replaced by slicing with step parameter

    // return runsum(np.floor(trunc(np.abs(fx8), deadband)/adcResolution), integN, 0)
}


const standardCoeff = {
  constant: -0.022223,
  hr: 0.000281,
  weight: 0.000081,
  acc: 0.000002,
}

const getEnergy = ({ accel, hr, weight, coeff = standardCoeff }) => {
  // resample accelerometer data to 30hz
  // run algorithm
}

module.exports = {

}