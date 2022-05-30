const handleData = (batches) => {
  accelDataPoints = []
  hrDataPoints = []
  batches.forEach(({ type, data }) => {
    data.forEach((value) => {
      if (type === 'heartRate') {
        hrDataPoints.push({
          t: value[0],
          hr: value[1],
        })
      }
      if (type === 'accel') {
        accelDataPoints.push({
          t: value[0],
          x: value[1],
          y: value[2],
          z: value[3],
        })
      }
    })
  })

  return { accelDataPoints, hrDataPoints }
}

module.exports = {
  handleData,
}
