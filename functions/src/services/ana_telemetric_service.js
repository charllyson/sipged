// functions/src/services/ana_telemetric_service.js
const fetch = require('node-fetch');

const ANA_BASE_URL =
'https://www.ana.gov.br/hidrowebservice/EstacoesTelemetricas';

// -----------------------------------------------------------------------------
// ENDPOINTS OFICIAIS
// -----------------------------------------------------------------------------
const ANA_AUTH_URL = `${ANA_BASE_URL}/OAUth/v1`;
const ANA_INVENTORY_URL = `${ANA_BASE_URL}/HidroInventarioEstacoes/v1`;

// Séries telemétricas adotadas (chuva/cota/vazão em “quase tempo real”)
const ANA_SERIE_TELEM_ADOTADA_URL =
`${ANA_BASE_URL}/HidroinfoanaSerieTelemetricaAdotada/v1`;

// Séries de vazão (estações convencionais fluviométricas)
const ANA_SERIE_VAZAO_URL =
`${ANA_BASE_URL}/HidroSerieVazao/v1`;

// Séries de chuva históricas (estações convencionais)
const ANA_SERIE_CHUVA_HIST_URL =
`${ANA_BASE_URL}/HidroSerieChuva/v1`;

// -----------------------------------------------------------------------------
// CREDENCIAIS (.env da pasta functions)
// -----------------------------------------------------------------------------
const ANA_IDENTIFICADOR = process.env.ANA_IDENTIFICADOR;
const ANA_SENHA = process.env.ANA_SENHA;

// -----------------------------------------------------------------------------
// CACHES SIMPLES EM MEMÓRIA
// -----------------------------------------------------------------------------
let tokenCache = {
    value: null,
    expiresAt: 0,
};

const inventoryCache = {
    // uf: { items, fetchedAt }
};

const seriesCache = {
    // key: { items, fetchedAt }
};

const TOKEN_TTL_MS = 10 * 60 * 1000;     // 10 min
const INVENTORY_TTL_MS = 10 * 60 * 1000; // 10 min
const SERIES_TTL_MS = 5 * 60 * 1000;     // 5 min

// -----------------------------------------------------------------------------
// TOKEN OAUTH – /EstacoesTelemetricas/OAUth/v1
// -----------------------------------------------------------------------------
async function getAnaOAuthToken() {
    if (!ANA_IDENTIFICADOR || !ANA_SENHA) {
        throw new Error(
            'Credenciais ANA não configuradas (ANA_IDENTIFICADOR / ANA_SENHA).'
        );
    }

    if (tokenCache.value && Date.now() < tokenCache.expiresAt) {
        return tokenCache.value;
    }

    const resp = await fetch(ANA_AUTH_URL, {
        method: 'GET',
        headers: {
            Identificador: ANA_IDENTIFICADOR,
            Senha: ANA_SENHA,
            Accept: 'application/json',
        },
    });

    if (!resp.ok) {
        throw new Error(
            `Erro ao obter token da ANA: ${resp.status} - ${await resp.text()}`
        );
    }

    const json = await resp.json();
    const token = json.items?.tokenautenticacao;

    if (!token) {
        throw new Error(`Token inválido retornado pela ANA: ${JSON.stringify(json)}`);
    }

    tokenCache = {
        value: token,
        expiresAt: Date.now() + TOKEN_TTL_MS,
    };

    return token;
}

// -----------------------------------------------------------------------------
// CHAMADA GENÉRICA AOS ENDPOINTS DA ANA
// -----------------------------------------------------------------------------
async function fetchFromAna(url) {
    const token = await getAnaOAuthToken();

    const resp = await fetch(url, {
        method: 'GET',
        headers: {
            Authorization: `Bearer ${token}`,
            Accept: 'application/json',
        },
    });

    if (!resp.ok) {
        const text = await resp.text();
        throw new Error(
            `Erro ANA em ${url}: ${resp.status} - ${text}`
        );
    }

    const data = await resp.json();
    const items = Array.isArray(data.items)
        ? data.items
        : data.items
        ? [data.items]
        : [];

    return { raw: data, items };
}

