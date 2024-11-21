const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();
const port = 3333;

app.use(express.static(path.join(__dirname)));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/api/status', (req, res) => {
    const dataDir = process.env.HOME + '/.digibyte';
    try {
        const debugLog = fs.readFileSync(path.join(dataDir, 'debug.log'), 'utf8');
        const blockHeight = debugLog.match(/height=(\d+)/);
        const connections = debugLog.match(/connections=(\d+)/);

        res.json({
            blocks: blockHeight ? blockHeight[1] : 'Loading...',
            connections: connections ? connections[1] : 'Loading...',
            verificationProgress: 'In Progress',
            dataDirectory: dataDir
        });
    } catch (error) {
        res.json({
            blocks: 'Loading...',
            connections: 'Loading...',
            verificationProgress: 0,
            dataDirectory: dataDir,
            error: error.message
        });
    }
});

app.listen(port, () => {
    console.log(`Dashboard running at http://localhost:${port}`);
});