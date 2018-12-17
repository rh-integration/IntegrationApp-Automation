const test = require('tape');
const supertest = require('supertest');

const app = require('../app');

test('test out greeting route with no query param', t => {
  supertest(app)
    .get('/')
    .expect('Content-Type', /json/)
    .expect(200)
    .then(response => {
      t.equal(response.body.content, 'Hello, World!');
      t.end();
    });
});

test('test out greeting route with a query param', t => {
  supertest(app)
    .get('/')
    .expect('Content-Type', /json/)
    .expect(200)
    .then(response => {
      t.equal(response.body.content, 'Hello, Luke');
      t.end();
    });
});
