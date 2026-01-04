const fetch = require('node-fetch');

const BASE_URL = 'https://transparencia.al.gov.br';

const DEFAULT_HEADERS = (apiKey) => ({
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
    ...(apiKey ? { 'chave-api-dados': apiKey } : {}),
});

function fmtDateBR(dd, mm, yyyy) {
    const d = String(dd).padStart(2, '0');
    const m = String(mm).padStart(2, '0');
    const y = String(yyyy);
    return `${d}/${m}/${y}`;
}

function yearRange(year) {
    return {
        dataIni: fmtDateBR(1, 1, year),
        dataFim: fmtDateBR(31, 12, year),
    };
}

// Cache simples em memória (bom p/ reduzir chamadas repetidas)
const cache = {
    ugsByYear: new Map(),      // year -> { items, fetchedAt }
    dotacoesByYear: new Map(), // key -> { payload, fetchedAt }
};

const TTL_UGS_MS = 60 * 60 * 1000;      // 1h
const TTL_DOTACOES_MS = 15 * 60 * 1000; // 15m

async function fetchJson(url, { apiKey }) {
    const resp = await fetch(url, {
        method: 'GET',
        headers: DEFAULT_HEADERS(apiKey),
    });

    if (!resp.ok) {
        const text = await resp.text();
        throw new Error(`AL Transparência erro ${resp.status} em ${url}: ${text}`);
    }

    // Algumas respostas podem vir como text/html; ainda assim geralmente é JSON
    const text = await resp.text();
    try {
        return JSON.parse(text);
    } catch (e) {
        throw new Error(`Resposta não-JSON do Portal (url=${url}). Trecho: ${text.slice(0, 200)}`);
    }
}

/**
 * Lista UGs no período (endpoint avançado de UG)
 * URL: /orcamento/json-dotacoes-avancada-ug/?data_registro_dti_=...&data_registro_dtf_=...
 */
async function listUgsForYear({ year, apiKey }) {
    const cached = cache.ugsByYear.get(year);
    if (cached && Date.now() - cached.fetchedAt < TTL_UGS_MS) {
        return cached.items;
    }

    const { dataIni, dataFim } = yearRange(year);
    const url =
    `${BASE_URL}/orcamento/json-dotacoes-avancada-ug/` +
    `?data_registro_dti_=${encodeURIComponent(dataIni)}` +
    `&data_registro_dtf_=${encodeURIComponent(dataFim)}`;

    const items = await fetchJson(url, { apiKey });

    if (!Array.isArray(items)) {
        throw new Error(`Esperado array de UGs, veio: ${typeof items}`);
    }

    cache.ugsByYear.set(year, { items, fetchedAt: Date.now() });
    return items;
}

/**
 * Encontra UG do DER por "contains" (case-insensitive).
 * O portal pode variar a descrição, então o matcher tenta alguns padrões.
 */
function findDerUg(ugs) {
    const patterns = [
        'DEPARTAMENTO ESTADUAL DE ESTRADAS DE RODAGEM',
        'DEPARTAMENTO DE ESTRADAS DE RODAGEM',
        'DER',
    ];

    const upper = ugs.map((u) => ({
        id: String(u.id ?? ''),
        descricao: String(u.descricao ?? '').toUpperCase(),
        raw: u,
    }));

    for (const p of patterns) {
        const target = p.toUpperCase();
        const found = upper.filter((u) => u.descricao.includes(target));
        if (found.length) {
            found.sort((a, b) => b.descricao.length - a.descricao.length);
            return found[0]; // {id, descricao, raw}
        }
    }
    return null;
}

/**
 * Consulta consolidada de dotações por UG no período do ano
 * URL: /orcamento/json-dotacoes/?...&ug=<ugId>
 */
async function getDotacoesConsolidadas({ year, ugId, apiKey }) {
    const key = `consol_${year}_${ugId}`;
    const cached = cache.dotacoesByYear.get(key);
    if (cached && Date.now() - cached.fetchedAt < TTL_DOTACOES_MS) {
        return cached.payload;
    }

    const { dataIni, dataFim } = yearRange(year);

    const url =
    `${BASE_URL}/orcamento/json-dotacoes/` +
    `?data_registro_dti_=${encodeURIComponent(dataIni)}` +
    `&data_registro_dtf_=${encodeURIComponent(dataFim)}` +
    `&limit=50&offset=0` +
    `&ug=${encodeURIComponent(String(ugId))}`;

    const payload = await fetchJson(url, { apiKey });

    cache.dotacoesByYear.set(key, { payload, fetchedAt: Date.now() });
    return payload;
}

/**
 * Detalhe por UG (linhas por natureza/subelemento etc.)
 * URL: /orcamento/json-dotacoes-ug/<ugId>/?data_registro_dti_=...&data_registro_dtf_=...&limit=...
 */
async function getDotacoesDetalhadas({ year, ugId, apiKey, limit = 5000, offset = 0 }) {
    const key = `det_${year}_${ugId}_${limit}_${offset}`;
    const cached = cache.dotacoesByYear.get(key);
    if (cached && Date.now() - cached.fetchedAt < TTL_DOTACOES_MS) {
        return cached.payload;
    }

    const { dataIni, dataFim } = yearRange(year);

    const url =
    `${BASE_URL}/orcamento/json-dotacoes-ug/${encodeURIComponent(String(ugId))}/` +
    `?data_registro_dti_=${encodeURIComponent(dataIni)}` +
    `&data_registro_dtf_=${encodeURIComponent(dataFim)}` +
    `&limit=${encodeURIComponent(String(limit))}` +
    `&offset=${encodeURIComponent(String(offset))}`;

    const payload = await fetchJson(url, { apiKey });

    cache.dotacoesByYear.set(key, { payload, fetchedAt: Date.now() });
    return payload;
}

module.exports = {
    listUgsForYear,
    findDerUg,
    getDotacoesConsolidadas,
    getDotacoesDetalhadas,
};
