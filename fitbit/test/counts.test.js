import calculateCounts from '../app/counts'
import accData from './accData'

describe('calculateCounts', () => {
  it('should return the correct counts', () => {
    const counts = calculateCounts(accData)
    expect(counts).toEqual(1)
  })
})
