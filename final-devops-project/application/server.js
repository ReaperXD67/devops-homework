const http = require('node:http');
const crypto = require('node:crypto');

function createServer() {
  let requests = 0;
  const started = Date.now();
  return http.createServer((req, res) => {
    requests += 1;
    const traceId = crypto.randomUUID();
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Trace-ID', traceId);
    res.setHeader('Content-Security-Policy', "default-src 'none'; style-src 'unsafe-inline'");
    const path = new URL(req.url, 'http://localhost').pathname;
    let status = 200;
    let type = 'application/json';
    let body;
    if (path === '/healthz' || path === '/readyz') {
      body = JSON.stringify({ status: 'ok' });
    } else if (path === '/api/info') {
      body = JSON.stringify({ application: 'DevOps homework', author: 'Aman Kumar', enrollment: '10275', version: process.env.APP_VERSION || '1.0.0' });
    } else if (path === '/metrics') {
      type = 'text/plain; version=0.0.4';
      const usage = process.cpuUsage();
      body = '# HELP app_requests_total HTTP requests received\n# TYPE app_requests_total counter\napp_requests_total ' + requests + '\n'
        + '# HELP process_resident_memory_bytes Resident memory\n# TYPE process_resident_memory_bytes gauge\nprocess_resident_memory_bytes ' + process.memoryUsage().rss + '\n'
        + '# HELP process_cpu_seconds_total Process CPU time\n# TYPE process_cpu_seconds_total counter\nprocess_cpu_seconds_total ' + (usage.user + usage.system) / 1e6 + '\n'
        + '# HELP app_uptime_seconds Uptime\n# TYPE app_uptime_seconds gauge\napp_uptime_seconds ' + (Date.now() - started) / 1000 + '\n';
    } else if (path === '/') {
      type = 'text/html; charset=utf-8';
      body = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>DevOps homework | Aman Kumar</title>'
        + '<style>body{background:#102329;color:#effaf7;font-family:system-ui;max-width:850px;margin:10vh auto;padding:32px}small{color:#8ae1bd}h1{font-size:56px;line-height:1.05}p{line-height:1.7}a{color:#8ae1bd}code{background:#213d45;padding:6px 10px}</style>'
        + '<small>SCALER / DEVOPS COURSE PROJECT</small><h1>From code to<br>observable service.</h1><p>Aman Kumar · Enrollment 10275</p>'
        + '<p>Application → GitHub Actions → Security gates → Container registry → Kubernetes → Helm → Monitoring → GitOps</p>'
        + '<p><a href="/healthz">Health</a> · <a href="/api/info">Application information</a> · <a href="/metrics">Prometheus metrics</a></p>'
        + '<p><code>Hello World from the final DevOps project</code></p></html>';
    } else {
      status = 404;
      body = JSON.stringify({ error: 'Not found' });
    }
    res.writeHead(status, { 'Content-Type': type });
    res.end(body);
    // Only controlled path and correlation ID are logged; query strings and secrets are excluded.
    console.log(JSON.stringify({ timestamp: new Date().toISOString(), traceId, method: req.method, path, status }));
  });
}

if (require.main === module) {
  const server = createServer();
  server.listen(Number(process.env.PORT || 8080), '0.0.0.0');
  for (const signal of ['SIGTERM', 'SIGINT']) process.on(signal, () => server.close());
}
module.exports = { createServer };
