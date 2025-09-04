import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'geo_json_preview_dialog.dart';
import 'geo_json_mult_line_sanitizer.dart';

class GeoJsonImport {
  /// Abre o file picker, mostra o preview e devolve o que foi selecionado.
  ///
  /// - `onSalvar`: recebe (linhasPrincipais, geometrias) já saneadas (LineStrings).
  /// - `onFinished`: callback opcional para pós-processo (snackbar, refresh, etc).
  static Future<void> geoJsonImport({
    required BuildContext context,
    required String path, // mantido por compatibilidade
    required Future<void> Function(
        List<Map<String, dynamic>> linhasPrincipais,
        List<Map<String, dynamic>> geometrias,
        ) onSalvar,
    required void Function()? onFinished,
    double maxJumpKm = 2.0,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['geojson', 'json'],
      );
      if (result == null) return;

      final file = result.files.first;
      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
      final Map<String, dynamic> geoJson = json.decode(utf8.decode(bytes));

      final List<dynamic> featuresRaw = geoJson['features'] ?? [];
      final List<Map<String, dynamic>> parsedFeatures =
      featuresRaw.whereType<Map<String, dynamic>>().toList();

      if (parsedFeatures.isEmpty) {
        _showSnackBar(context, 'GeoJSON sem dados válidos.');
        return;
      }

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return GeoJsonPreviewDialog(
            features: parsedFeatures,
            onSalvar: (linhas, tipos, subcolecoes) async {
              // subcolecoes esperado: [{'points': [{latitude, longitude}, ...]}, ...]
              final geometrias = <Map<String, dynamic>>[];
              int totalSaltosConsiderados = 0;

              for (final sub in subcolecoes) {
                final rawPoints = (sub['points'] as List?) ?? const [];
                final pts = rawPoints.map((p) {
                  final lat = (p['latitude'] as num).toDouble();
                  final lng = (p['longitude'] as num).toDouble();
                  return LatLng(lat, lng);
                }).toList();

                final sanitized = sanitizePolyline(raw: pts, maxJumpKm: maxJumpKm);
                totalSaltosConsiderados +=
                sanitized.forwardLongJumps <= sanitized.reverseLongJumps
                    ? sanitized.forwardLongJumps
                    : sanitized.reverseLongJumps;

                for (final seg in sanitized.segments) {
                  final pointsMap = seg
                      .map((p) => {
                    'latitude': p.latitude,
                    'longitude': p.longitude,
                  })
                      .toList();
                  geometrias.add({
                    'geometryType': 'LineString',
                    'points': pointsMap,
                  });
                }
              }

              await onSalvar(linhas, geometrias);
              onFinished?.call();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Importado com correção de saltos. '
                          'Saltos detectados (na escolha de sentido): $totalSaltosConsiderados',
                    ),
                  ),
                );
              }
            },
          );
        },
      );
    } catch (e) {
      _showSnackBar(context, 'Erro ao importar GeoJSON: $e');
    }
  }

  static void _showSnackBar(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
