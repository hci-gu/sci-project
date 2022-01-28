const express = require('express')
const fs = require('fs')
const cors = require('cors')
const app = express()
app.use(cors())
app.use(express.json({limit: '50mb'}));

app.post('/data', (req, res) => {
    // data_{date}.json
    const fileName = `data_${new Date().toISOString()}.json`
    fs.writeFile(fileName, JSON.stringify(req.body), (err) => {})
    const data = req.body
    console.log('data', data)
    res.sendStatus(200)
})

app.listen(3000, () => console.log('listening on port 3000'))
