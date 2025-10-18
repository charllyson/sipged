// functions/index.js
const functions = require("firebase-functions");
const inmetApp = require("./services/inmet/handler");

exports.proxyInmet = functions
    .region("us-central1")
    .https
    .onRequest(inmetApp);
