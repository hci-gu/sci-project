const { MongoClient } = require('mongodb')
const COLLECTION = 'sensor-data'
const COLLECTION_HR = 'sensor-data-hr'
const COLLECTION_ACCEL = 'sensor-data-accel'

let db
let inited = false
const init = async () => {
  if (!inited) {
    const client = await MongoClient.connect(
      process.env.MONGO_URL || 'mongodb://localhost:27017',
      {}
    )
    db = client.db(process.env.MONGO_DB || 'sci')
    try {
      await db.createCollection(COLLECTION)
      await db.createCollection(COLLECTION_HR)
      await db.createCollection(COLLECTION_ACCEL)
    } catch (e) {}
    inited = true
  }
}

const save = async (collection, docs) => {
  await db.collection(collection).insertMany(docs)
}

const get = async (collection, query, { limit = 100000, offset = 0 }) => {
  const docs = await db
    .collection(collection)
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
