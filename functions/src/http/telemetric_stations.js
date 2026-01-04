// functions/src/http/telemetric_stations.js
const { onRequest } = require('firebase-functions/v2/https');
const cors = require('../config/cors');

const {
    getTelemetricStationsByUf,
    getPluviometricStationsByUf,
    getFluviometricStationsByUf,
} = require('../services/ana_telemetric_service');

// -----------------------------------------------------------------------------
// GENÉRICO: ?uf=AL&tipoEstacao=PLUVIOMETRICA/FLUVIOMETRICA
// -----------------------------------------------------------------------------
exports.telemetricStations = onRequest(async (req, res) => {
    return cors(req, res, async () => {
        try {
            const uf = (req.query.uf || 'AL').toString().toUpperCase();
            const tipoEstacao = req.query.tipoEstacao
                ? req.query.tipoEstacao.toString()
                : null;

            const result = await getTelemetricStationsByUf(uf, tipoEstacao);

            res.status(200).json(result.items || []);
        } catch (err) {
            console.error('[telemetricStations] Erro:', err);
            res.status(500).json({
                error: true,
                message: err.message || String(err),
            });
        }
    });
});

// -----------------------------------------------------------------------------
// APENAS PLUVIOMÉTRICAS TELEMÉTRICAS
// -----------------------------------------------------------------------------
exports.telemetricPluviometricStations = onRequest(async (req, res) => {
    return cors(req, res, async () => {
        try {
            const uf = (req.query.uf || 'AL').toString().toUpperCase();

            const result = await getPluviometricStationsByUf(uf);

            res.status(200).json(result.items || []);
        } catch (err) {
            console.error('[telemetricPluviometricStations] Erro:', err);
            res.status(500).json({
                error: true,
                message: err.message || String(err),
            });
        }
    });
});

// -----------------------------------------------------------------------------
// APENAS FLUVIOMÉTRICAS TELEMÉTRICAS
// -----------------------------------------------------------------------------
exports.telemetricFluviometricStations = onRequest(async (req, res) => {
    return cors(req, res, async () => {
        try {
            const uf = (req.query.uf || 'AL').toString().toUpperCase();

            const result = await getFluviometricStationsByUf(uf);

            res.status(200).json(result.items || []);
        } catch (err) {
            console.error('[telemetricFluviometricStations] Erro:', err);
            res.status(500).json({
                error: true,
                message: err.message || String(err),
            });
        }
    });
});
