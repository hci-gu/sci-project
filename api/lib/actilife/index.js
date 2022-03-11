const spawn = require('child_process').spawn
const fs = require('fs')
const path = require('path')

const counts = ({ type, minute, acc, f }) =>
  new Promise((resolve, reject) => {
    const tmpFile = `/tmp/accel_${type}_${minute}.json`
    console.log('writeFile', tmpFile)

    fs.writeFileSync(tmpFile, JSON.stringify(acc))
    const process = spawn('python3', [
      path.join(__dirname, 'counts.py'),
      tmpFile,
      `${f}`,
    ])
    let output = ''
    let error = ''
    process.stdout.on('data', (data) => {
      output = output + data.toString()
    })
    process.stdout.on('close', () => {
      fs.unlinkSync(tmpFile)
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