// -----------------------------------------------------------------------------
// INVENTÁRIO – /HidroInventarioEstacoes/v1
// -----------------------------------------------------------------------------
async function getInventoryByUf(uf = 'AL') {
    const ufUpper = uf.toString().toUpperCase();

    const cached = inventoryCache[ufUpper];
    if (cached && Date.now() - cached.fetchedAt < INVENTORY_TTL_MS) {
        return cached.items;
    }

    const params = new URLSearchParams();
    // Nome do parâmetro exatamente como aparece no Swagger:
    // "Unidade Federativa"
    params.append('Unidade Federativa', ufUpper);

    const url = `${ANA_INVENTORY_URL}?${params.toString()}`;
    const { items } = await fetchFromAna(url);

    inventoryCache[ufUpper] = {
        items,
        fetchedAt: Date.now(),
    };

    return items;
}

// -----------------------------------------------------------------------------
// ESTAÇÕES TELEMÉTRICAS POR UF + FILTRO TIPO
// -----------------------------------------------------------------------------
async function getTelemetricStationsByUf(uf = 'AL', tipoEstacao = null) {
    const items = await getInventoryByUf(uf);

    const filteredTelemetric = items.filter((it) => {
        const teleStart = it.Data_Periodo_Telemetrica_Inicio;
        return teleStart !== null && teleStart !== undefined && `${teleStart}`.trim() !== '';
    });

    if (!tipoEstacao) {
        return { items: filteredTelemetric };
    }

    const tipoUpper = tipoEstacao.toString().toUpperCase();

    const filtered = filteredTelemetric.filter((it) => {
        const tipo = (it.Tipo_Estacao || '').toString().toUpperCase();
        if (tipoUpper.startsWith('PLUVI')) return tipo.includes('PLUVIOMETR');
        if (tipoUpper.startsWith('FLUVI')) return tipo.includes('FLUVIOMETR');
        return true;
    });

    return { items: filtered };
}

async function getPluviometricStationsByUf(uf = 'AL') {
    return getTelemetricStationsByUf(uf, 'PLUVIOMETRICA');
}

async function getFluviometricStationsByUf(uf = 'AL') {
    return getTelemetricStationsByUf(uf, 'FLUVIOMETRICA');
}

// -----------------------------------------------------------------------------
// HELPERS – DATA E RANGE
// -----------------------------------------------------------------------------
function formatDateYMD(date) {
    const d = date instanceof Date ? date : new Date(date);
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
}

/**
 * RangeIntervaloDeBusca – valores possíveis conforme manual:
 * MINUTO_5, MINUTO_10, ..., HORA_1, ..., DIAS_2, DIAS_7, DIAS_14, DIAS_21, DIAS_30
 */
function mapDaysBackToRange(daysBack = 7) {
    const n = Math.max(1, Number.isFinite(daysBack) ? Number(daysBack) : 7);

    if (n <= 2) return 'DIAS_2';
    if (n <= 7) return 'DIAS_7';
    if (n <= 14) return 'DIAS_14';
    if (n <= 21) return 'DIAS_21';
    return 'DIAS_30';
}

// -----------------------------------------------------------------------------
// SÉRIE TELEMÉTRICA ADOTADA (chuva / cota / vazão) – quase tempo real
// -----------------------------------------------------------------------------
async function getPluviometricSeries(codigoEstacao, daysBack = 7) {
    if (!codigoEstacao) {
        throw new Error('codigoEstacao é obrigatório');
    }

    const safeDaysBackRaw = Number.isFinite(daysBack) ? Number(daysBack) : 7;
    const safeDaysBack = Math.min(Math.max(safeDaysBackRaw, 1), 30);
    const range = mapDaysBackToRange(safeDaysBack);

    const key = `PLUVIOM_TELEM_ADOTADA_${codigoEstacao}_${range}`;
    const cached = seriesCache[key];
    if (cached && Date.now() - cached.fetchedAt < SERIES_TTL_MS) {
        return { items: cached.items };
    }

    const params = new URLSearchParams();
    params.append('CodigoDaEstacao', String(codigoEstacao));
    params.append('TipoFiltroData', 'DATA_LEITURA');
    params.append('RangeIntervaloDeBusca', range);

    const url = `${ANA_SERIE_TELEM_ADOTADA_URL}?${params.toString()}`;
    console.log('[DEBUG URL SERIE TELEM ADOTADA] =>', url);

    try {
        const { items } = await fetchFromAna(url);

        seriesCache[key] = {
            items,
            fetchedAt: Date.now(),
        };

        return { items };
    } catch (err) {
        const msg = String(err || '');
        if (msg.includes(' 400 -')) {
            console.warn('[getPluviometricSeries] 400 da ANA, retornando lista vazia:', msg);
            const items = [];
            seriesCache[key] = { items, fetchedAt: Date.now() };
            return { items };
        }
        throw err;
    }
}

