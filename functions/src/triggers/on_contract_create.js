// functions/src/triggers/on_contract_create.js
const functions = require('firebase-functions/v1');
const admin = require('../config/firebase'); // se estiver usando esse

const onContractCreate = functions.firestore
    .document('contracts/{contractId}')
    .onCreate(async (snap, context) => {
    // sua lógica aqui
});

module.exports = { onContractCreate };
