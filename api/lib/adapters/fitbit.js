const handleData = (batches) => {
  accelDataPoints = []
  hrDataPoints = []
  batches.forEach(({ type, start, data, frequency }) => {
    data.forEach((value, i) => {
      if (type === 'heartRate') {
        hrDataPoints.push({
          t: start + (1000 / frequency) * i,
          v: value,
        })
      }
      if (type === 'accel') {
        accelDataPoints.push({
          t: start + (1000 / frequency) * i,
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
