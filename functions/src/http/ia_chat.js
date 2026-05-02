// functions/src/http/ia_chat.js

const { onRequest } = require('firebase-functions/v2/https');
const corsHandler = require('../config/cors');
const { askIa } = require('../services/ia_service');

const iaChat = onRequest(
    {
        region: 'southamerica-east1',
        timeoutSeconds: 60,
        memory: '256MiB',
    },
    async (req, res) => {
        return corsHandler(req, res, async () => {
            if (req.method !== 'POST') {
                return res.status(405).json({
                    ok: false,
                    message: 'Method Not Allowed',
                });
            }

            try {
                const body = req.body || {};
                const message = String(body.message || '').trim();

                if (!message) {
                    return res.status(400).json({
                        ok: false,
                        message: "Campo 'message' é obrigatório.",
                    });
                }

                const reply = await askIa(message);

                return res.status(200).json({
                    ok: true,
                    reply,
                });
            } catch (error) {
                console.error(
                    '[iaChat] Erro:',
                    error?.response?.data || error,
                );

                const apiError = error?.response?.data?.error;
                const status = error?.response?.status || error?.status;

                const message =
                apiError?.message ||
                error?.message ||
                'Erro interno ao processar a IA.';

                return res.status(500).json({
                    ok: false,
                    message,
                    status,
                    raw: apiError || null,
                });
            }
        });
    },
);

module.exports = { iaChat };