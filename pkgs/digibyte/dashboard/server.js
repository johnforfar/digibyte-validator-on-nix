const http = require('http');
const fs = require('fs');
const path = require('path');

const port = 3333;

const server = http.createServer((req, res) => {
    if (req.url === '/') {
        fs.readFile(path.join(__dirname, 'index.html'), (err, content) => {
            if (err) {
                res.writeHead(500);
                res.end('Error loading dashboard');
                return;
            }
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(content);
        });
    } else if (req.url === '/api/status') {
        const dataDir = process.env.HOME + '/.digibyte';
        try {
            const debugLog = fs.readFileSync(path.join(dataDir, 'debug.log'), 'utf8');
            const blockHeight = debugLog.match(/height=(\d+)/);
            const connections = debugLog.match(/connections=(\d+)/);

            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                blocks: blockHeight ? blockHeight[1] : 'Loading...',
                connections: connections ? connections[1] : 'Loading...',
                verificationProgress: 'In Progress',
                dataDirectory: dataDir
            }));
        } catch (error) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                blocks: 'Loading...',
                connections: 'Loading...',
                verificationProgress: '0%',
                error: error.message
            }));
        }
    } else {
        res.writeHead(404);
        res.end('Not found');
    }
});

server.listen(port, () => {
    console.log(`Dashboard running at http://localhost:${port}`);
});