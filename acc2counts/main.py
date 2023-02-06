import math
import numpy as np
import pandas as pd
import json

from scipy import signal

def custom_filter(b, a, x, zi):
    filter_order = max(len(a), len(b))
    y = []
    # make copy of zi into zi
    zi = np.copy(zi)
    # add a 0 to end of zi
    zi = np.append(zi, 0)
    for i in range(len(x)):
        order = filter_order - 1
        while order > 0:
            if (i >= order):
                zi[order - 1] = b[order] * x[i - order] - a[order] * y[i - order] + zi[order]
            order -= 1
        y.append(b[0] * x[i] + zi[0])
    return y

def custom_filtfilt(b, a, x, zi):
    # Apply 'odd' padding to input signal
    padding_length = 3 * max(len(a), len(b))  # the scipy.signal.filtfilt default
    x_forward = np.concatenate((
        [2 * x[0] - xi for xi in x[padding_length:0:-1]],
        x,
        [2 * x[-1] - xi for xi in x[-2:-padding_length-2:-1]]))

    # Filter forward
    y_forward = custom_filter(b, a, x_forward, zi * x_forward[0])

    # Filter backward
    x_backward = y_forward[::-1]  # reverse
    y_backward = custom_filter(b, a, x_backward, zi * x_backward[0])

    # Remove padding and reverse
    return y_backward[-padding_length-1:padding_length-1:-1]


# import resampy

A_coeff = np.array(
    [1, -4.1637, 7.5712,-7.9805, 5.385, -2.4636, 0.89238, 0.06361, -1.3481, 2.4734, -2.9257, 2.9298, -2.7816, 2.4777,
     -1.6847, 0.46483, 0.46565, -0.67312, 0.4162, -0.13832, 0.019852])
B_coeff = np.array(
    [0.049109, -0.12284, 0.14356, -0.11269, 0.053804, -0.02023, 0.0063778, 0.018513, -0.038154, 0.048727, -0.052577,
     0.047847, -0.046015, 0.036283, -0.012977, -0.0046262, 0.012835, -0.0093762, 0.0034485, -0.00080972, -0.00019623])

def pptrunc(data, max_value):
    '''
    Saturate a vector such that no element's absolute value exceeds max_abs_value.
    Current name: absolute_saturate().
      :param data: a vector of any dimension containing numerical data
      :param max_value: a float value of the absolute value to not exceed
      :return: the saturated vector
    '''
    outd = np.where(data > max_value, max_value, data)
    return np.where(outd < -max_value, -max_value, outd)

def trunc(data, min_value):
  
    '''
    Truncate a vector such that any value lower than min_value is set to 0.
    Current name zero_truncate().
    :param data: a vector of any dimension containing numerical data
    :param min_value: a float value the elements of data should not fall below
    :return: the truncated vector
    '''

    return np.where(data < min_value, 0, data)

def runsum(data, length, threshold):
    '''
    Compute the running sum of values in a vector exceeding some threshold within a range of indices.
    Divides the data into len(data)/length chunks and sums the values in excess of the threshold for each chunk.
    Current name run_sum().
    :param data: a 1D numerical vector to calculate the sum of
    :param len: the length of each chunk to compute a sum along, as a positive integer
    :param threshold: a numerical value used to find values exceeding some threshold
    :return: a vector of length len(data)/length containing the excess value sum for each chunk of data
    '''
    
    N = len(data)
    cnt = int(math.ceil(N/length))

    rs = np.zeros(cnt)

    for n in range(cnt):
        for p in range(length*n, length*(n+1)):
            if p<N and data[p]>=threshold:
                rs[n] = rs[n] + data[p] - threshold

    return rs

def counts(data, filesf, B=B_coeff, A=A_coeff):
    '''
    Get activity counts for a set of accelerometer observations.
    First resamples the data frequency to 30Hz, then applies a Butterworth filter to the signal, then filters by the
    coefficient matrices, saturates and truncates the result, and applies a running sum to get the final counts.
    Current name get_actigraph_counts()
    :param data: the vertical axis of accelerometer readings, as a vector
    :param filesf: the number of observations per second in the file
    :param a: coefficient matrix for filtering the signal, as found by Jan Brond
    :param b: coefficient matrix for filtering the signal, as found by Jan Brond
    :return: a vector containing the final counts
    '''
    
    deadband = 0.068
    sf = 30
    peakThreshold = 2.13
    adcResolution = 0.0164
    integN = 10
    gain = 0.965

    # if filesf>sf:
    #     data = resampy.resample(np.asarray(data), filesf, sf)

    B2, A2 = signal.butter(4, np.array([0.01, 7])/(sf/2), btype='bandpass')

    # zi = signal.lfilter_zi(B2, A2)
    # print(json.dumps(zi.tolist()))
    zi = [-0.07532883864659122, -0.0753546620840857, 0.22603070565973946, 0.22598432569253424, -0.22599275859607648, -0.22600915159543014, 0.07533559105142006, 0.07533478851866574]
    zi = np.asarray(zi)

    # dataf = signal.filtfilt(B2, A2, data)
    dataf = custom_filtfilt(B2, A2, data, zi)

    # return dataf[:10]

    B = B * gain

    #NB: no need for a loop here as we only have one axis in array
    fx8up = signal.lfilter(B, A, dataf)

    fx8 = pptrunc(fx8up[::3], peakThreshold) #downsampling is replaced by slicing with step parameter

    return runsum(np.floor(trunc(np.abs(fx8), deadband)/adcResolution), integN, 0)

import sys

filename = sys.argv[1]
freq = sys.argv[2]

f = open(sys.argv[1], 'r')
data = json.load(f)

# print(data)
cs = counts(data, int(freq))

# print(len(cs))
print(json.dumps(cs.tolist()))
