type DataPoint = {
  id: number
  t: Date
  [key: string]: any
}
type GroupFunction = (d: DataPoint) => string
type GroupedData = {
  [key: string]: DataPoint[]
}
export const group = (data: DataPoint[], f: GroupFunction): GroupedData => {
  const groups: any = {}
  data.forEach((d) => {
    const key = f(d)
    if (!groups[key]) groups[key] = []
    groups[key].push(d)
  })
  return groups
}

export const getMinute = (ts: Date): string => {
  const d = new Date(ts)
  return `${d.getFullYear()}-${
    d.getMonth() + 1
  }-${d.getDate()} ${d.getHours()}:${d.getMinutes()}`
}

type PromiseFunction = (d: any) => Promise<any>
export const promiseSeries = (items: any[], method: PromiseFunction) => {
  const results: any[] = []

  function runMethod(item: any) {
    return new Promise((resolve, reject) => {
      method(item)
        .then((res) => {
          results.push(res)
          resolve(res)
        })
        .catch((err) => reject(err))
    })
  }

  return items
    .reduce(
      (promise, item) => promise.then(() => runMethod(item)),
      Promise.resolve()
    )
    .then(() => results)
}
