import calculateCounts from '../app/counts'
import calculateCountsSplit from '../app/counts_split'
import accData from './accData'

describe('calculateCounts', () => {
  it('should return the correct counts', async () => {
    const accX = new Float32Array(1800)
    const accY = new Float32Array(1800)
    const accZ = new Float32Array(1800)

    // accData is a 5400 length array of 3 axis values
    for (let i = 0; i < 1800; i++) {
      accX[i] = accData[i * 3] / 9.82
      accY[i] = accData[i * 3 + 1] / 9.82
      accZ[i] = accData[i * 3 + 2] / 9.82
    }

    const counts = await calculateCounts(accX, accY, accZ)
    expect(counts).toEqual(15351.626428492846)
  })
})
