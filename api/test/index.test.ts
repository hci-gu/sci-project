import db from '../lib/db'
import createServer from '../lib/server'
import request from 'supertest'

const app = createServer()

beforeEach(async () => {
  await db()
})

test('GET /ping', () => request(app).get('/ping').expect(200))

describe('/users', () => {
  test('POST /users', async () => {
    const body = {
      weight: 100,
    }

    const response = await request(app).post('/users').send(body).expect(200)

    expect(response.body.id).toBeTruthy()
    expect(response.body.weight).toBe(100)
  })

  test('POST /users alternates testType A/B', async () => {
    const first = await request(app).post('/users').send({}).expect(200)
    const second = await request(app).post('/users').send({}).expect(200)

    expect(first.body.testType).toBe('A')
    expect(second.body.testType).toBe('B')
  })

  test('POST/PATCH /users supports features and injuryDate', async () => {
    const created = await request(app)
      .post('/users')
      .send({
        features: { 'pain-smell-reminders': true, 'uti-reminders': false },
        injuryDate: '2024-01-15',
      })
      .expect(200)

    expect(created.body.features).toEqual({
      'pain-smell-reminders': true,
      'uti-reminders': false,
    })
    expect(created.body.injuryDate).toBe('2024-01-15')

    const updated = await request(app)
      .patch(`/users/${created.body.id}`)
      .send({
        features: { 'pain-smell-reminders': false, 'uti-reminders': true },
        injuryDate: '2024-02-01',
      })
      .expect(200)

    expect(updated.body.features).toEqual({
      'pain-smell-reminders': false,
      'uti-reminders': true,
    })
    expect(updated.body.injuryDate).toBe('2024-02-01')
  })

  describe('GET /users/:id', () => {
    let userId: string

    beforeEach(async () => {
      const response = await request(app).post('/users').send({}).expect(200)
      userId = response.body.id
    })

    test('returns 404 for missing user', async () => {
      const id = 'not-a-real-id'

      await request(app).get(`/users/${id}`).expect(404)
    })

    test('returns user', async () => {
      const response = await request(app).get(`/users/${userId}`).expect(200)

      expect(response.body.id).toBe(userId)
    })
  })

  describe('/users/data', () => {
    let userId: string

    beforeEach(async () => {
      const response = await request(app).post('/users').send({}).expect(200)
      userId = response.body.id
    })

    test('GET /users/:id/data/:type empty', async () => {
      const response = await request(app)
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

      await request(app).post(`/users/${userId}/data`).send(body).expect(200)
    })

    test('GET /users/:id/data/:type with data', async () => {
      const body = require('./data/fitbit.accel.json')

      await request(app).post(`/users/${userId}/data`).send(body).expect(200)

      const response = await request(app)
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

      await request(app).post(`/users/${userId}/data`).send(body).expect(200)

      const response = await request(app)
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
    let userId: string

    beforeEach(async () => {
      const response = await request(app).post('/users').send({}).expect(200)
      userId = response.body.id
      expect(userId).toBeDefined()
    })

    test('GET /users/:id/energy', async () => {
      await request(app).get(`/energy/${userId}`).expect(200)
    })
  })
})
