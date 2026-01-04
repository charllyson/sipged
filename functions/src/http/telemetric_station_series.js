// functions/src/http/telemetric_station_series.js
const { onRequest } = require('firebase-functions/v2/https');
const cors = require('../config/cors');

const {
    getStationSeries,
} = require('../services/ana_telemetric_service');

/**
 * Cloud Function HTTP para obter a série histórica de uma estação.
 *
 * Exemplo:
 *   /telemetricStationSeries?codigoEstacao=15400000&tipoEstacao=PLUVIOMETRICA&daysBack=7
 */
exports.telemetricStationSeries = onRequest(async (req, res) => {
    return cors(req, res, async () => {
        try {
            const codigoEstacao = req.query.codigoEstacao;
            if (!codigoEstacao) {
                return res.status(400).json({
                    error: true,
                    message: 'Parâmetro "codigoEstacao" é obrigatório',
                });
            }

            const tipoEstacao = (req.query.tipoEstacao || 'PLUVIOMETRICA').toString();

            const rawDaysBack = parseInt(req.query.daysBack || '7', 10);
            const daysBack = Number.isFinite(rawDaysBack) ? rawDaysBack : 7;

            const result = await getStationSeries({
                codigoEstacao,
                tipoEstacao,
                daysBack,
            });

            // Se o service tratou 400 internamente, ele retorna { items: [] }
            res.status(200).json(result.items || []);
        } catch (err) {
            console.error('[telemetricStationSeries] Erro:', err);
            res.status(500).json({
                error: true,
                message: err.message || String(err),
            });
        }
    });
});
