const { onRequest } = require('firebase-functions/v2/https');
const cors = require('../config/cors');

const {
    listUgsForYear,
    findDerUg,
    getDotacoesConsolidadas,
    getDotacoesDetalhadas,
} = require('../services/al_transparencia_service');

exports.derDotacoesOrcamentarias = onRequest(
    { timeoutSeconds: 60, memory: '256MiB' },
    async (req, res) => {
        return cors(req, res, async () => {
            try {
                const apiKey = process.env.AL_TRANSPARENCIA_API_KEY;
                if (!apiKey) {
                    return res.status(500).json({
                        ok: false,
                        message: 'AL_TRANSPARENCIA_API_KEY não configurada no ambiente das Functions.',
                    });
                }

                const anoAtual = new Date().getFullYear();

                const anoInicial = parseInt(String(req.query.anoInicial ?? (anoAtual - 5)), 10);
                const anoFinal = parseInt(String(req.query.anoFinal ?? anoAtual), 10);

                if (!Number.isFinite(anoInicial) || !Number.isFinite(anoFinal)) {
                    return res.status(400).json({ ok: false, message: 'anoInicial/anoFinal inválidos.' });
                }
                if (anoFinal < anoInicial) {
                    return res.status(400).json({ ok: false, message: 'anoFinal < anoInicial.' });
                }

                const detalhado = String(req.query.detalhado ?? 'false').toLowerCase() === 'true';

                // Descobre UG do DER (pelo ano inicial)
                const ugs = await listUgsForYear({ year: anoInicial, apiKey });
                const der = findDerUg(ugs);

                if (!der?.id) {
                    return res.status(404).json({
                        ok: false,
                        message: 'UG do DER/AL não encontrada no Portal da Transparência.',
                    });
                }

                const items = [];

                for (let ano = anoInicial; ano <= anoFinal; ano++) {
                    const consolidado = await getDotacoesConsolidadas({
                        year: ano,
                        ugId: der.id,
                        apiKey,
                    });

                    let detalhadoPayload = null;
                    if (detalhado) {
                        detalhadoPayload = await getDotacoesDetalhadas({
                            year: ano,
                            ugId: der.id,
                            apiKey,
                            limit: 5000,
                            offset: 0,
                        });
                    }

                    items.push({
                        ano,
                        ugId: der.id,
                        ugDescricao: der.descricao,
                        consolidado,
                        detalhado: detalhadoPayload,
                    });
                }

                return res.status(200).json({
                    ok: true,
                    ug: { id: der.id, descricao: der.descricao },
                    items,
                });
            } catch (err) {
                console.error('[derDotacoesOrcamentarias] Erro:', err);
                return res.status(500).json({
                    ok: false,
                    message: err.message || String(err),
                });
            }
        });
    }
);
