const request = require('supertest');
const app = require('../server'); // Adjust path if necessary

describe('GET /', () => {
  it('should return Hello World', (done) => {
    request(app)
      .get('/')
      .expect(200)
      .expect((res) => {
        if (res.body.message !== 'Hello World!') throw new Error("Response does not match");
      })
      .end(done);
  });
});
