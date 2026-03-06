// functions/src/http/public_accident_pdf.js
const express = require('express');
const PDFDocument = require('pdfkit');

const admin = require('../config/firebase'); // ajuste se seu path for diferente
const corsHandler = require('../config/cors');

const { onRequest } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');

// ✅ Ajuste a região conforme seu projeto (southamerica-east1 é comum no BR)
setGlobalOptions({
    region: 'southamerica-east1',
    memory: '256MiB',
    timeoutSeconds: 30,
});

const db = admin.firestore();

// Coleção pública criada por você: publicAccidentReports/{token}
const PUBLIC_COL = 'publicAccidentReports';

function _toDate(v) {
    if (!v) return null;
    if (v.toDate) return v.toDate(); // Firestore Timestamp
    if (v instanceof Date) return v;
    const d = new Date(v);
    return isNaN(d.getTime()) ? null : d;
}

function _fmtDate(dt) {
    if (!dt) return '-';
    const d = String(dt.getDate()).padLeft?.(2, '0') ?? String(dt.getDate()).padStart(2, '0');
    const m = String(dt.getMonth() + 1).padStart(2, '0');
    const y = String(dt.getFullYear());
    return `${d}/${m}/${y}`;
}

function _safeStr(v) {
    const s = (v ?? '').toString().trim();
    return s.length ? s : '-';
}

function _writeLine(doc, label, value) {
    doc
        .font('Helvetica-Bold')
        .text(`${label}: `, { continued: true })
        .font('Helvetica')
        .text(_safeStr(value));
}

function _generatePdfBuffer(payload) {
    return new Promise((resolve, reject) => {
        try {
            const doc = new PDFDocument({
                size: 'A4',
                margin: 48,
            });

            const chunks = [];
            doc.on('data', (c) => chunks.push(c));
            doc.on('end', () => resolve(Buffer.concat(chunks)));
            doc.on('error', reject);

            // ===== Cabeçalho =====
            doc
                .font('Helvetica-Bold')
                .fontSize(18)
                .text('BOLETIM PÚBLICO — ACIDENTE', { align: 'center' });

            doc.moveDown(0.5);
            doc
                .font('Helvetica')
                .fontSize(10)
                .fillColor('#666666')
                .text('Documento gerado automaticamente pelo SIPGED', { align: 'center' });

            doc.fillColor('#000000');
            doc.moveDown(1.2);

            // ===== Conteúdo =====
            const publicData = payload.publicData || {};
            const dt = _toDate(publicData.date);

            doc.fontSize(12);
            _writeLine(doc, 'Ordem', publicData.order);
            _writeLine(doc, 'Data', _fmtDate(dt));
            _writeLine(doc, 'Cidade', publicData.city);
            _writeLine(doc, 'Rodovia', publicData.highway);
            _writeLine(doc, 'Tipo', publicData.typeOfAccident);
            _writeLine(doc, 'Mortes', publicData.death);
            _writeLine(doc, 'Vítimas (escoriações)', publicData.scoresVictims);
            _writeLine(doc, 'Transportes envolvidos', publicData.transportInvolved);
            _writeLine(doc, 'Local', publicData.location);
            _writeLine(doc, 'Ponto de referência', publicData.referencePoint);

            // Coordenadas
            const latLng = publicData.latLng || null;
            if (latLng && typeof latLng === 'object') {
                const lat = latLng.latitude ?? latLng.lat;
                const lon = latLng.longitude ?? latLng.lng;
                doc.moveDown(0.3);
                _writeLine(doc, 'Coordenadas', `${_safeStr(lat)}, ${_safeStr(lon)}`);
            }

            doc.moveDown(1.0);
            doc
                .font('Helvetica')
                .fontSize(9)
                .fillColor('#666666')
                .text(`Token: ${payload.token || '-'}`);
            doc
                .font('Helvetica')
                .fontSize(9)
                .fillColor('#666666')
                .text(`Gerado em: ${_fmtDate(new Date())}`);

            // Rodapé
            doc.moveDown(2.0);
            doc
                .font('Helvetica-Oblique')
                .fontSize(8)
                .fillColor('#999999')
                .text('Uso público. Informações sensíveis foram omitidas.', { align: 'center' });

            doc.end();
        } catch (e) {
            reject(e);
        }
    });
}

const app = express();

// ✅ CORS (usa seu handler)
app.use(corsHandler);

// Health
app.get('/', (_, res) => {
    res.status(200).send('publicAccidentPdf OK. Use /{token}');
});

// PDF por token
app.get('/:token', async (req, res) => {
    try {
        const token = (req.params.token || '').trim();
        if (!token) return res.status(400).send('Token ausente.');

        const snap = await db.collection(PUBLIC_COL).doc(token).get();
        if (!snap.exists) return res.status(404).send('Boletim não encontrado.');

        const data = snap.data() || {};
        const enabled = data.enabled === true;
        const revokedAt = _toDate(data.revokedAt);
        const expiresAt = _toDate(data.expiresAt);

        if (!enabled || revokedAt) {
            return res.status(410).send('Boletim revogado.');
        }
        if (expiresAt && new Date() > expiresAt) {
            return res.status(410).send('Boletim expirado.');
        }

        const payload = {
            token,
            ...data,
        };

        const pdfBuffer = await _generatePdfBuffer(payload);

        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader(
            'Content-Disposition',
            `inline; filename="boletim_acidente_${token}.pdf"`
        );
        res.status(200).send(pdfBuffer);
    } catch (err) {
        console.error('publicAccidentPdf error:', err);
        res.status(500).send(`Erro ao gerar PDF: ${err}`);
    }
});

// ✅ Exporta como Cloud Function v2
exports.publicAccidentPdf = onRequest(app);