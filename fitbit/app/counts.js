const getCounts = (values) => {
  return values
}

export default (acc) => {
  const [xs, ys, zs] = [
    getCounts(acc.filter((_, i) => i % 3 === 0).map((d) => d / 9.82)),
    getCounts(acc.filter((_, i) => i % 3 === 1).map((d) => d / 9.82)),
    getCounts(acc.filter((_, i) => i % 3 === 2).map((d) => d / 9.82)),
  ]
  const x = xs.reduce((a, b) => a + b)
  const y = ys.reduce((a, b) => a + b)
  const z = zs.reduce((a, b) => a + b)
  const accVM = Math.sqrt(x * x + y * y + z * z)

  return accVM
}
