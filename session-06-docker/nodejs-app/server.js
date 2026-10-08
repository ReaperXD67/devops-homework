const http = require('node:http');
http.createServer((_req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end('<h1>Hello World from Node.js</h1><p>Aman Kumar | 10275</p>');
}).listen(8080, '0.0.0.0');
