const spawn = require('child_process').spawn;
const fs = require('fs')
const path = require('path')

const counts = ({ acc, f }) => new Promise((resolve, reject) => {
  fs.writeFileSync('/tmp/accel.json', JSON.stringify(acc))
  console.log({ path: path.join(__dirname, 'counts.py') })
  const process = spawn('python3', [path.join(__dirname, 'counts.py'), '/tmp/accel.json', `${f}`])
  let output = ''
  let error = ''
  process.stdout.on('data', data => {
    console.log({ data })
    output = output + data.toString()
  })
  process.stdout.on('close', () => {
    if (error !== '') {
      console.log('error', error)
      reject(error)
    } else {
      console.log('result is', output)
      resolve(JSON.parse(output))
    }
  })
  process.stderr.on('data', (d) => {
    console.log({ error: d.toString() })
    error = error + d.toString()
  })
})

module.exports = {
  counts,
}
