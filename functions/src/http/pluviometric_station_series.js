// functions/src/http/pluviometric_station_series.js
const { onRequest } = require('firebase-functions/v2/https');
const cors = require('../config/cors');

const {
    getPluviometricHistoricSeries,
} = require('../services/ana_telemetric_service');

/**
 * Exemplo de chamada:
 *  /pluviometricStationSeries?codigoEstacao=01037030&anoInicial=1984&anoFinal=1984
 */
exports.pluviometricStationSeries = onRequest(async (req, res) => {
    return cors(req, res, async () => {
        try {
            const codigoEstacao = req.query.codigoEstacao;
            if (!codigoEstacao) {
                return res.status(400).json({
                    error: true,
                    message: 'Parâmetro "codigoEstacao" é obrigatório',
                });
            }

            const anoInicial = req.query.anoInicial || req.query.anoInicio;
            const anoFinal = req.query.anoFinal || req.query.anoFim;

            if (!anoInicial || !anoFinal) {
                return res.status(400).json({
                    error: true,
                    message: 'Parâmetros "anoInicial" e "anoFinal" são obrigatórios',
                });
            }

            const nivelConsistencia = req.query.nivelConsistencia || '2';

            const { items } = await getPluviometricHistoricSeries({
                codigoEstacao,
                anoInicio: anoInicial,
                anoFim: anoFinal,
                nivelConsistencia,
            });

            res.status(200).json(items || []);
        } catch (err) {
            console.error('[pluviometricStationSeries] Erro:', err);
            res.status(500).json({
                error: true,
                message: err.message || String(err),
            });
        }
    });
});
