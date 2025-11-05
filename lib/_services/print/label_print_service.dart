// lib/_services/print/label_print_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:siged/_widgets/bluetooth/bitmap/label_bitmap.dart';
import 'package:siged/_widgets/bluetooth/bitmap/label_bitmap_preview.dart';
import 'package:siged/_widgets/bluetooth/bitmap/ble_client.dart';

import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';

/// Preset de rótulos (largura x altura, em mm).
class LabelPreset {
  final String name;
  final double wMm; // largura (mm)
  final double hMm; // altura (mm)
  const LabelPreset(this.name, this.wMm, this.hMm);
}

/// Serviço responsável por:
/// - Montar bitmap 1-bit a partir do Canvas (row-aligned)
/// - Gerar ESC/POS raster (GS v 0) com GAP
/// - Conectar via Web Bluetooth e enviar os bytes
class LabelPrintService {
  /// Presets suportados (padrão: índice 0 → 14×30 mm).
  static const presets = <LabelPreset>[
    LabelPreset('14×30 mm', 14, 30),
    LabelPreset('14×40 mm', 14, 40),
    LabelPreset('14×50 mm', 14, 50),
  ];

  /// Constrói o job ESC/POS raster (GS v 0) + GAP (feed).
  static Uint8List _buildEscPosRasterJob(
      MonoBitmap bmp, {
        int mode = 0, // 0=normal, 1=2xL, 2=2xA, 3=2x ambos
        bool center = true,
        double gapMm = 10,
        bool invert = false,
      }) {
    final widthBytes = (bmp.widthPx + 7) >> 3; // bytes por linha
    final height = bmp.heightPx;

    final xL = widthBytes & 0xFF;
    final xH = (widthBytes >> 8) & 0xFF;
    final yL = height & 0xFF;
    final yH = (height >> 8) & 0xFF;

    final data = invert
        ? Uint8List.fromList(bmp.bytes.map((b) => (~b) & 0xFF).toList())
        : bmp.bytes;

    final out = BytesBuilder();

    // ESC @ (init)
    out.add([0x1B, 0x40]);

    // alinhamento
    if (center) out.add([0x1B, 0x61, 0x01]); // ESC a 1

    // GS v 0 m xL xH yL yH  {data}
    out.add([0x1D, 0x76, 0x30, mode, xL, xH, yL, yH]);
    out.add(data);

    // Feed por pontos (ESC J n) ≈ 203/25.4 dots/mm ≈ 8.0
    final dotsPerMm = 203 / 25.4;
    int remaining = (gapMm * dotsPerMm).round(); // ex.: 10 mm ≈ 80 dots
    while (remaining > 0) {
      final n = remaining.clamp(1, 255);
      out.add([0x1B, 0x4A, n]); // ESC J n
      remaining -= n;
    }

    return out.toBytes();
  }

  /// Abre diálogo com preview e envia a etiqueta via BLE.
  static Future<void> printAccident(
      BuildContext context,
      AccidentsData accident, {
        int presetIndex = 0,
        double gapMm = 10,
        bool invert = false,
      }) async {
    final p = presets[presetIndex.clamp(0, presets.length - 1)];

    // Texto sugerido (ajuste a gosto)
    final texto = 'Acidente ${accident.order ?? ''} • ${accident.city ?? ''}';
    final qr = accident.id ?? '';

    // Configuração única de layout usada no PREVIEW e na IMPRESSÃO
    const cfg = LabelLayoutConfig(
      padMm: 1.5,
      qrSideMm: 11.0,
      spaceBetweenMm: 0.6,
      textSizeMm: 2.8,
      textMaxLines: 3,
      rotateTextClockwise: true,
      // minTextBandMmForRow: 4.0 (padrão) → no 14×30 vai cair para “coluna”
    );


    // Mostra preview e confirma
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Etiqueta (${p.name})'),
        content: SizedBox(
          height: 340,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabelBitmapPreview(
                  larguraMm: p.wMm,
                  alturaMm: p.hMm,
                  texto: texto,
                  qrData: qr,
                  dpi: 203,
                  cfg: cfg,
                ),
                const SizedBox(height: 12),
                Text(
                  'Gap configurado: ${gapMm.toStringAsFixed(1)} mm',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
        false;

    if (!ok) return;

    // Render 1-bit (row-aligned) — MESMO layout do preview
    final mono = await renderLabelMonoPackedRowAligned(
      larguraMm: p.wMm,
      alturaMm: p.hMm,
      texto: texto,
      qrData: qr,
      dpi: 203,
      threshold: 128, // ajuste fino: 110–140 pode escurecer mais o texto
      cfg: cfg,
    );

    // Monta ESC/POS job
    final job = _buildEscPosRasterJob(
      mono,
      gapMm: gapMm,
      invert: invert,
    );

    // Envia via Web Bluetooth (chunks de 20 no browser)
    final ble = createBleClient();
    await ble.connect();
    await ble.writeAll(job, chunk: 20);
    await ble.disconnect();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etiqueta enviada para a impressora.')),
      );
    }
  }
}