// -----------------------------------------------------------------------------
// SÉRIE DE VAZÃO (estações convencionais fluviométricas)
// -----------------------------------------------------------------------------
function buildDateRangeParams(daysBack = 30) {
    const now = new Date();

    const safeDaysBackRaw = Number.isFinite(daysBack) ? Number(daysBack) : 30;
    const safeDaysBack = Math.min(Math.max(safeDaysBackRaw, 1), 365);

    const end = now;
    const start = new Date(
        now.getTime() - (safeDaysBack - 1) * 24 * 60 * 60 * 1000
    );

    const fmt = (d) => formatDateYMD(d);

    return {
        dataInicial: fmt(start),
        dataFinal: fmt(end),
        horarioInicial: '00:00:00',
        horarioFinal: '23:59:59',
    };
}

async function getFluviometricSeries(codigoEstacao, daysBack = 30) {
    if (!codigoEstacao) {
        throw new Error('codigoEstacao é obrigatório');
    }

    const safeDaysBackRaw = Number.isFinite(daysBack) ? Number(daysBack) : 30;
    const safeDaysBack = Math.min(Math.max(safeDaysBackRaw, 1), 365);

    const key = `FLUVIOM_${codigoEstacao}_${safeDaysBack}`;
    const cached = seriesCache[key];
    if (cached && Date.now() - cached.fetchedAt < SERIES_TTL_MS) {
        return { items: cached.items };
    }

    const {
        dataInicial,
        dataFinal,
        horarioInicial,
        horarioFinal,
    } = buildDateRangeParams(safeDaysBack);

    const params = new URLSearchParams();
    params.append('CodigoEstacao', String(codigoEstacao));
    params.append('TipoFiltroData', 'DATA_LEITURA');
    params.append('DataInicial', dataInicial);
    params.append('DataFinal', dataFinal);
    params.append('HorarioInicial', horarioInicial);
    params.append('HorarioFinal', horarioFinal);

    const url = `${ANA_SERIE_VAZAO_URL}?${params.toString()}`;
    console.log('[DEBUG URL SERIE FLUVIOM] =>', url);

    try {
        const { items } = await fetchFromAna(url);

        seriesCache[key] = {
            items,
            fetchedAt: Date.now(),
        };

        return { items };
    } catch (err) {
        const msg = String(err || '');
        if (msg.includes(' 400 -')) {
            console.warn('[getFluviometricSeries] 400 da ANA, retornando lista vazia:', msg);
            const items = [];
            seriesCache[key] = { items, fetchedAt: Date.now() };
            return { items };
        }
        throw err;
    }
}

