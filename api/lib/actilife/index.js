const spawn = require('child_process').spawn;
const fs = require('fs')
const path = require('path')

const counts = ({ acc, f }) => new Promise((resolve, reject) => {
  fs.writeFileSync('/tmp/accel.json', JSON.stringify(acc))
  const process = spawn('python3', [path.join(__dirname, 'counts.py'), '/tmp/accel.json', `${f}`])
  let output = ''
  let error = ''
  process.stdout.on('data', data => {
    output = output + data.toString()
  })
  process.stdout.on('close', () => {
    if (error !== '') {
      reject(error)
    } else {
      resolve(JSON.parse(output))
    }
  })
  process.stderr.on('data', (d) => {
    error = error + d.toString()
  })
})

module.exports = {
  counts,
}
