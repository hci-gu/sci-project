const handleData = (batches) => {
  accelDataPoints = []
  hrDataPoints = []
  batches.forEach(({ type, data }) => {
    data.forEach((value) => {
      if (type === 'heartRate') {
        hrDataPoints.push({
          t: value[0],
          v: value[1],
        })
      }
      if (type === 'accel') {
        accelDataPoints.push({
          t: value[0],
          v: [value[1], value[2], value[3]],
        })
      }
    })
  })

  return { accelDataPoints, hrDataPoints }
}

module.exports = {
  handleData,
}
