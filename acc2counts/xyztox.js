const data = require('./accel.json')

const output = data.map(d => d.x)

console.log(JSON.stringify(output))
