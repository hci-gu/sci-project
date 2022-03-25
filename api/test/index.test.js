const db = require('../lib/db')
const createServer = require('../lib/server')
const supertest = require('supertest')

const app = createServer()

beforeEach(async () => {
  await db()
})

test('GET /ping', () => supertest(app).get('/ping').expect(200))

describe('/users', () => {
  test('POST /users', async () => {
    const body = {
      weight: 100,
    }

    const response = await supertest(app).post('/users').send(body).expect(200)

    expect(response.body.id).toBeTruthy()
    expect(response.body.weight).toBe(100)
  })

  describe('GET /users/:id', () => {
    let userId

    beforeEach(async () => {
      response = await supertest(app).post('/users').send({}).expect(200)
      userId = response.body.id
    })

    test('returns 404 for missing user', async () => {
      const id = 'not-a-real-id'

      await supertest(app).get(`/users/${id}`).expect(404)
    })

    test('returns user', async () => {
      const response = await supertest(app).get(`/users/${userId}`).expect(200)

      expect(response.body.id).toBe(userId)
    })
  })

  describe('/users/data', () => {
    let userId

    beforeEach(async () => {
      response = await supertest(app).post('/users').send({}).expect(200)
      userId = response.body.id
    })

    test('GET /users/:id/data/:type empty', async () => {
      const response = await supertest(app)
        .get(`/users/${userId}/data/accel`)
        .query({
          from: '2021-01-01T00:00:00.000Z',
          to: '2022-01-01T00:00:00.000Z',
        })
        .expect(200)

      expect(response.body.length).toBe(0)
    })

    test('POST /users/:id/data', async () => {
      const body = require('./data/fitbit.accel.json')

      await supertest(app).post(`/users/${userId}/data`).send(body).expect(200)
    })

    test('GET /users/:id/data/:type with data', async () => {
      const body = require('./data/fitbit.accel.json')

      await supertest(app).post(`/users/${userId}/data`).send(body).expect(200)

      const response = await supertest(app)
        .get(`/users/${userId}/data/accel`)
        .query({
          from: '2022-01-01T00:00:00.000Z',
          to: '2023-01-01T00:00:00.000Z',
        })
        .expect(200)

      expect(response.body.length).toBe(90)
    })

    // cant group in sqlite
    xtest('GET /users/:id/data/:type grouped', async () => {
      const body = require('./data/fitbit.accel.json')

      await supertest(app).post(`/users/${userId}/data`).send(body).expect(200)

      const response = await supertest(app)
        .get(`/users/${userId}/data/accel`)
        .query({
          from: '2022-01-01T00:00:00.000Z',
          to: '2023-01-01T00:00:00.000Z',
          group: 'minute',
        })
        .expect(200)

      expect(response.body.length).toBe(60)
    })
  })

  describe('/GET /users/:id/energy', () => {
    let userId

    beforeEach(async () => {
      response = await supertest(app).post('/users').send({}).expect(200)
      userId = response.body.id
    })

    test('GET /users/:id/energy', async () => {
      await supertest(app).get(`/users/${userId}/energy`).expect(200)
    })
  })
})
