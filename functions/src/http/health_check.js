// functions/src/http/health_check.js
const functions = require('firebase-functions/v1');
const corsHandler = require('../config/cors');

const healthCheck = functions.https.onRequest((req, res) => {
    corsHandler(req, res, () => {
        res.status(200).json({
            status: 'ok',
            message: 'SIPGED Functions ativas 🚀',
            timestamp: new Date().toISOString(),
        });
    });
});

module.exports = { healthCheck };
