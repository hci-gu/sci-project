const ACCEL_FREQUENCY = 20

const handleData = (batches) => {
  accelDataPoints = []
  hrDataPoints = []
  batches
    .map((d) => JSON.parse(d))
    .forEach(({ type, start, end, data }) => {
      data.forEach((value, i) => {
        if (type === 'heartRate') {
          hrDataPoints.push({
            t: start + 1000 * i,
            v: value,
          })
        }
        if (type === 'accel') {
          accelDataPoints.push({
            t: start + (1000 / ACCEL_FREQUENCY) * i,
            v: value,
          })
        }
      })
    })

  return { accelDataPoints, hrDataPoints }
}

module.exports = {
  handleData,
}
