/*
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_widgets/bluetooth/bitmap/ble_client.dart';
import 'package:sipged/_services/print/label_bitmap.dart';

import '../../_widgets/bluetooth/bitmap/ble_client_iface.dart';

class PrintTestButton extends StatelessWidget {
  const PrintTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.bug_report),
      label: const Text('Imprimir em blocos (teste preto)'),
      onPressed: () async {
        final ble = createBleClient();
        await ble.connect();

        const larguraMm = 14.0;
        const alturaMm = 30.0;
        const dpi = 203;

        // Alinha largura para múltiplo de 8
        int _mmToPx(double mm) {
          final px = (mm * dpi / 25.4).round();
          return px + (8 - px % 8) % 8;
        }

        final width = _mmToPx(larguraMm);
        final height = _mmToPx(alturaMm);
        final bytesPerRow = (width + 7) >> 3;
        final totalBytes = bytesPerRow * height;

        // Cria imagem preta sólida
        final blackData = Uint8List.fromList(List.generate(totalBytes, (_) => 0xFF));
        final mono = MonoBitmap(blackData, width, height);

        await _sendEscPosInChunks(
          ble: ble,
          bmp: mono,
          chunkHeight: 16,
          gapMm: 10,
          invert: false,
          delayMs: 60,
        );

        await ble.disconnect();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impressão por blocos enviada')),
          );
        }
      },
    );
  }

  /// Divide imagem e envia em blocos GS v 0 (anti-falha)
  Future<void> _sendEscPosInChunks({
    required LabelBleClient ble,
    required MonoBitmap bmp,
    int chunkHeight = 16,
    double gapMm = 10,
    bool invert = false,
    int delayMs = 50,
  }) async {
    final widthPx = bmp.widthPx;
    final height = bmp.heightPx;
    final bytesPerRow = (widthPx + 7) >> 3;
    final totalBytes = bmp.bytes;

    final dotsPerMm = 203 / 25.4;
    final feedDots = (gapMm * dotsPerMm).round();

    // ESC @ + alinhamento à esquerda
    final header = BytesBuilder();
    header.add([0x1B, 0x40]);
    header.add([0x1B, 0x61, 0x00]); // ESC a 0
    await ble.writeAll(header.toBytes(), chunk: 16);
    await Future.delayed(Duration(milliseconds: delayMs));

    // Envia a imagem em blocos (faixas)
    for (int y = 0; y < height; y += chunkHeight) {
      final currentHeight = (y + chunkHeight <= height)
          ? chunkHeight
          : height - y;

      final yL = currentHeight & 0xFF;
      final yH = (currentHeight >> 8) & 0xFF;

      final block = BytesBuilder();
      block.add([
        0x1D, 0x76, 0x30, 0x00,
        bytesPerRow & 0xFF,
        (bytesPerRow >> 8) & 0xFF,
        yL, yH
      ]);

      final start = y * bytesPerRow;
      final end = start + currentHeight * bytesPerRow;
      final slice = totalBytes.sublist(start, end);

      block.add(invert
          ? Uint8List.fromList(slice.map((b) => ~b & 0xFF).toList())
          : slice);

      await ble.writeAll(block.toBytes(), chunk: 16);
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    // GAP (alimentação final)
    int remaining = feedDots;
    while (remaining > 0) {
      final n = remaining.clamp(1, 255);
      await ble.writeAll(Uint8List.fromList([0x1B, 0x4A, n]), chunk: 16);
      remaining -= n;
    }

    // LF final
    await ble.writeAll(Uint8List.fromList([0x0A]), chunk: 16);
  }
}
*/
