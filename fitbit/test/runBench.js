import { spawn } from 'child_process'
import fs from 'fs'

const runTest = (testFile) => {
  return new Promise((resolve, reject) => {
    fs.writeFileSync('./test/tmpRunner.js', testFile, 'utf8')

    const test = spawn('./test/bin/jerry', ['./test/tmpRunner.js'], {
      stdio: 'inherit',
    })

    test.on('exit', () => {
      fs.unlinkSync('./test/tmpRunner.js')
      resolve()
    })
  })
}

const run = async () => {
  const accData = fs.readFileSync('./test/accData.js', 'utf8')
  const counts = fs.readFileSync('./app/counts.js', 'utf8')
  const counts_base = fs.readFileSync('./app/counts_base.js', 'utf8')
  const bench = fs.readFileSync('./test/bench.js', 'utf8')

  const testFile = `
    ${accData.replace('export default', 'const accData =')}
    ${counts.replace('export default', 'const calculateCounts =')}
    ${bench}
  `
  const testFile_base = `
    ${accData.replace('export default', 'const accData =')}
    ${counts_base.replace('export default', 'const calculateCounts =')}
    ${bench.replace(
      'calculateCounts(accX, accY, accZ)',
      'calculateCounts(accData)'
    )}
  `
  console.log('BASELINE')
  await runTest(testFile_base)
  console.log('UPDATED')
  await runTest(testFile)
}

run()
