// functions/src/http/ibge_proxy.js
const { onRequest } = require('firebase-functions/v2/https');
const cors = require('../config/cors');
const fetch = require('node-fetch');

// ✅ base sem "v1" fixo, pra suportar v1 e v3
const IBGE_API_BASE = 'https://servicodados.ibge.gov.br/api';

// ✅ allowlist pra NÃO virar open-proxy
// (você usa "localidades/..." e "malhas/...")
function isAllowedPath(cleanedPath) {
    const p = String(cleanedPath || '');
    return (
    p.startsWith('v1/localidades/') ||
    p.startsWith('v3/malhas/') ||
    p.startsWith('v1/malhas/') // se algum endpoint v1 existir/for usado
    );
}

/**
 * Espera receber "path" como você manda do Flutter:
 *   localidades/estados?orderBy=nome
 *   localidades/estados/27/municipios
 *   malhas/municipios/2704302?formato=application/vnd.geo+json&qualidade=minima
 *
 * A função vai inferir a versão:
 *  - localidades => v1
 *  - malhas      => v3 (no seu caso)
 */
function normalizePath(rawPath) {
    const p = String(rawPath || '').trim();
    if (!p) return null;

    // bloqueia URL completa (evita SSRF)
    if (/^https?:\/\//i.test(p)) return null;
    if (p.includes('://')) return null;

    const cleaned = p.replace(/^\/+/, '');

    // se já vier com v1/ ou v3/, mantém
    if (/^v[13]\//i.test(cleaned)) return cleaned;

    // inferência simples por prefixo
    if (cleaned.startsWith('localidades/')) return `v1/${cleaned}`;
    if (cleaned.startsWith('malhas/')) return `v3/${cleaned}`;

    // se vier algo fora, recusa
    return null;
}

exports.ibgeProxy = onRequest(
    { timeoutSeconds: 60, memory: '256MiB' },
    async (req, res) => {
        return cors(req, res, async () => {
            try {
                const normalized = normalizePath(req.query.path);
                if (!normalized) {
                    return res.status(400).json({
                        ok: false,
                        message:
                        'Parâmetro "path" inválido. Use exemplos: localidades/... ou malhas/...',
                    });
                }

                if (!isAllowedPath(normalized)) {
                    return res.status(403).json({
                        ok: false,
                        message: 'Path não permitido (allowlist).',
                        path: normalized,
                    });
                }

                const url = `${IBGE_API_BASE}/${normalized}`;

                const resp = await fetch(url, {
                    method: 'GET',
                    headers: {
                        // IBGE pode retornar geojson, json, etc.
                        Accept: 'application/json, application/vnd.geo+json, text/plain;q=0.9, */*;q=0.8',
                    },
                });

                const text = await resp.text();

                if (!resp.ok) {
                    return res.status(resp.status).json({
                        ok: false,
                        message: `IBGE retornou ${resp.status}`,
                        url,
                        body: text.slice(0, 800),
                    });
                }

                // ✅ preserva content-type do IBGE (ajuda GeoJSON)
                const ct = resp.headers.get('content-type') || 'application/json; charset=utf-8';
                res.setHeader('content-type', ct);

                // tenta JSON; se não for, devolve texto (GeoJSON geralmente é JSON)
                try {
                    const payload = JSON.parse(text);
                    return res.status(200).send(payload);
                } catch (_) {
                    return res.status(200).send(text);
                }
            } catch (err) {
                console.error('[ibgeProxy] Erro:', err);
                return res.status(500).json({
                    ok: false,
                    message: err?.message || String(err),
                });
            }
        });
    }
);
