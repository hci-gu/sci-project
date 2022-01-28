const { MongoClient } = require('mongodb')
const COLLECTION = 'sensor-data'

let collection
let inited = false
const init = async () => {
  if (!inited) {
    const client = await MongoClient.connect(
      process.env.MONGO_URL || 'mongodb://localhost:27017',
      {}
    )
    const db = client.db(process.env.MONGO_DB || 'sci')
    try {
      await db.createCollection(COLLECTION)
    } catch (e) {}
    collection = db.collection(COLLECTION)
    inited = true
  }
}

const save = async (docs) => {
  await collection.insertMany(docs)
}

const get = async (query, { limit = 100000, offset = 0 }) => {
  const docs = await collection
    .find(query)
    .skip(offset * limit)
    .limit(limit)
    .toArray()
  return docs
}

module.exports = {
  init,
  save,
  get,
}