// -----------------------------------------------------------------------------
// SÉRIE PLUVIOMÉTRICA HISTÓRICA – HIDROSerieChuva/v1
// Busca ANO A ANO, respeitando o limite de 366 dias por chamada
// -----------------------------------------------------------------------------
async function getPluviometricHistoricSeries({
    codigoEstacao,
    dataInicial,
    dataFinal,
}) {
    if (!codigoEstacao) {
        throw new Error('codigoEstacao é obrigatório');
    }
    if (!dataInicial || !dataFinal) {
        throw new Error('dataInicial e dataFinal são obrigatórios (yyyy-MM-dd)');
    }

    const key = `PLUVIOM_HIST_${codigoEstacao}_${dataInicial}_${dataFinal}`;
    const cached = seriesCache[key];
    if (cached && Date.now() - cached.fetchedAt < SERIES_TTL_MS) {
        return { items: cached.items };
    }

    const start = new Date(`${dataInicial}T00:00:00`);
    const end = new Date(`${dataFinal}T00:00:00`);

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        throw new Error(`Datas inválidas: dataInicial=${dataInicial}, dataFinal=${dataFinal}`);
    }
    if (start > end) {
        throw new Error('dataInicial não pode ser maior que dataFinal');
    }

    const allItems = [];
    const startYear = start.getFullYear();
    const endYear = end.getFullYear();

    for (let year = startYear; year <= endYear; year++) {
        let segStart = new Date(year, 0, 1);
        let segEnd = new Date(year, 11, 31);

        if (year === startYear && segStart < start) {
            segStart = new Date(start.getTime());
        }
        if (year === endYear && segEnd > end) {
            segEnd = new Date(end.getTime());
        }

        if (segStart > segEnd) continue;

        const segDataInicial = formatDateYMD(segStart);
        const segDataFinal = formatDateYMD(segEnd);

        const params = new URLSearchParams();
        params.append('Código da Estação', String(codigoEstacao));
        params.append('Tipo Filtro Data', 'DATA_LEITURA');
        params.append('Data Inicial (yyyy-MM-dd)', segDataInicial);
        params.append('Data Final (yyyy-MM-dd)', segDataFinal);

        const url = `${ANA_SERIE_CHUVA_HIST_URL}?${params.toString()}`;
        console.log(`[DEBUG HIDRO SERIE CHUVA ano ${year}] => ${url}`);

        try {
            const { items } = await fetchFromAna(url);
            if (Array.isArray(items) && items.length > 0) {
                console.log(
                    `[getPluviometricHistoricSeries] Ano ${year} retornou ${items.length} item(s)`
                );
                allItems.push(...items);
            } else {
                console.log(
                    `[getPluviometricHistoricSeries] Ano ${year} sem dados`
                );
            }
        } catch (err) {
            const msg = String(err || '');
            console.warn(
                `[getPluviometricHistoricSeries] Erro no ano ${year}:`,
                msg
            );
            // se quiser abortar geral, pode trocar por: throw err;
        }
    }

    allItems.sort((a, b) => {
        const da = a['Data_Hora_Dado'];
        const db = b['Data_Hora_Dado'];
        if (!da && !db) return 0;
        if (!da) return 1;
        if (!db) return -1;
        try {
            const d1 = new Date(da);
            const d2 = new Date(db);
            return d1 - d2;
        } catch {
            return String(da).localeCompare(String(db));
        }
    });

    seriesCache[key] = {
        items: allItems,
        fetchedAt: Date.now(),
    };

    return { items: allItems };
}

// -----------------------------------------------------------------------------
// HELPER: extrair valor de chuva (mm) de um item da HIDROSerieChuva
// (ajuste se você ver outro nome de campo no JSON real)
// -----------------------------------------------------------------------------
function extractRainValue(item) {
    if (!item || typeof item !== 'object') return 0;

    const candidates = [
        'Chuva',
        'Chuva_mm',
        'PRECIPITACAO',
        'Precipitacao',
        'Precipitação',
        'Valor',
    ];

    for (const key of candidates) {
        if (Object.prototype.hasOwnProperty.call(item, key)) {
            const v = item[key];
            if (v == null) continue;
            const num = typeof v === 'number' ? v : parseFloat(String(v).replace(',', '.'));
            if (!Number.isNaN(num)) return num;
        }
    }

    return 0;
}

