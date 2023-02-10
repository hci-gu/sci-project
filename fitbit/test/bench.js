const runTest = (times) => {
  const accX = new Float32Array(1800)
  const accY = new Float32Array(1800)
  const accZ = new Float32Array(1800)

  // accData is a 5400 length array of 3 axis values
  for (let i = 0; i < 1800; i++) {
    accX[i] = accData[i * 3] / 9.82
    accY[i] = accData[i * 3 + 1] / 9.82
    accZ[i] = accData[i * 3 + 2] / 9.82
  }
  let totalTime = 0

  for (let i = 0; i < times; i++) {
    let start = new Date().getTime()
    calculateCounts(accX, accY, accZ)
    const timeSpent = new Date().getTime() - start
    print(`Test run ${i + 1} took ${timeSpent}ms`)
    totalTime += timeSpent
  }

  print(`Total time spent: ${totalTime}ms`)
  print(`Average time spent: ${totalTime / times}ms`)
}

runTest(25)
