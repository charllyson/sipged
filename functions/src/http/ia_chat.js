// functions/src/http/ia_chat.js
const functions = require('firebase-functions/v1');
const corsHandler = require('../config/cors');
const { askIa } = require('../services/ia_service');

const iaChat = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
        if (req.method !== 'POST') {
            res.status(405).send('Method Not Allowed');
            return;
        }

        try {
            const body = req.body || {};
            const message = body.message || '';

            if (!message) {
                res.status(400).json({ error: "Campo 'message' é obrigatório." });
                return;
            }

            const reply = await askIa(message);

            res.status(200).json({ reply });
        } catch (error) {
            console.error('Erro na função iaChat:', error?.response?.data || error);

            // Extrai info mais amigável
            const apiError = error?.response?.data?.error;
            const status = error?.response?.status || error?.status;
            const message =
            apiError?.message ||
            error?.message ||
            'Erro interno ao processar a IA.';

            res.status(500).json({
                error: message,
                status,
                raw: apiError || null,
            });
        }
    });
});

module.exports = { iaChat };
