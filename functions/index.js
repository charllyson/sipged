// functions/index.js
const { iaChat } = require('./src/http/ia_chat');
const { healthCheck } = require('./src/http/health_check');
const { onContractCreate } = require('./src/triggers/on_contract_create');

const {
    telemetricStations,
    telemetricPluviometricStations,
    telemetricFluviometricStations,
} = require('./src/http/telemetric_stations');

const {
    telemetricStationSeries,
} = require('./src/http/telemetric_station_series');

const {
    pluviometricStationSeries,
} = require('./src/http/pluviometric_station_series');
const { derDotacoesOrcamentarias } = require('./src/http/al_der_dotacoes');

exports.derDotacoesOrcamentarias = derDotacoesOrcamentarias;

exports.iaChat = iaChat;
exports.healthCheck = healthCheck;
exports.onContractCreate = onContractCreate;

exports.telemetricStations = telemetricStations;
exports.telemetricPluviometricStations = telemetricPluviometricStations;
exports.telemetricFluviometricStations = telemetricFluviometricStations;
exports.telemetricStationSeries = telemetricStationSeries;
exports.pluviometricStationSeries = pluviometricStationSeries;
