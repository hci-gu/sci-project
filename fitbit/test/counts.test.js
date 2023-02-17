import calculateCounts from '../app/counts'
// import calculateCounts from '../app/counts_memwatch'
import accData from './accData'

describe('calculateCounts', () => {
  it('should return the correct counts', async () => {
    const length = 1800
    const accX = new Float32Array(length)
    const accY = new Float32Array(length)
    const accZ = new Float32Array(length)

    // accData is a 5400 length array of 3 axis values
    for (let i = 0; i < length; i++) {
      accX[i] = accData[i * 3] / 9.82
      accY[i] = accData[i * 3 + 1] / 9.82
      accZ[i] = accData[i * 3 + 2] / 9.82
    }

    const counts = await calculateCounts(accX, accY, accZ)
    // expect(counts).toEqual(15351.626428492846) // before memchanges
    // expect(counts).toEqual(15388.939729559019) // after small bugfix
    // expect(counts).toEqual(15575.106099157078) // changed to Float32Array AB2
    expect(counts).toEqual(15569.778579029311) // changed to Float32Array AB
  })
})