// -----------------------------------------------------------------------------
// TOTAIS PLUVIOMÉTRICOS POR ESTAÇÃO EM UM PERÍODO (UF)
// Retorna: { "01037030": 1234.5, ... }
// -----------------------------------------------------------------------------
async function getPluviometricTotalsForPeriod({
    uf = 'AL',
    dataInicial,
    dataFinal,
}) {
    if (!dataInicial || !dataFinal) {
        throw new Error('dataInicial e dataFinal são obrigatórios (yyyy-MM-dd)');
    }

    const ufUpper = uf.toString().toUpperCase();
    const key = `PLUVIOM_TOTALS_${ufUpper}_${dataInicial}_${dataFinal}`;
    const cached = seriesCache[key];
    if (cached && Date.now() - cached.fetchedAt < SERIES_TTL_MS) {
        return { totalsByStation: cached.items };
    }

    const { items: stations } = await getPluviometricStationsByUf(ufUpper);

    const totals = {};

    for (const st of stations || []) {
        const codigo =
        st.codigoestacao ||
        st.CodigoEstacao ||
        st.CodigoEstacaoTelemetrica ||
        st['Código da Estação'] ||
        st['CodigoEstacao'];

        if (!codigo) continue;

        try {
            const { items } = await getPluviometricHistoricSeries({
                codigoEstacao: codigo,
                dataInicial,
                dataFinal,
            });

            let sum = 0;
            for (const it of items || []) {
                sum += extractRainValue(it);
            }

            totals[String(codigo)] = sum;
        } catch (err) {
            console.warn(
                '[getPluviometricTotalsForPeriod] Erro ao somar estação',
                codigo,
                String(err || '')
            );
        }
    }

    seriesCache[key] = {
        items: totals,
        fetchedAt: Date.now(),
    };

    return { totalsByStation: totals };
}

// -----------------------------------------------------------------------------
// DATAS DISPONÍVEIS POR UF (PLUVIOMÉTRICAS)
// Retorna array de 'yyyy-MM-dd' com dias que possuem algum registro em QUALQUER
// estação da UF.
// -----------------------------------------------------------------------------
async function getPluviometricAvailableDatesByUf(uf = 'AL') {
    const ufUpper = uf.toString().toUpperCase();

    const { items: stations } = await getPluviometricStationsByUf(ufUpper);

    const dateSet = new Set();

    const todayStr = formatDateYMD(new Date());
    const startStr = '1900-01-01';

    for (const st of stations || []) {
        const codigo =
        st.codigoestacao ||
        st.CodigoEstacao ||
        st.CodigoEstacaoTelemetrica ||
        st['Código da Estação'] ||
        st['CodigoEstacao'];

        if (!codigo) continue;

        try {
            const { items } = await getPluviometricHistoricSeries({
                codigoEstacao: codigo,
                dataInicial: startStr,
                dataFinal: todayStr,
            });

            for (const it of items || []) {
                const raw = it['Data_Hora_Dado'] || it.Data_Hora_Dado;
                if (!raw) continue;
                const d = new Date(raw);
                if (Number.isNaN(d.getTime())) continue;
                dateSet.add(formatDateYMD(d));
            }
        } catch (err) {
            console.warn(
                '[getPluviometricAvailableDatesByUf] erro estação',
                codigo,
                String(err || '')
            );
        }
    }

    const arr = Array.from(dateSet);
    arr.sort();
    return arr;
}

// -----------------------------------------------------------------------------
// DISPATCHER GENÉRICO – /telemetricStationSeries
// -----------------------------------------------------------------------------
async function getStationSeries({ codigoEstacao, tipoEstacao, daysBack = 7 }) {
    if (!codigoEstacao) {
        throw new Error('codigoEstacao é obrigatório');
    }

    const tipo = (tipoEstacao || '').toString().toUpperCase();

    if (tipo.startsWith('PLUVI')) {
        return getPluviometricSeries(codigoEstacao, daysBack);
    }

    if (tipo.startsWith('FLUVI')) {
        return getFluviometricSeries(codigoEstacao, daysBack);
    }

    // Fallback: trata como pluviométrica telemétrica
    return getPluviometricSeries(codigoEstacao, daysBack);
}

module.exports = {
    getAnaOAuthToken,
    getTelemetricStationsByUf,
    getPluviometricStationsByUf,
    getFluviometricStationsByUf,
    getPluviometricSeries,
    getFluviometricSeries,
    getPluviometricHistoricSeries,
    getPluviometricTotalsForPeriod,
    getPluviometricAvailableDatesByUf,
    getStationSeries,
};
