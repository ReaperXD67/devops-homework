const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { createServer } = require('../server');
let server;
let base;
before(async () => {
  server = createServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => new Promise(resolve => server.close(resolve)));
test('home page identifies the assignment', async () => {
  const response = await fetch(base);
  assert.equal(response.status, 200);
  assert.match(await response.text(), /Enrollment 10275/);
  assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
});
test('liveness and readiness are healthy', async () => {
  for (const route of ['/healthz', '/readyz']) {
    const response = await fetch(base + route);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { status: 'ok' });
  }
});
test('API returns version without configuration secrets', async () => {
  const info = await (await fetch(base + '/api/info')).json();
  assert.equal(info.enrollment, '10275');
  assert.equal(info.version, '1.0.0');
  assert.equal(Object.keys(info).length, 4);
});
test('metrics count requests and expose CPU and memory', async () => {
  const first = await (await fetch(base + '/metrics')).text();
  await fetch(base + '/healthz');
  const second = await (await fetch(base + '/metrics')).text();
  const count = text => Number(text.match(/^app_requests_total (\d+)$/m)[1]);
  assert.ok(count(second) > count(first));
  assert.match(second, /process_resident_memory_bytes \d+/);
  assert.match(second, /process_cpu_seconds_total [\d.]+/);
});
test('unknown paths return 404 with unique correlation IDs', async () => {
  const a = await fetch(base + '/missing');
  const b = await fetch(base + '/missing');
  assert.equal(a.status, 404);
  assert.deepEqual(await a.json(), { error: 'Not found' });
  assert.notEqual(a.headers.get('x-trace-id'), b.headers.get('x-trace-id'));
});
