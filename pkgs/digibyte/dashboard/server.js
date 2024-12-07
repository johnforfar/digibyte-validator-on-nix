// ./pkgs/digibyte/dashboard/server.js

const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const port = 3333;
const DIGIBYTE_DIR = path.join(process.env.HOME, '.digibyte');
const CONFIG_FILE = path.join(DIGIBYTE_DIR, 'digibyte.conf');
const LOCK_FILE = path.join(DIGIBYTE_DIR, 'dashboard.lock');
const CLI_BIN = path.join(process.env.HOME, '.nix-profile/bin/digibyte-cli');

function getNodeStatus() {
    return new Promise((resolve, reject) => {
        // Get blockchain info
        exec(`${CLI_BIN} -conf=${CONFIG_FILE} getblockchaininfo`, (error, stdout1, stderr1) => {
            if (error) {
                return reject(error);
            }
            
            // Get network info
            exec(`${CLI_BIN} -conf=${CONFIG_FILE} getnetworkinfo`, (error2, stdout2, stderr2) => {
                if (error2) {
                    return reject(error2);
                }

                try {
                    const blockchainInfo = JSON.parse(stdout1);
                    const networkInfo = JSON.parse(stdout2);

                    resolve({
                        blocks: blockchainInfo.blocks,
                        connections: networkInfo.connections,
                        verificationProgress: `${(blockchainInfo.verificationprogress * 100).toFixed(2)}%`,
                        dataDirectory: DIGIBYTE_DIR,
                        networkVersion: networkInfo.version,
                        subVersion: networkInfo.subversion
                    });
                } catch (e) {
                    reject(e);
                }
            });
        });
    });
}

const server = http.createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

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
        try {
            const status = await getNodeStatus();
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(status));
        } catch (error) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                blocks: 'Error',
                connections: 'Error',
                verificationProgress: 'Error',
                dataDirectory: DIGIBYTE_DIR,
                error: error.message
            }));
        }
    } else {
        res.writeHead(404);
        res.end('Not found');
    }
});

// Handle cleanup
process.on('SIGINT', () => {
    console.log('Shutting down...');
    process.exit(0);
});

console.log('Starting dashboard server...');
server.listen(port, (err) => {
    if (err) {
        console.error('Error starting server:', err);
        process.exit(1);
    }
    console.log('==============================================');
    console.log(`Dashboard running at http://localhost:${port}`);
    console.log(`Data directory: ${DIGIBYTE_DIR}`);
    console.log('==============================================');
});