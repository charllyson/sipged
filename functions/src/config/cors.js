// functions/src/config/cors.js
const cors = require('cors');

const corsHandler = cors({
    origin: true, // depois você pode restringir para o domínio do SIGED
});

module.exports = corsHandler;
